import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';

import '../widgets/custom_text_field.dart';

class SafezoneScreen extends StatefulWidget {
  const SafezoneScreen({super.key});

  @override
  State<SafezoneScreen> createState() => _SafezoneScreenState();
}

class _SafezoneScreenState extends State<SafezoneScreen> {
  final TextEditingController _safezoneNameController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  String? _selectedChild;

  final List<String> _children = [
    'Emma Johnson',
    'Liam Smith',
    'Olivia Brown',
  ];

  String _selectedLocation = 'No location selected';
  double? _latitude;
  double? _longitude;

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PickSafezoneLocationScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['name'] as String;
        _latitude = result['latitude'] as double;
        _longitude = result['longitude'] as double;
      });
    }
  }

  void _addSafezone() {
    if (_safezoneNameController.text.trim().isEmpty ||
        _radiusController.text.trim().isEmpty ||
        _selectedChild == null ||
        _latitude == null ||
        _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Safezone added for $_selectedChild')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _safezoneNameController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Add Safezone'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Safezone Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Create a safe area for your child',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 30),

              CustomTextField(
                label: 'Safezone Name',
                hint: 'Home, School, Park...',
                controller: _safezoneNameController,
              ),

              const SizedBox(height: 18),

              CustomTextField(
                label: 'Radius',
                hint: 'Enter radius in meters',
                controller: _radiusController,
                keyboardType: TextInputType.number,
                maxLength: 5,
              ),

              const SizedBox(height: 18),

              const Text(
                'Child',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 6),

              DropdownButtonFormField<String>(
                value: _selectedChild,
                hint: const Text('Select child'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _children.map((child) {
                  return DropdownMenuItem(
                    value: child,
                    child: Text(child),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedChild = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 6),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedLocation,
                        style: TextStyle(
                          color: _selectedLocation == 'No location selected'
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map),
                  label: const Text('Choose Location on Map'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _addSafezone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Add Safezone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  final TextEditingController _searchController = TextEditingController();

  GoogleMapController? _mapController;

  LatLng _pickedLatLng = const LatLng(36.7525, 5.0843);
  String _pickedLocation = 'Selected Location';

  void _selectLocation() {
    Navigator.pop(
      context,
      {
        'name': _pickedLocation,
        'latitude': _pickedLatLng.latitude,
        'longitude': _pickedLatLng.longitude,
      },
    );
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pickedLatLng = position;
      _pickedLocation =
      '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );
  }

  void _moveToPrediction(Prediction prediction) {
    final description = prediction.description ?? 'Selected place';

    final lat = double.tryParse(prediction.lat ?? '');
    final lng = double.tryParse(prediction.lng ?? '');

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get this place location'),
        ),
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

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 17),
    );
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
            onMapCreated: (controller) {
              _mapController = controller;
            },
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _selectLocation,
                    icon: const Icon(
                      Icons.check,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Use This Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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