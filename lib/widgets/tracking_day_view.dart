import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';
import '../models/child.dart';
import '../models/gps_log.dart';
import '../service/route_service.dart';

class TrackingDayView extends StatefulWidget {
  final List<Child> children;

  const TrackingDayView({
    super.key,
    required this.children,
  });

  @override
  State<TrackingDayView> createState() => _TrackingDayViewState();
}

class _TrackingDayViewState extends State<TrackingDayView> {
  DateTime _selectedDate = DateTime.now();
  Child? _selectedChild;
  List<GpsLog> _routeData = [];
  bool _isLoadingRoute = false;
  String? _routeError;

  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _endpointMarkers = {};

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first;
      _fetchRoute();
    }
  }

  @override
  void didUpdateWidget(TrackingDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children != oldWidget.children && widget.children.isNotEmpty) {
      if (_selectedChild == null ||
          !widget.children.any((c) => c.id == _selectedChild!.id)) {
        setState(() => _selectedChild = widget.children.first);
        _fetchRoute();
      }
    }
  }

  Future<void> _fetchRoute() async {
    if (_selectedChild == null) return;

    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
    });

    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final data = await RouteService.getRoute(_selectedChild!.id, dateStr);

      if (!mounted) return;

      data.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      data.removeWhere((log) =>
          log.latitude == 0 && log.longitude == 0);

      final deduplicated = <GpsLog>[];
      for (final log in data) {
        if (deduplicated.isEmpty ||
            deduplicated.last.latitude != log.latitude ||
            deduplicated.last.longitude != log.longitude) {
          deduplicated.add(log);
        }
      }

      setState(() {
        _routeData = deduplicated;
        _isLoadingRoute = false;
      });

      _buildRouteMap();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRoute = false;
        _routeError = e.toString();
      });
    }
  }

  void _buildRouteMap() {
    if (_routeData.isEmpty) {
      setState(() {
        _polylines = {};
        _endpointMarkers = {};
      });
      return;
    }

    final points = _routeData
        .map((log) => LatLng(log.latitude, log.longitude))
        .toList();

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: points,
      color: AppColors.info,
      width: 4,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    final first = _routeData.first;
    final last = _routeData.last;

    final startMarker = Marker(
      markerId: const MarkerId('route_start'),
      position: LatLng(first.latitude, first.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Start'),
    );

    final endMarker = Marker(
      markerId: const MarkerId('route_end'),
      position: LatLng(last.latitude, last.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'End'),
    );

    setState(() {
      _polylines = {polyline};
      _endpointMarkers = {startMarker, endMarker};
    });

    _fitRouteBounds(points);
  }

  void _fitRouteBounds(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchRoute();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const Center(
        child: Text(
          'No tracking data available',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedChild?.id,
                  decoration: const InputDecoration(
                    labelText: 'Select Child',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: widget.children.map((child) {
                    return DropdownMenuItem(
                      value: child.id,
                      child: Text(child.fullName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedChild = widget.children.firstWhere((c) => c.id == value);
                    });
                    _fetchRoute();
                  },
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingRoute)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_routeError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'No data for this day',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else if (_routeData.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.map_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'No data for this day',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _routeData.first.latitude,
                      _routeData.first.longitude,
                    ),
                    zoom: 14,
                  ),
                  polylines: _polylines,
                  markers: _endpointMarkers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitRouteBounds(
                      _routeData
                          .map((log) => LatLng(log.latitude, log.longitude))
                          .toList(),
                    );
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
