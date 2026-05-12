import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'camera_screen.dart';
import '../providers/inventory_provider.dart';

class InputBarangScreen extends StatelessWidget {
  const InputBarangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Penerimaan'),
        actions: [
          if (provider.unsyncedCount > 0)
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
              tooltip: 'Sync Data',
              onPressed: () => provider.syncData(),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.receipt_long, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 24),
            const Text(
              'Mulai Penerimaan Baru',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ambil foto bon atau surat jalan dari supplier untuk memulai pencatatan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            
            if (provider.isSyncing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sedang menyinkronkan data...'),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraScreen()),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('AMBIL FOTO BON'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            
            const SizedBox(height: 24),
            
            if (provider.unsyncedCount > 0 && !provider.isSyncing)
              OutlinedButton.icon(
                onPressed: () => provider.syncData(),
                icon: const Icon(Icons.sync),
                label: Text('SINKRONKAN (${provider.unsyncedCount}) DATA'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
