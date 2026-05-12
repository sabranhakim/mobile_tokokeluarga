import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  final _noTerimaController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Supplier? _selectedSupplier;
  final List<DetailPenerimaanTemp> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    // Auto-generate No Terima matching web dashboard: TRM-YYYYMMDD + 6 random hex chars
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final randomHex = _generateRandomHex(6);
    _noTerimaController.text = 'TRM-$dateStr$randomHex';
    
    _addItemRow();
    
    // Ensure inventory data is loaded for dropdowns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().init();
    });
  }

  String _generateRandomHex(int length) {
    const chars = '0123456789ABCDEF';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi data dan pilih supplier')),
      );
      return;
    }

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
      noTerima: _noTerimaController.text,
      supplierId: _selectedSupplier!.id,
      supplierNama: _selectedSupplier!.namaSupplier,
      tglTerima: _selectedDate,
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
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.photoPath),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              
              // Form Fields
              TextFormField(
                controller: _noTerimaController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Terima',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Terima',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Supplier Dropdown
              DropdownButtonFormField<Supplier>(
                decoration: const InputDecoration(
                  labelText: 'Pilih Supplier',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
                value: _selectedSupplier,
                items: provider.suppliers.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.namaSupplier));
                }).toList(),
                onChanged: (val) => setState(() => _selectedSupplier = val),
                validator: (val) => val == null ? 'Wajib dipilih' : null,
                hint: const Text('Pilih Supplier'),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daftar Barang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: _addItemRow,
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                  ),
                ],
              ),
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

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan Penerimaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, List<Barang> availableBarangs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Barang>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Pilih Barang', border: InputBorder.none),
                    value: _selectedItems[index].barang,
                    items: availableBarangs.map((b) {
                      return DropdownMenuItem(value: b, child: Text(b.namaBarang));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedItems[index].barang = val),
                    validator: (val) => val == null ? 'Pilih' : null,
                  ),
                ),
                if (_selectedItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _removeItemRow(index),
                  ),
              ],
            ),
            const Divider(),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              initialValue: _selectedItems[index].jumlah > 0 ? _selectedItems[index].jumlah.toString() : '',
              keyboardType: TextInputType.number,
              onChanged: (val) => _selectedItems[index].jumlah = int.tryParse(val) ?? 0,
              validator: (val) => (int.tryParse(val ?? '') ?? 0) <= 0 ? 'Minimal 1' : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for UI management
class DetailPenerimaanTemp {
  Barang? barang;
  int jumlah = 0;
}
