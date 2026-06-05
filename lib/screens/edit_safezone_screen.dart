import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/safe_zone.dart';
import '../service/safezone_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/custom_text_field.dart';

class EditSafezoneScreen extends StatefulWidget {
  final SafeZone safezone;

  const EditSafezoneScreen({super.key, required this.safezone});

  @override
  State<EditSafezoneScreen> createState() => _EditSafezoneScreenState();
}

class _EditSafezoneScreenState extends State<EditSafezoneScreen> {
  late TextEditingController _nameController;
  late double _radius;
  late double _latitude;
  late double _longitude;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.safezone.name);
    _radius = widget.safezone.radius;
    _latitude = widget.safezone.latitude;
    _longitude = widget.safezone.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await SafezoneService.updateSafezone(
        id: widget.safezone.id,
        name: _nameController.text.trim(),
        radius: _radius,
        longitude: _longitude,
        latitude: _latitude,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Safezone updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickSafezoneLocationScreen(
          initialLatLng: LatLng(_latitude, _longitude),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'] as double;
        _longitude = result['longitude'] as double;
      });
    }
  }

  String _radiusLabel(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} km';
    return '${value.toInt()} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Safezone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: CustomTextField(
                label: 'Safezone Name',
                hint: 'Home, School, Park...',
                controller: _nameController,
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Radius',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _radiusLabel(_radius),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _radius,
                    min: 10,
                    max: 1000,
                    divisions: 99,
                    label: _radiusLabel(_radius),
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                    ),
                    child: Text(
                      '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map_outlined, size: 20),
                      label: const Text('Choose Location on Map'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primaryDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PickSafezoneLocationScreen extends StatefulWidget {
  final LatLng? initialLatLng;

  const PickSafezoneLocationScreen({super.key, this.initialLatLng});

  @override
  State<PickSafezoneLocationScreen> createState() =>
      _PickSafezoneLocationScreenState();
}

class _PickSafezoneLocationScreenState
    extends State<PickSafezoneLocationScreen> {
  GoogleMapController? _mapController;
  late LatLng _pickedLatLng;

  @override
  void initState() {
    super.initState();
    _pickedLatLng = widget.initialLatLng ?? const LatLng(36.7525, 5.0843);
  }

  void _onMapTap(LatLng position) {
    setState(() => _pickedLatLng = position);
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _selectLocation() {
    Navigator.pop(context, {
      'latitude': _pickedLatLng.latitude,
      'longitude': _pickedLatLng.longitude,
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLatLng,
              zoom: 15,
            ),
            onMapCreated: (c) => _mapController = c,
            onTap: _onMapTap,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _pickedLatLng,
              ),
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 30,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _selectLocation,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Use This Location',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
