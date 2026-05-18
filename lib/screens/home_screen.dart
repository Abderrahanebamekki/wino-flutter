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

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2;

  final PanelController _panelController = PanelController();
  GoogleMapController? _mapController;
  Timer? _liveUpdateTimer;

  final Map<int, StreamSubscription<ChildGps>> _gpsSubscriptions = {};
  StreamSubscription<NotificationM>? _notificationSubscription;

  static const double _bottomNavHeight = HomeBottomNav.height;
  static const double _panelBottomGap = 18;

  final Random _random = Random();

  bool _isLoading = true;
  String? _errorMessage;

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Marker> _safeZoneMarkers = {};
  int? _selectedChildId;

  List<Child> _children = [];

  final Map<int, ChildGps> _locations = {};
  final Map<int, ChildHealth> _health = {};
  final Map<int, ChildDevice> _devices = {};
  final Map<int, List<SafeZone>> _childSafeZones = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _startLiveUpdates();
  }

  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    for (final subscription in _gpsSubscriptions.values) {
      subscription.cancel();
    }
    _gpsSubscriptions.clear();
    _notificationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final children = await ChildService.getChildren();

      final Map<int, ChildGps> loadedLocations = {};
      final Map<int, ChildHealth> fakeHealth = {};
      final Map<int, ChildDevice> fakeDevices = {};

      for (final child in children) {
        final location = await ChildLocationService.getLocation(child.id);
        loadedLocations[child.id] = location;
        fakeHealth[child.id] = ChildHealth(
          childId: child.id,
          heartBeat: 88,
          oxygenLevel: 98,
        );
        fakeDevices[child.id] = ChildDevice(
          childId: child.id,
          batteryLevel: 80,
        );
      }

      if (!mounted) return;

      setState(() {
        _children = children;
        _locations.clear();
        _locations.addAll(loadedLocations);
        _health.clear();
        _health.addAll(fakeHealth);
        _devices.clear();
        _devices.addAll(fakeDevices);
        _isLoading = false;
        _errorMessage = null;
      });

      await _loadMarkers();
      _startGpsStreams();
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
      _gpsSubscriptions[child.id]?.cancel();
      _gpsSubscriptions[child.id] =
          ChildLocationService.listenLocation(child.id).listen(
        (gps) async {
          if (!mounted) return;
          setState(() => _locations[child.id] = gps);
          await _loadMarkers();
        },
        onError: (error) =>
            print('GPS STREAM ERROR child ${child.id}: $error'),
        onDone: () => print('GPS STREAM DONE child ${child.id}'),
      );
    }
  }

  void _startNotificationStream() {
    _notificationSubscription?.cancel();
    _notificationSubscription =
        AlertNotificationService.listenForAlerts().listen(
      (notification) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title}: ${notification.message}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              onPressed: _onMessagesTap,
            ),
          ),
        );
      },
      onError: (error) => print('NOTIFICATION STREAM ERROR: $error'),
    );
  }

  void _startLiveUpdates() {
    _liveUpdateTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        if (!mounted) return;
        setState(() {
          for (final child in _children) {
            final health = _health[child.id];
            final device = _devices[child.id];
            if (health != null) {
              health.heartBeat =
                  (health.heartBeat + _random.nextInt(7) - 3).clamp(60, 140);
              health.oxygenLevel =
                  (health.oxygenLevel + _random.nextInt(3) - 1).clamp(90, 100);
            }
            if (device != null) {
              device.batteryLevel =
                  (device.batteryLevel - _random.nextInt(2)).clamp(0, 100);
            }
          }
        });
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
      final label = insideZone != null ? '${child.fullName}\n@ ${insideZone.name}' : child.fullName;
      final maxLines = insideZone != null ? 2 : 1;

      final icon = await createNameMarker(label, maxLines: maxLines);
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

      final Set<Circle> circles = {};
      final Set<Marker> markers = {};
      const Color zoneColor = AppColors.success;

      for (final zone in zones) {
        final position = LatLng(zone.latitude, zone.longitude);
        circles.add(
          Circle(
            circleId: CircleId('sz_${zone.id}'),
            center: position,
            radius: zone.radius,
            fillColor: zoneColor.withValues(alpha: 0.25),
            strokeColor: zoneColor.withValues(alpha: 0.8),
            strokeWidth: 3,
            zIndex: 2,
          ),
        );

        final icon = await createNameMarker(zone.name, color: zoneColor);
        markers.add(
          Marker(
            markerId: MarkerId('sz_${zone.id}'),
            position: position,
            icon: icon,
            anchor: const Offset(0.5, 1),
          ),
        );
      }

      if (!mounted || _selectedChildId != child.id) return;

      setState(() {
        _circles = circles;
        _safeZoneMarkers = markers;
      });

      await _loadMarkers();
    } catch (e) {
      print('ERROR loading safe zones: $e');
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const MembershipView();
      case 1:
        return TrackingDayView(
          children: _children,
          locations: _locations,
          health: _health,
          devices: _devices,
        );
      case 3:
        return InformationView(
          children: _children,
          health: _health,
          devices: _devices,
          locations: _locations,
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
            target: LatLng(37.7749, -122.4194),
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
