import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';
import '../models/safe_zone.dart';
import '../service/safezone_service.dart';
import 'child_marker.dart';

class SafeZoneMapWidget extends StatefulWidget {
  final List<SafeZone>? safeZones;
  final int? childId;
  final LatLng? initialCenter;
  final double initialZoom;
  final double? height;
  final bool showZoomControls;

  const SafeZoneMapWidget({
    super.key,
    this.safeZones,
    this.childId,
    this.initialCenter,
    this.initialZoom = 14,
    this.height,
    this.showZoomControls = false,
  }) : assert(safeZones != null || childId != null,
            'Either safeZones or childId must be provided');

  @override
  State<SafeZoneMapWidget> createState() => _SafeZoneMapWidgetState();
}

class _SafeZoneMapWidgetState extends State<SafeZoneMapWidget>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  List<SafeZone> _safeZones = [];
  bool _isLoading = true;
  bool _isPulsing = false;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _loadSafeZones();
    _startPulse();
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  void _startPulse() {
    _pulseTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (timer) {
        if (!mounted) return;
        setState(() => _isPulsing = !_isPulsing);
        _buildCircles();
      },
    );
  }

  @override
  void didUpdateWidget(SafeZoneMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.safeZones != widget.safeZones ||
        oldWidget.childId != widget.childId) {
      _loadSafeZones();
    }
  }

  Future<void> _loadSafeZones() async {
    if (widget.safeZones != null) {
      _safeZones = widget.safeZones!;
      _isLoading = false;
      _buildCircles();
      _buildMarkers();
      return;
    }
    if (widget.childId == null) return;

    setState(() => _isLoading = true);
    try {
      final zones = await SafezoneService.getSafeZone(widget.childId!);
      if (!mounted) return;
      _safeZones = zones;
      _isLoading = false;
      _buildCircles();
      _buildMarkers();
    } catch (e) {
      if (!mounted) return;
      _safeZones = [];
      _isLoading = false;
    }
  }

  void _buildCircles() {
    final Set<Circle> circles = {};
    const Color zoneColor = AppColors.success;
    final pulseAlpha = _isPulsing ? 0.35 : 0.20;
    final strokeAlpha = _isPulsing ? 0.95 : 0.70;
    for (final zone in _safeZones) {
      circles.add(
        Circle(
          circleId: CircleId('sz_${zone.id}'),
          center: LatLng(zone.latitude, zone.longitude),
          radius: zone.radius,
          fillColor: zoneColor.withValues(alpha: pulseAlpha),
          strokeColor: zoneColor.withValues(alpha: strokeAlpha),
          strokeWidth: _isPulsing ? 4 : 3,
          zIndex: 2,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _circles = circles);
  }

  Future<void> _buildMarkers() async {
    final Set<Marker> markers = {};
    for (final zone in _safeZones) {
      final icon =
          await createNameMarker(zone.name, color: AppColors.success);
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
    setState(() => _markers = markers);
  }

  void _fitAllZones() {
    if (_safeZones.isEmpty || _mapController == null) return;
    if (_safeZones.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_safeZones.first.latitude, _safeZones.first.longitude),
          widget.initialZoom,
        ),
      );
      return;
    }

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (final zone in _safeZones) {
      if (zone.latitude < minLat) minLat = zone.latitude;
      if (zone.latitude > maxLat) maxLat = zone.latitude;
      if (zone.longitude < minLng) minLng = zone.longitude;
      if (zone.longitude > maxLng) maxLng = zone.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final LatLng defaultCenter = widget.initialCenter ??
        (_safeZones.isNotEmpty
            ? LatLng(
                _safeZones.first.latitude,
                _safeZones.first.longitude,
              )
            : const LatLng(36.7525, 5.0843));

    Widget map = GoogleMap(
      initialCameraPosition: CameraPosition(
        target: defaultCenter,
        zoom: widget.initialZoom,
      ),
      markers: _markers,
      circles: _circles,
      onMapCreated: (controller) {
        _mapController = controller;
        _fitAllZones();
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: widget.showZoomControls,
      mapToolbarEnabled: false,
    );

    if (widget.height != null) {
      map = SizedBox(height: widget.height, child: map);
    }

    return map;
  }
}
