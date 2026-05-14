import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../models/child.dart';
import '../models/child_gps.dart';
import '../models/notification.dart';
import '../models/child_vitals.dart';
import '../models/child_device.dart';
import '../service/child_service.dart';
import '../service/child_gps.dart';
import '../service/notification_service.dart';
import '../service/safezone_service.dart';

import '../widgets/child_marker.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/add_options_sheet.dart';
import '../widgets/child_detail_sheet.dart';
import '../widgets/children_panel.dart';
import '../widgets/home_bottom_nav.dart';

import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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

              setState(() {
                _locations[child.id] = gps;
              });

              await _loadMarkers();

              print(
                'HOME GPS UPDATE child=${child.id}, lat=${gps.latitude}, lng=${gps.longitude}, speed=${gps.speed}',
              );
            },
            onError: (error) {
              print('GPS STREAM ERROR child ${child.id}: $error');
            },
            onDone: () {
              print('GPS STREAM DONE child ${child.id}');
            },
          );
    }
  }

  void _startNotificationStream() {
    _notificationSubscription?.cancel();
    _notificationSubscription =
        AlertNotificationService.listenForAlerts().listen(
          (notification) {
            print(
              'ALERT RECEIVED: ${notification.title}: ${notification.message}',
            );
          },
          onError: (error) {
            print('NOTIFICATION STREAM ERROR: $error');
          },
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

      final icon = await createNameMarker(child.fullName);

      loadedMarkers.add(
        Marker(
          markerId: MarkerId(child.id.toString()),
          position: LatLng(
            location.latitude,
            location.longitude,
          ),
          icon: icon,
          anchor: const Offset(0.5, 1),
          onTap: () => _showChildLocation(child),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _markers = loadedMarkers;
    });
  }

  void _toggleChildrenPanel() {
    if (_panelController.isPanelOpen) {
      _panelController.close();
    } else {
      _panelController.open();
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      showAddOptionsSheet(context);
    }
  }

  void _onSettingsTap() {}

  void _onMessagesTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _showChildLocation(Child child) {
    final location = _locations[child.id];
    final health = _health[child.id];
    final device = _devices[child.id];

    if (location == null || health == null || device == null) {
      return;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        17,
      ),
    );

    showChildDetailSheet(context, child, location, health, device);

    _loadChildSafeZones(child);
  }

  Future<void> _loadChildSafeZones(Child child) async {
    setState(() => _selectedChildId = child.id);

    try {
      final zones = await SafezoneService.getSafeZone(child.id);

      if (!mounted || _selectedChildId != child.id) return;

      final Set<Circle> circles = {};
      final Set<Marker> markers = {};
      const Color zoneColor = Colors.green;

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

        final icon = await createNameMarker(
          zone.name,
          color: Colors.green,
        );

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
    } catch (e) {
      print('ERROR loading safe zones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
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
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          HomeTopBar(
            onSettingsTap: _onSettingsTap,
            onMessagesTap: _onMessagesTap,
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
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
            color: Colors.white,
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
