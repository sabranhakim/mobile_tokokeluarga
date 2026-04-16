import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../../data/models/barang_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/penerimaan_barang_model.dart';
import '../../data/models/detail_penerimaan_model.dart';

class InputBarangFormScreen extends StatefulWidget {
  final String photoPath;
  const InputBarangFormScreen({super.key, required this.photoPath});

  @override
  State<InputBarangFormScreen> createState() => _InputBarangFormScreenState();
}

class _InputBarangFormScreenState extends State<InputBarangFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Supplier? _selectedSupplier;
  final List<DetailPenerimaanTemp> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    // Add one empty item row by default
    _addItemRow();
  }

  void _addItemRow() {
    setState(() {
      _selectedItems.add(DetailPenerimaanTemp());
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      if (_selectedItems.length > 1) {
        _selectedItems.removeAt(index);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi data dan pilih supplier')),
      );
      return;
    }

    // Convert temp items to DetailPenerimaan
    final details = _selectedItems.where((e) => e.barang != null && e.jumlah > 0).map((e) {
      return DetailPenerimaan(
        barangId: e.barang!.id,
        barangNama: e.barang!.namaBarang,
        jumlah: e.jumlah,
      );
    }).toList();

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 barang yang valid')),
      );
      return;
    }

    final penerimaan = PenerimaanBarang(
      supplierId: _selectedSupplier!.id,
      supplierNama: _selectedSupplier!.namaSupplier,
      tglTerima: DateTime.now(),
      fotoBonPath: widget.photoPath,
      details: details,
    );

    await context.read<InventoryProvider>().saveOffline(penerimaan);
    
    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil disimpan secara offline')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Penerimaan')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(widget.photoPath),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              
              // Supplier Dropdown
              DropdownButtonFormField<Supplier>(
                decoration: const InputDecoration(
                  labelText: 'Pilih Supplier',
                  border: OutlineInputBorder(),
                ),
                value: _selectedSupplier,
                items: provider.suppliers.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.namaSupplier));
                }).toList(),
                onChanged: (val) => setState(() => _selectedSupplier = val),
                validator: (val) => val == null ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 24),
              
              const Text('Daftar Barang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),

              // Dynamic Item List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedItems.length,
                itemBuilder: (context, index) {
                  return _buildItemRow(index, provider.barangs);
                },
              ),

              TextButton.icon(
                onPressed: _addItemRow,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Baris Barang'),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan Penerimaan', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, List<Barang> availableBarangs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<Barang>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Barang', border: OutlineInputBorder()),
              value: _selectedItems[index].barang,
              items: availableBarangs.map((b) {
                return DropdownMenuItem(value: b, child: Text(b.namaBarang));
              }).toList(),
              onChanged: (val) => setState(() => _selectedItems[index].barang = val),
              validator: (val) => val == null ? 'Pilih' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (val) => _selectedItems[index].jumlah = int.tryParse(val) ?? 0,
              validator: (val) => (int.tryParse(val ?? '') ?? 0) <= 0 ? 'Min 1' : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeItemRow(index),
          ),
        ],
      ),
    );
  }
}

// Helper class for UI management
class DetailPenerimaanTemp {
  Barang? barang;
  int jumlah = 0;
}
