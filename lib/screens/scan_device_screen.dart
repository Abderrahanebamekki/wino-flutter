import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import '../service/device_service.dart';
import '../theme/app_colors.dart';
import '../widgets/back_title_bar.dart';

class ScanDeviceScreen extends StatefulWidget {
  final int childId;

  const ScanDeviceScreen({super.key, required this.childId});

  @override
  State<ScanDeviceScreen> createState() => _ScanDeviceScreenState();
}

class _ScanDeviceScreenState extends State<ScanDeviceScreen> {
  MobileScannerController? _scannerController;
  String? _scannedValue;
  bool _isScanning = true;
  bool _isLoading = false;
  bool _isLinking = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    setState(() => _isLoading = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final String? qrData =
            await QrCodeToolsPlugin.decodeFrom(image.path);
        if (qrData != null && qrData.isNotEmpty) {
          setState(() {
            _scannedValue = qrData;
            _isScanning = false;
          });
          _scannerController?.stop();
          if (mounted) _showResultDialog(qrData);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No QR code found in the image')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanning && capture.barcodes.isNotEmpty) {
      final String? value = capture.barcodes.first.rawValue;
      if (value != null && value.isNotEmpty) {
        setState(() {
          _scannedValue = value;
          _isScanning = false;
        });
        _scannerController?.stop();
        _showResultDialog(value);
      }
    }
  }

  void _showResultDialog(String value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        ),
        title: const Text('QR Code Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scanned Value:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              ),
              child: SelectableText(value, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Scan Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleScannedValue(value);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScannedValue(String deviceId) async {
    setState(() => _isLinking = true);

    try {
      await DeviceService.linkChildToDevice(
        childId: widget.childId,
        deviceId: deviceId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device linked to child successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error linking device: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isLinking = false;
        _isScanning = true;
        _scannedValue = null;
      });
      _scannerController?.start();
    }
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _scannedValue = null;
    });
    _scannerController?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackTitleBar(title: 'Scan Device'),
      body: _isLinking
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Linking device to child...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _isScanning
                      ? Stack(
                          children: [
                            MobileScanner(
                              controller: _scannerController!,
                              onDetect: _onDetect,
                            ),
                            Center(
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primaryDark,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Text(
                                'Position QR code within the frame',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(blurRadius: 10, color: Colors.black54),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code_rounded,
                                size: 80,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'QR Code Scanned!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _scannedValue ?? '',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onPressed: _resetScanner,
                        isActive: _isScanning,
                      ),
                      _buildActionButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onPressed: _isLoading ? () {} : _pickImageFromGallery,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryDark : AppColors.background,
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      color:
                          isActive ? Colors.white : AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
