import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:file_picker/file_picker.dart';

import '../models/child.dart';
import '../service/child_service.dart';
import '../service/safezone_service.dart';
import 'home_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/custom_text_field.dart';

class SafezoneScreen extends StatefulWidget {
  const SafezoneScreen({super.key});

  @override
  State<SafezoneScreen> createState() => _SafezoneScreenState();
}

class _SafezoneScreenState extends State<SafezoneScreen>
    with SingleTickerProviderStateMixin {
  final _safezoneNameController = TextEditingController();
  double _radius = 100;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  Child? _selectedChild;
  List<Child> _children = [];
  bool _isLoadingChildren = true;

  String _selectedLocation = 'No location selected';
  double? _latitude;
  double? _longitude;

  String? _uploadedFileName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final children = await ChildService.getChildren();
      if (mounted) {
        setState(() {
          _children = children;
          _isLoadingChildren = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingChildren = false);
      }
    }
  }

  @override
  void dispose() {
    _safezoneNameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PickSafezoneLocationScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result['name'] as String;
        _latitude = result['latitude'] as double;
        _longitude = result['longitude'] as double;
      });
    }
  }

  Future<void> _pickFile() async {
    setState(() => _isUploading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['kml', 'kmz', 'gpx', 'csv', 'json', 'geojson', 'txt'],
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() {
          _uploadedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeFile() {
    setState(() {
      _uploadedFileName = null;
    });
  }

  Future<void> _addSafezone() async {
    if (_safezoneNameController.text.trim().isEmpty ||
        _selectedChild == null ||
        _latitude == null ||
        _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      await SafezoneService.createSafeZone(
        name: _safezoneNameController.text.trim(),
        radius: _radius,
        longitude: _longitude!,
        latitude: _latitude!,
        childId: _selectedChild!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Safezone added for ${_selectedChild!.fullName}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add safezone: $e')),
        );
      }
    }
  }

  String _radiusLabel(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} km';
    }
    return '${value.toInt()} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Safezone'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppColors.screenPadding,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSafezoneForm(),
                const SizedBox(height: 24),
                _buildRadiusSection(),
                const SizedBox(height: 24),
                _buildChildSelector(),
                const SizedBox(height: 24),
                _buildLocationSection(),
                const SizedBox(height: 24),
                _buildFileUploadSection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safezone Information',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Create a safe area for your child',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildSafezoneForm() {
    return AppCard(
      child: Column(
        children: [
          CustomTextField(
            label: 'Safezone Name',
            hint: 'Home, School, Park...',
            controller: _safezoneNameController,
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Radius',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _radiusLabel(_radius),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryDark,
              inactiveTrackColor: AppColors.primaryDark.withOpacity(0.15),
              thumbColor: AppColors.primaryDark,
              overlayColor: AppColors.primaryDark.withOpacity(0.12),
              trackHeight: 6,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 24),
              valueIndicatorColor: AppColors.primaryDark,
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            child: Slider(
              value: _radius,
              min: 10,
              max: 1000,
              divisions: 99,
              label: _radiusLabel(_radius),
              onChanged: (value) {
                setState(() => _radius = value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '10 m',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  '1000 m',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Child',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _isLoadingChildren
              ? const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : _children.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No children found. Add a child first.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      value: _selectedChild?.id,
                      hint: const Text('Select child'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                          borderSide:
                              const BorderSide(color: AppColors.primaryDark, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: _children.map((child) {
                        return DropdownMenuItem(
                          value: child.id,
                          child: Text(child.fullName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedChild = _children.firstWhere((c) => c.id == value);
                        });
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primaryDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedLocation,
                    style: TextStyle(
                      color: _selectedLocation == 'No location selected'
                          ? AppColors.textHint
                          : AppColors.textBody,
                      fontWeight: _selectedLocation == 'No location selected'
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
    );
  }

  Widget _buildFileUploadSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              const Text(
                'Location File (Optional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Upload KML, GPX, GeoJSON or CSV',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          if (_uploadedFileName != null)
            _buildFileInfo()
          else
            _buildFilePicker(),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
          border: Border.all(
            color: AppColors.primaryDark.withOpacity(0.2),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: _isUploading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 36,
                    color: AppColors.primaryDark.withOpacity(0.6),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to select a file',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supported: KML, KMZ, GPX, CSV, GeoJSON',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFileInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(
          color: AppColors.primaryDark.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.insert_drive_file,
              size: 24,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _uploadedFileName ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Ready to upload',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removeFile,
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.error,
            splashRadius: 20,
            tooltip: 'Remove file',
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _addSafezone,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.surface,
          elevation: 2,
          shadowColor: AppColors.primaryDark.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusLarge),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 22),
            SizedBox(width: 10),
            Text(
              'Add Safezone',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map Picker
// ---------------------------------------------------------------------------

class PickSafezoneLocationScreen extends StatefulWidget {
  const PickSafezoneLocationScreen({super.key});

  @override
  State<PickSafezoneLocationScreen> createState() =>
      _PickSafezoneLocationScreenState();
}

class _PickSafezoneLocationScreenState
    extends State<PickSafezoneLocationScreen> {
  static const String _googleApiKey =
      'AIzaSyBVxb2tMiQi8XGeUEVjBxaSpsityG_LuJY';

  final _searchController = TextEditingController();
  GoogleMapController? _mapController;

  LatLng _pickedLatLng = const LatLng(36.7525, 5.0843);
  String _pickedLocation = 'Selected Location';

  void _selectLocation() {
    Navigator.pop(context, {
      'name': _pickedLocation,
      'latitude': _pickedLatLng.latitude,
      'longitude': _pickedLatLng.longitude,
    });
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pickedLatLng = position;
      _pickedLocation =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _moveToPrediction(Prediction prediction) {
    final description = prediction.description ?? 'Selected place';
    final lat = double.tryParse(prediction.lat ?? '');
    final lng = double.tryParse(prediction.lng ?? '');

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get this place location')),
      );
      return;
    }

    final position = LatLng(lat, lng);
    setState(() {
      _pickedLatLng = position;
      _pickedLocation = description;
      _searchController.text = description;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: description.length),
      );
    });
    FocusScope.of(context).unfocus();
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 17));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLatLng,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            markers: {
              Marker(
                markerId: const MarkerId('safezone_location'),
                position: _pickedLatLng,
              ),
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GooglePlacesAutoCompleteTextFormField(
                textEditingController: _searchController,
                config: const GoogleApiConfig(
                  apiKey: _googleApiKey,
                  countries: ['dz'],
                  fetchPlaceDetailsWithCoordinates: true,
                  debounceTime: 600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search school, hospital, home...',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(color: Colors.black, fontSize: 15),
                onPredictionWithCoordinatesReceived: (prediction) {
                  _moveToPrediction(prediction);
                },
                onSuggestionClicked: (prediction) {
                  final description = prediction.description ?? '';
                  _searchController.text = description;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: description.length),
                  );
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 30,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Text(
                    'Selected: $_pickedLocation',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _selectLocation,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Use This Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
