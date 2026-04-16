import 'package:flutter/material.dart';
import 'camera_screen.dart';

class InputBarangScreen extends StatelessWidget {
  const InputBarangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Langsung arahkan ke kamera saat halaman ini dibuka
    return const CameraScreen();
  }
}
