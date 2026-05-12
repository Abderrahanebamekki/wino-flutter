import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../models/child.dart';
import '../models/child_gps.dart';
import '../models/child_vitals.dart';
import '../models/child_device.dart';

import '../service/child_service.dart';
import '../service/child_gps.dart';

import './add_child_screen.dart';
import './safezone_screen.dart';
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

  static const double _bottomNavHeight = 86;
  static const double _panelBottomGap = 18;

  final Random _random = Random();

  bool _isLoading = true;
  String? _errorMessage;

  Set<Marker> _markers = {};

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

  Future<BitmapDescriptor> _createNameMarker(String name) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double width = 260;
    const double height = 90;

    final markerPaint = Paint()..color = Colors.blue;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final bubbleRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 8, width - 16, height - 28),
      const Radius.circular(32),
    );

    canvas.drawRRect(bubbleRect.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawRRect(bubbleRect, markerPaint);

    final trianglePath = Path()
      ..moveTo(width / 2 - 14, height - 22)
      ..lineTo(width / 2 + 14, height - 22)
      ..lineTo(width / 2, height - 4)
      ..close();

    canvas.drawPath(trianglePath.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawPath(trianglePath, markerPaint);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
      textAlign: TextAlign.center,
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    textPainter.layout(maxWidth: width - 32);

    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, 24),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadMarkers() async {
    final Set<Marker> loadedMarkers = {};

    for (final child in _children) {
      final location = _locations[child.id];

      if (location == null) continue;

      final icon = await _createNameMarker(child.fullName);

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
      _showAddOptions();
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

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
               boxShadow: [
            BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          ],
        ),
        child: Row(
        children: [
        Expanded(
        child: _buildAddOption(
        icon: Icons.shield,
        title: 'Safezone',
        color: Colors.green,
        onTap: () {
        Navigator.pop(context);
        Navigator.push(
        context,
        MaterialPageRoute(
        builder: (_) => const SafezoneScreen(),
        ),
        );
        },
        ),
        ),
        const SizedBox(width: 14),
        Expanded(
        child: _buildAddOption(
        icon: Icons.child_care,
        title: 'Child',
        color: Colors.blue,
        onTap: () {
        Navigator.pop(context);
        Navigator.push(
        context,
        MaterialPageRoute(
        builder: (_) => const AddChildScreen(),
        ),
        );
        },
        ),
        ),
        ],
        ),
        ),
        );
      },
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 115,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChildLocation(Child child) {
    final location = _locations[child.id];
    final health = _health[child.id];
    final device = _devices[child.id];

    if (location == null  || health == null || device == null) {
      return;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        17,
      ),
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blue,
                    child: Text(
                      child.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    child.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    Icons.favorite,
                    'Heart Beat',
                    '${health.heartBeat} BPM',
                  ),
                  _infoRow(
                    Icons.monitor_heart,
                    'Oxygen Level',
                    '${health.oxygenLevel}%',
                  ),
                  _infoRow(
                    Icons.battery_full,
                    'Battery Level',
                    '${device.batteryLevel}%',
                  ),
                  _infoRow(
                    Icons.speed,
                    'Speed',
                    '${location.speed.toStringAsFixed(1)} km/h',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(value),
        ],
      ),
    );
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

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Error loading data. Check backend URL, JWT token, and endpoints.',
              textAlign: TextAlign.center,
            ),
          ),
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
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          _buildTopIcons(),
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
              return _buildChildrenPanel(scrollController);
            },
            body: const SizedBox.shrink(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopIconButton(
            icon: Icons.settings,
            onTap: _onSettingsTap,
          ),
          _buildTopIconButton(
            icon: Icons.message,
            onTap: _onMessagesTap,
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.grey[800], size: 24),
      ),
    );
  }

  Widget _buildChildrenPanel(ScrollController scrollController) {
    return Column(
      children: [
        _buildPanelHandle(),
        const SizedBox(height: 8),
        _buildPanelHeader(),
        Expanded(
          child: _buildChildrenList(scrollController),
        ),
      ],
    );
  }

  Widget _buildPanelHandle() {
    return GestureDetector(
      onTap: _toggleChildrenPanel,
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildPanelHeader() {
    return GestureDetector(
      onTap: _toggleChildrenPanel,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const Text(
                'Children Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_children.length} active',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        height: _bottomNavHeight,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.location_on,
              label: 'Location',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.add_circle_outline,
              label: 'Add',
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.card_membership,
              label: 'Memberships',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 95,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.grey,
                size: 27,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenList(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _children.length,
      itemBuilder: (context, index) {
        final child = _children[index];
        return _buildChildItem(child);
      },
    );
  }

  Widget _buildChildItem(Child child) {
    final location = _locations[child.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue,
          child: Text(
            child.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          child.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${child.age} years old',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
        trailing: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blue,
          child: Text(
            location == null
                ? '--'
                : '${location.speed.toStringAsFixed(0)}\nkm/h',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _showChildLocation(child),
      ),
    );
  }
}