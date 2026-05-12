import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
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

  // Colors from HTML Palette
  final Color colorPrimary = const Color(0xFF00236F);
  final Color colorSecondary = const Color(0xFF0058BE);
  final Color colorBackground = const Color(0xFFF8F9FF);
  final Color colorSurface = const Color(0xFFFFFFFF);
  final Color colorOutlineVariant = const Color(0xFFC5C5D3);
  final Color colorOnSurfaceVariant = const Color(0xFF444651);
  final Color colorError = const Color(0xFFBA1A1A);

  @override
  void initState() {
    super.initState();
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final randomHex = _generateRandomHex(6);
    _noTerimaController.text = 'TRM-$dateStr$randomHex';
    
    _addItemRow();
    
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorPrimary,
              onPrimary: Colors.white,
              onSurface: colorPrimary,
            ),
          ),
          child: child!,
        );
      },
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
        SnackBar(
          content: const Text('Mohon lengkapi data dan pilih supplier'),
          backgroundColor: colorError,
        ),
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
        SnackBar(
          content: const Text('Minimal harus ada 1 barang yang valid'),
          backgroundColor: colorError,
        ),
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

    await context.read<InventoryProvider>().submitPenerimaan(penerimaan);
    
    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proses penyimpanan data selesai'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorSurface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Icon(Icons.inventory_2, color: colorPrimary),
            const SizedBox(width: 8),
            Text(
              'Goods Receiving',
              style: TextStyle(
                color: colorPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE5EEFF),
              child: Icon(Icons.person, size: 20, color: colorPrimary),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colorOutlineVariant, height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Preview Area
              GestureDetector(
                onTap: () => Navigator.pop(context), // Go back to re-take if needed
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: colorOutlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(widget.photoPath),
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF4FF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add_a_photo, color: colorPrimary, size: 24),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Receipt Captured',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Tap to retake photo',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Basic Info Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: colorOutlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      label: 'Receipt No',
                      child: TextFormField(
                        controller: _noTerimaController,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: _inputDecoration('e.g. GR-99238'),
                        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Date',
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: _inputDecoration('').copyWith(
                            suffixIcon: Icon(Icons.calendar_today, size: 20, color: colorOnSurfaceVariant),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Supplier',
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorOutlineVariant, width: 2),
                        ),
                        child: DropdownSearch<Supplier>(
                          items: provider.suppliers,
                          selectedItem: _selectedSupplier,
                          compareFn: (a, b) => a.id == b.id,
                          onChanged: (val) => setState(() => _selectedSupplier = val),
                          filterFn: (item, filter) => 
                            item.namaSupplier.toLowerCase().contains(filter.toLowerCase()),
                          dropdownBuilder: (context, selectedItem) {
                            return Text(
                              selectedItem?.namaSupplier ?? 'Select Supplier',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selectedItem == null ? FontWeight.normal : FontWeight.w500,
                                color: selectedItem == null ? colorOutlineVariant : colorPrimary,
                              ),
                            );
                          },
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            menuProps: MenuProps(
                              borderRadius: BorderRadius.circular(12),
                              elevation: 4,
                            ),
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Cari nama supplier...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: colorOutlineVariant),
                                ),
                              ),
                            ),
                            itemBuilder: (context, item, isSelected) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Text(
                                item.namaSupplier,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Received Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Received Items',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedItems.length} Items Total',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorOnSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Items Table Look
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: colorOutlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      color: const Color(0xFFEFF4FF),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Item / SKU',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorOnSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Qty',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorOnSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFC5C5D3)),
                    
                    // Table Body
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedItems.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFC5C5D3)),
                      itemBuilder: (context, index) {
                        return _buildItemTableRow(index, provider.barangs);
                      },
                    ),
                    
                    // Add Row Button
                    Container(
                      color: const Color(0xFFF8F9FF),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextButton.icon(
                        onPressed: _addItemRow,
                        icon: Icon(Icons.library_add, size: 18, color: colorPrimary),
                        label: Text(
                          'Add Row',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // Actions
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.task_alt),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  elevation: 4,
                  shadowColor: colorPrimary.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colorOutlineVariant, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: colorOnSurfaceVariant,
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorOutlineVariant, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8F9FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorOutlineVariant, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorOutlineVariant, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorSecondary, width: 2),
      ),
      errorStyle: const TextStyle(height: 0),
    );
  }

  Widget _buildItemTableRow(int index, List<Barang> availableBarangs) {
    // Find the current barang in the available list to ensure exact reference match
    Barang? currentBarang;
    if (_selectedItems[index].barang != null) {
      try {
        currentBarang = availableBarangs.firstWhere((b) => b.id == _selectedItems[index].barang!.id);
      } catch (_) {
        currentBarang = null;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: index % 2 == 1 ? const Color(0xFFF8F9FF).withOpacity(0.5) : Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SKU Searchable Dropdown
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorOutlineVariant.withOpacity(0.5)),
              ),
              child: DropdownSearch<Barang>(
                items: availableBarangs,
                selectedItem: currentBarang,
                compareFn: (a, b) => a.id == b.id,
                filterFn: (item, filter) => 
                  item.kodeBarang.toLowerCase().contains(filter.toLowerCase()) || 
                  item.namaBarang.toLowerCase().contains(filter.toLowerCase()),
                onChanged: (val) => setState(() => _selectedItems[index].barang = val),
                dropdownBuilder: (context, selectedItem) {
                  if (selectedItem == null) {
                    return const Text('Pilih SKU / Nama Barang', 
                      style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedItem.kodeBarang, 
                        style: TextStyle(
                          color: colorPrimary, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        selectedItem.namaBarang, 
                        style: TextStyle(
                          color: colorOnSurfaceVariant,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  );
                },
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: InputBorder.none,
                    errorStyle: TextStyle(height: 0),
                    isDense: true,
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  menuProps: MenuProps(
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                  ),
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Cari baranng',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colorOutlineVariant),
                      ),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 400),
                  itemBuilder: (context, item, isSelected) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.kodeBarang, 
                          style: TextStyle(
                            color: colorPrimary, 
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.namaBarang, 
                          style: TextStyle(
                            color: colorOnSurfaceVariant,
                            fontSize: 13,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                validator: (val) => val == null ? '' : null,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Qty Field (tanpa label)
          SizedBox(
            width: 75,
            child: TextFormField(
              initialValue: _selectedItems[index].jumlah > 0 ? _selectedItems[index].jumlah.toString() : '',
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF00236F)),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Qty',
                hintStyle: TextStyle(fontSize: 13, color: colorPrimary.withOpacity(0.4), fontWeight: FontWeight.normal),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                isDense: true,
                errorStyle: const TextStyle(height: 0),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorPrimary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorOutlineVariant),
                ),
              ),
              onChanged: (val) => _selectedItems[index].jumlah = int.tryParse(val) ?? 0,
              validator: (val) => (int.tryParse(val ?? '') ?? 0) <= 0 ? '' : null,
            ),
          ),
          const SizedBox(width: 4),

          // Delete
          IconButton(
            onPressed: () => _removeItemRow(index),
            icon: Icon(Icons.delete_outline_rounded, color: colorError.withOpacity(0.6), size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class DetailPenerimaanTemp {
  Barang? barang;
  int jumlah = 0;
}

