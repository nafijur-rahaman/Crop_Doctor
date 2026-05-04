import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/custom_notification.dart';
import 'result_screen.dart';

/// Crops supported by the ML model.
const List<String> kSupportedCrops = [
  'Tomato',
  'Potato',
  'Corn',
  'Wheat',
  'Rice',
  'Apple',
  'Grape',
  'Pepper',
  'Strawberry',
  'Peach',
  'Cherry',
  'Squash',
  'Soybean',
];

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  bool _isPickingImage = false;
  bool _isCameraInitialized = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(back, ResolutionPreset.high,
          enableAudio: false);
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Crop selector ────────────────────────────────────────────────────────────

  /// Shows a bottom sheet for crop selection and returns the selected crop.
  Future<String?> _selectCrop() async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Crop Type',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A191E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose the crop you are scanning for accurate detection.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: kSupportedCrops.length,
                  itemBuilder: (_, i) {
                    final crop = kSupportedCrops[i];
                    return GestureDetector(
                      onTap: () => Navigator.pop(ctx, crop),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A36C).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF00A36C).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          crop,
                          style: const TextStyle(
                            color: Color(0xFF00A36C),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Capture / pick ──────────────────────────────────────────────────────────

  Future<void> _navigateToResult(Uint8List imageBytes) async {
    final crop = await _selectCrop();
    if (crop == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(imageBytes: imageBytes, crop: crop),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _pickImage(ImageSource.camera);
      return;
    }
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final photo = await _cameraController!.takePicture();
      if (!mounted) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      await _navigateToResult(bytes);
    } catch (_) {
      if (mounted) {
        CustomNotification.show(context, 'Could not capture photo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (!mounted || file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      await _navigateToResult(bytes);
    } catch (_) {
      if (mounted) {
        CustomNotification.show(context, 'Could not open image picker. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    final next = _flashMode == FlashMode.off
        ? FlashMode.auto
        : _flashMode == FlashMode.auto
            ? FlashMode.torch
            : FlashMode.off;
    try {
      await _cameraController!.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {
      if (mounted) CustomNotification.show(context, 'Could not change flash mode.');
    }
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto_outlined;
      case FlashMode.torch:
      case FlashMode.always:
        return Icons.flash_on_outlined;
      default:
        return Icons.flash_off_outlined;
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A191E),
      body: Stack(
        children: [
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!)),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleIcon(Icons.chevron_left, () => Navigator.pop(context)),
                _circleIcon(_flashIcon, _toggleFlash),
              ],
            ),
          ),
          Positioned(
            top: 130,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  _isPickingImage
                      ? 'Selecting crop...'
                      : 'Align the affected leaf within the frame',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(280, 280),
                    painter: ScannerOverlayPainter(),
                  ),
                  if (_isPickingImage)
                    const CircularProgressIndicator(color: Color(0xFF00A36C))
                  else if (!_isCameraInitialized)
                    const Icon(Icons.eco_outlined,
                        color: Color(0xFF00A36C), size: 80),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _bottomAction(Icons.image_outlined,
                      () => _pickImage(ImageSource.gallery)),
                  _shutterButton(),
                  _bottomAction(
                    Icons.insights_outlined,
                    () => CustomNotification.show(
                        context, 'Insights will be added later.'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _bottomAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _shutterButton() {
    return GestureDetector(
      onTap: _takePicture,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00A36C), width: 4),
        ),
        child: const CircleAvatar(radius: 35, backgroundColor: Colors.white),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00A36C)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cs = 40.0;
    const double r = 20.0;

    for (final corners in [
      [Offset(0, cs), Offset(0, r), Offset(0, 0), Offset(r, 0), Offset(cs, 0)],
      [
        Offset(size.width - cs, 0),
        Offset(size.width - r, 0),
        Offset(size.width, 0),
        Offset(size.width, r),
        Offset(size.width, cs)
      ],
      [
        Offset(0, size.height - cs),
        Offset(0, size.height - r),
        Offset(0, size.height),
        Offset(r, size.height),
        Offset(cs, size.height)
      ],
      [
        Offset(size.width - cs, size.height),
        Offset(size.width - r, size.height),
        Offset(size.width, size.height),
        Offset(size.width, size.height - r),
        Offset(size.width, size.height - cs)
      ],
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(corners[0].dx, corners[0].dy)
          ..lineTo(corners[1].dx, corners[1].dy)
          ..quadraticBezierTo(corners[2].dx, corners[2].dy,
              corners[3].dx, corners[3].dy)
          ..lineTo(corners[4].dx, corners[4].dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter _) => false;
}
