import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../theme/app_colors.dart';
import '../models/child.dart';
import '../models/child_gps.dart';
import '../models/notification.dart';
import '../models/child_vitals.dart';
import '../models/child_device.dart';
import '../models/safe_zone.dart';
import '../service/child_service.dart';
import '../service/child_gps.dart';
import '../service/notification_service.dart';
import '../service/safezone_service.dart';
import '../service/vital_service.dart';
import '../service/battery_service.dart';

import '../widgets/child_marker.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/add_options_sheet.dart';
import '../widgets/children_panel.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/information_view.dart';
import '../widgets/tracking_day_view.dart';
import '../widgets/membership_view.dart';

import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;

  final PanelController _panelController = PanelController();
  GoogleMapController? _mapController;
  Timer? _liveUpdateTimer;
  Timer? _zonePulseTimer;
  Timer? _markerPulseTimer;

  final Map<int, StreamSubscription<ChildGps>> _gpsSubscriptions = {};
  final Map<int, StreamSubscription<dynamic>> _vitalSubscriptions = {};
  StreamSubscription<NotificationM>? _notificationSubscription;

  static const double _bottomNavHeight = HomeBottomNav.height;
  static const double _panelBottomGap = 18;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isZonePulsing = false;
  bool _isMarkerPulsing = false;
  late AnimationController _pulseAnimController;

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Marker> _safeZoneMarkers = {};
  int? _selectedChildId;

  List<Child> _children = [];

  final Map<int, ChildGps> _locations = {};
  final Map<int, DateTime> _lastGpsUpdate = {};
  final Map<int, ChildHealth> _health = {};
  final Map<int, ChildDevice> _devices = {};
  final Map<int, List<SafeZone>> _childSafeZones = {};

  @override
  void initState() {
    super.initState();
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimController.repeat(reverse: true);
    _loadData();
    _startLiveUpdates();
    _startZonePulse();
    _startMarkerPulse();
  }

  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    _zonePulseTimer?.cancel();
    _markerPulseTimer?.cancel();
    _pulseAnimController.dispose();
    for (final subscription in _gpsSubscriptions.values) {
      subscription.cancel();
    }
    _gpsSubscriptions.clear();
    for (final subscription in _vitalSubscriptions.values) {
      subscription.cancel();
    }
    _vitalSubscriptions.clear();
    _notificationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final children = await ChildService.getChildren();

      final Map<int, ChildGps> loadedLocations = {};

      for (final child in children) {
        try {
          final location = await ChildLocationService.getLocation(child.id);
          loadedLocations[child.id] = location;
        } catch (e) {
          print('Failed to load GPS for child ${child.id}: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _children = children;
        _locations.clear();
        _locations.addAll(loadedLocations);
        _health.clear();
        _devices.clear();
        _isLoading = false;
        _errorMessage = null;
      });

      await _loadMarkers();
      _startGpsStreams();
      _startVitalStreams();
      _startNotificationStream();

      if (children.isNotEmpty) {
        _loadChildSafeZones(children.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _startGpsStreams() {
    for (final child in _children) {
      _listenToChildGps(child);
    }
  }

  void _startVitalStreams() {
    for (final child in _children) {
      _listenToChildVitals(child);
    }
  }

  void _listenToChildVitals(Child child) {
    _vitalSubscriptions[child.id]?.cancel();
    _vitalSubscriptions[child.id] =
        VitalService.listenVitals(child.id).listen(
      (vital) {
        if (!mounted) return;
        setState(() {
          _health[child.id] = ChildHealth(
            childId: child.id,
            heartBeat: vital.heartbeats,
            oxygenLevel: vital.oxygenLevel,
          );
        });
      },
      onError: (error) {
        print('VITALS STREAM ERROR child ${child.id}: $error');
        _reconnectVitalsDelayed(child);
      },
      onDone: () {
        print('VITALS STREAM DONE child ${child.id}');
        _reconnectVitalsDelayed(child);
      },
    );
  }

  void _reconnectVitalsDelayed(Child child) {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _listenToChildVitals(child);
    });
  }

  void _listenToChildGps(Child child) {
    _gpsSubscriptions[child.id]?.cancel();
    _gpsSubscriptions[child.id] =
        ChildLocationService.listenLocation(child.id).listen(
      (gps) async {
        if (!mounted) return;
        setState(() {
          _locations[child.id] = gps;
          _lastGpsUpdate[child.id] = DateTime.now();
        });
        await _loadMarkers();
      },
      onError: (error) {
        print('GPS STREAM ERROR child ${child.id}: $error');
        _reconnectGpsDelayed(child);
      },
      onDone: () {
        print('GPS STREAM DONE child ${child.id}');
        _reconnectGpsDelayed(child);
      },
    );
  }

  void _reconnectGpsDelayed(Child child) {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _listenToChildGps(child);
    });
  }

  void _startNotificationStream() {
    _notificationSubscription?.cancel();
    _notificationSubscription =
        AlertNotificationService.listenForAlerts().listen(
      (notification) {
        if (!mounted) return;
      },
      onError: (error) => print('NOTIFICATION STREAM ERROR: $error'),
    );
  }

  void _startLiveUpdates() {
    _liveUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (!mounted) return;
        _fetchBatteryForAll();
      },
    );
    _fetchBatteryForAll();
  }

  Future<void> _fetchBatteryForAll() async {
    for (final child in _children) {
      try {
        final batteryStr = await BatteryService.getBattery(child.id);
        final battery = int.tryParse(batteryStr) ?? 0;
        if (!mounted) return;
        setState(() {
          _devices[child.id] = ChildDevice(
            childId: child.id,
            batteryLevel: battery.clamp(0, 100),
          );
        });
      } catch (e) {
        print('Battery fetch failed for child ${child.id}: $e');
      }
    }
  }

  void _startZonePulse() {
    _zonePulseTimer = Timer.periodic(
      const Duration(milliseconds: 750),
      (timer) {
        if (!mounted) return;
        setState(() => _isZonePulsing = !_isZonePulsing);
        _rebuildZoneCircles();
      },
    );
  }

  void _startMarkerPulse() {
    _markerPulseTimer = Timer.periodic(
      const Duration(milliseconds: 1000),
      (timer) {
        if (!mounted) return;
        setState(() => _isMarkerPulsing = !_isMarkerPulsing);
        _loadMarkers();
      },
    );
  }

  Future<void> _loadMarkers() async {
    final Set<Marker> loadedMarkers = {};
    for (final child in _children) {
      final location = _locations[child.id];
      if (location == null) continue;

      final zones = _childSafeZones[child.id] ?? [];
      final insideZone = _findContainingZone(location, zones);

      final idle = _lastGpsUpdate[child.id] != null
          ? DateTime.now().difference(_lastGpsUpdate[child.id]!)
          : Duration.zero;
      final icon = await createChildMarker(
        name: child.fullName,
        speed: location.speed,
        idleDuration: idle,
        color: AppColors.info,
        isInsideZone: insideZone != null,
        isPulsing: _isMarkerPulsing,
      );
      loadedMarkers.add(
        Marker(
          markerId: MarkerId(child.id.toString()),
          position: LatLng(location.latitude, location.longitude),
          icon: icon,
          anchor: const Offset(0.5, 1),
          onTap: () => _showChildLocation(child),
        ),
      );
    }
    if (!mounted) return;
    setState(() => _markers = loadedMarkers);
  }

  SafeZone? _findContainingZone(ChildGps location, List<SafeZone> zones) {
    for (final zone in zones) {
      final distance = _distanceInMeters(
        location.latitude, location.longitude,
        zone.latitude, zone.longitude,
      );
      if (distance <= zone.radius) return zone;
    }
    return null;
  }

  double _distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  void _toggleChildrenPanel() {
    if (_panelController.isPanelOpen) {
      _panelController.close();
    } else {
      _panelController.open();
    }
  }

  void _onNavItemTapped(int index) {
    if (index == 4) {
      showAddOptionsSheet(context);
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _onSettingsTap() {}

  void _onMessagesTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _showChildLocation(Child child) {
    final location = _locations[child.id];
    if (location == null) return;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        17,
      ),
    );



    _loadChildSafeZones(child);
  }

  Future<void> _loadChildSafeZones(Child child) async {
    setState(() => _selectedChildId = child.id);

    try {
      final zones = await SafezoneService.getSafeZone(child.id);
      if (!mounted || _selectedChildId != child.id) return;

      _childSafeZones[child.id] = zones;

      _rebuildZoneCircles();
      await _rebuildZoneMarkers();
      await _loadMarkers();
    } catch (e) {
      print('ERROR loading safe zones: $e');
    }
  }

  void _rebuildZoneCircles() {
    final zones = _selectedChildId != null
        ? (_childSafeZones[_selectedChildId] ?? [])
        : <SafeZone>[];
    final Set<Circle> circles = {};
    const Color zoneColor = AppColors.success;
    final pulseAlpha = _isZonePulsing ? 0.35 : 0.20;
    final strokeAlpha = _isZonePulsing ? 0.95 : 0.70;

    for (final zone in zones) {
      circles.add(
        Circle(
          circleId: CircleId('sz_${zone.id}'),
          center: LatLng(zone.latitude, zone.longitude),
          radius: zone.radius,
          fillColor: zoneColor.withValues(alpha: pulseAlpha),
          strokeColor: zoneColor.withValues(alpha: strokeAlpha),
          strokeWidth: _isZonePulsing ? 4 : 3,
          zIndex: 2,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _circles = circles);
  }

  Future<void> _rebuildZoneMarkers() async {
    final zones = _selectedChildId != null
        ? (_childSafeZones[_selectedChildId] ?? [])
        : <SafeZone>[];
    final Set<Marker> markers = {};
    const Color zoneColor = AppColors.success;

    for (final zone in zones) {
      final icon = await createNameMarker(zone.name, color: zoneColor);
      markers.add(
        Marker(
          markerId: MarkerId('sz_${zone.id}'),
          position: LatLng(zone.latitude, zone.longitude),
          icon: icon,
          anchor: const Offset(0.5, 1),
        ),
      );
    }
    if (!mounted) return;
    setState(() => _safeZoneMarkers = markers);
  }

  Widget _buildBody() {
    const bottomPad = EdgeInsets.only(bottom: HomeBottomNav.height + 16);

    switch (_selectedIndex) {
      case 0:
        return Padding(
          padding: bottomPad,
          child: const MembershipView(),
        );
      case 1:
        return Padding(
          padding: bottomPad,
          child: TrackingDayView(
            children: _children,
          ),
        );
      case 3:
        return Padding(
          padding: bottomPad,
          child: InformationView(
            children: _children,
            health: _health,
            devices: _devices,
          ),
        );
      case 2:
      default:
        return _buildLocationView();
    }
  }

  Widget _buildLocationView() {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(36.7749, 6.4194),
            zoom: 15,
          ),
          markers: {
            if (_selectedChildId != null)
              ..._markers.where(
                (m) => m.markerId.value == _selectedChildId.toString(),
              )
            else
              ..._markers,
            ..._safeZoneMarkers,
          },
          circles: _circles,
          onMapCreated: (controller) => _mapController = controller,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        SlidingUpPanel(
          controller: _panelController,
          minHeight: 76,
          maxHeight: screenHeight * 0.55,
          margin: const EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: _bottomNavHeight + _panelBottomGap,
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppColors.radiusPanel),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
          color: AppColors.surface,
          panelBuilder: (scrollController) {
            return ChildrenPanel(
              scrollController: scrollController,
              panelController: _panelController,
              children: _children,
              locations: _locations,
              onToggle: _toggleChildrenPanel,
              onChildTap: _showChildLocation,
            );
          },
          body: const SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildBody(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeTopBar(
              onSettingsTap: _onSettingsTap,
              onMessagesTap: _onMessagesTap,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: HomeBottomNav(
              selectedIndex: _selectedIndex,
              onItemTapped: _onNavItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}
