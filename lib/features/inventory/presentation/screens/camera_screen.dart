import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'input_barang_form_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  static const int _maxPhotos = 3;
  final List<String> _capturedPaths = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Error initializing camera: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_capturedPaths.length >= _maxPhotos) return;

    try {
      final XFile photo = await _controller!.takePicture();
      if (mounted) {
        setState(() {
          _capturedPaths.add(photo.path);
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _capturedPaths.removeAt(index);
    });
  }

  void _proceedToForm() {
    if (_capturedPaths.isEmpty) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InputBarangFormScreen(photoPaths: List.from(_capturedPaths)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Text('Menyiapkan Kamera...', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ],
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;
    final takenCount = _capturedPaths.length;
    final remaining = _maxPhotos - takenCount;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fullscreen Camera Preview
          if (takenCount < _maxPhotos)
            Transform.scale(
              scale: 1 / (_controller!.value.aspectRatio * size.aspectRatio),
              child: Center(
                child: CameraPreview(_controller!),
              ),
            )
          else
            Container(color: Colors.black),

          // Immersive Overlay
          if (takenCount < _maxPhotos)
            Positioned.fill(
              child: CustomPaint(
                painter: CameraGridPainter(colorScheme.primary),
              ),
            ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'FOTO BON PENERIMAAN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Counter badge
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$takenCount/$_maxPhotos',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Captured photos strip
          if (takenCount > 0)
            Positioned(
              bottom: 180,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 80,
                child: Center(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    itemCount: takenCount,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_capturedPaths[index]),
                                height: 80,
                                width: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      // Left: Retake button
                      if (takenCount > 0 && takenCount < _maxPhotos)
                        Flexible(
                          child: TextButton.icon(
                            onPressed: _takePicture,
                            icon: const Icon(Icons.camera_alt, color: Colors.white70, size: 20),
                            label: Text(
                              'Ambil Lagi',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      else
                        const Spacer(flex: 1),

                      // Capture button (hidden if max reached)
                      if (takenCount < _maxPhotos)
                        GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            height: 76,
                            width: 76,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.camera_alt_rounded, size: 28, color: colorScheme.primary),
                            ),
                          ),
                        )
                      else
                        const Spacer(flex: 1),

                      // Right: Proceed button
                      if (takenCount > 0)
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _proceedToForm,
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: const Text('Lanjut'),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          ),
                        )
                      else
                        const Spacer(flex: 1),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraGridPainter extends CustomPainter {
  final Color primaryColor;
  CameraGridPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);

    final focusPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final margin = size.width * 0.1;
    final rect = Rect.fromLTWH(
      margin,
      size.height * 0.2,
      size.width - (margin * 2),
      size.height * 0.55,
    );

    const cornerLength = 40.0;

    canvas.drawPath(Path()
      ..moveTo(rect.left, rect.top + cornerLength)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + cornerLength, rect.top), focusPaint);

    canvas.drawPath(Path()
      ..moveTo(rect.right - cornerLength, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + cornerLength), focusPaint);

    canvas.drawPath(Path()
      ..moveTo(rect.left, rect.bottom - cornerLength)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left + cornerLength, rect.bottom), focusPaint);

    canvas.drawPath(Path()
      ..moveTo(rect.right - cornerLength, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.bottom - cornerLength), focusPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
