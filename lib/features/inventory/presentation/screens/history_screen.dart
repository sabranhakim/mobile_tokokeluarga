import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Penerimaan')),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.history.isEmpty) {
            return const Center(child: Text('Belum ada transaksi diinput.'));
          }
          return RefreshIndicator(
            onRefresh: () => provider.init(),
            child: ListView.builder(
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final item = provider.history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.isSynced == 1 ? Colors.green : Colors.orange,
                      child: Icon(
                        item.isSynced == 1 ? Icons.check : Icons.sync_problem,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(item.supplierNama),
                    subtitle: Text(
                      'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(item.tglTerima)}\n'
                      '${item.details.length} item diterima',
                    ),
                    trailing: Text(
                      item.isSynced == 1 ? 'Synced' : 'Pending',
                      style: TextStyle(
                        color: item.isSynced == 1 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
