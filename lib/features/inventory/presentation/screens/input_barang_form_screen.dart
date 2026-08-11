import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../../core/time_service.dart';
import '../providers/inventory_provider.dart';
import '../../data/models/barang_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/penerimaan_barang_model.dart';
import '../../data/models/detail_penerimaan_model.dart';

class InputBarangFormScreen extends StatefulWidget {
  final List<String> photoPaths;
  const InputBarangFormScreen({super.key, required this.photoPaths});

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

    final now = TimeService.instance.isInitialized
        ? TimeService.instance.now()
        : DateTime.now();
    _selectedDate = now;
    _noTerimaController.text =
        'TRM-${DateFormat('yyyyMMdd').format(now)}${_generateRandomHex(6)}';
    _noTerimaController.addListener(_refreshDuplicateIndicator);

    _addItemRow();

    if (!TimeService.instance.isInitialized) {
      TimeService.instance.init().then((_) {
        if (mounted) {
          final serverNow = TimeService.instance.now();
          setState(() {
            _selectedDate = serverNow;
          });
          _noTerimaController.text =
              'TRM-${DateFormat('yyyyMMdd').format(serverNow)}${_generateRandomHex(6)}';
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().init();
    });
  }

  String _generateRandomHex(int length) {
    const chars = '0123456789ABCDEF';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  @override
  void dispose() {
    _noTerimaController.removeListener(_refreshDuplicateIndicator);
    _noTerimaController.dispose();
    super.dispose();
  }

  void _refreshDuplicateIndicator() {
    if (mounted) {
      setState(() {});
    }
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

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DetailPenerimaan> _currentValidDetails() {
    return _selectedItems.where((e) => e.barang != null && e.jumlah > 0).map((
      e,
    ) {
      return DetailPenerimaan(
        barangId: e.barang!.id,
        barangNama: e.barang!.namaBarang,
        jumlah: e.jumlah,
        batchNumber: e.batchNumber,
        tglKadaluarsa: e.tglKadaluarsa,
      );
    }).toList();
  }

  List<String> _findDuplicateWarnings({
    required List<PenerimaanBarang> history,
    required List<DetailPenerimaan> details,
  }) {
    final warnings = <String>[];
    final noTerima = _noTerimaController.text.trim().toLowerCase();

    if (noTerima.isNotEmpty) {
      final hasSameNoTerima = history.any(
        (item) => (item.noTerima ?? '').trim().toLowerCase() == noTerima,
      );
      if (hasSameNoTerima) {
        warnings.add('Nomor terima sudah pernah digunakan.');
      }
    }

    final itemCounts = <String, int>{};
    for (final detail in details) {
      itemCounts[detail.barangId] = (itemCounts[detail.barangId] ?? 0) + 1;
    }
    if (itemCounts.values.any((count) => count > 1)) {
      warnings.add('Ada barang yang dipilih lebih dari sekali di form ini.');
    }

    final supplier = _selectedSupplier;
    if (supplier != null && details.isNotEmpty) {
      final selectedBarangIds =
          details.map((detail) => detail.barangId).toSet();
      final hasSameSupplierDateBarang = history.any((item) {
        if (item.supplierId != supplier.id ||
            !_isSameDate(item.tglTerima, _selectedDate)) {
          return false;
        }
        return item.details.any(
          (detail) => selectedBarangIds.contains(detail.barangId),
        );
      });

      if (hasSameSupplierDateBarang) {
        warnings.add(
          'Supplier, tanggal, dan minimal satu barang sama dengan riwayat yang sudah ada.',
        );
      }
    }

    return warnings;
  }

  Future<bool> _confirmDuplicateRisk(List<String> warnings) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Potensi Input Ganda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data ini mirip dengan riwayat yang sudah ada:'),
              const SizedBox(height: 12),
              ...warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(warning)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text('Periksa kembali sebelum menyimpan.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Periksa Lagi'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tetap Simpan'),
            ),
          ],
        );
      },
    );

    return result ?? false;
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

  Future<bool> _showPreviewDialog(List<DetailPenerimaan> details, InventoryProvider provider) async {
    final double totalQty = details.fold<double>(0, (sum, item) => sum + item.jumlah);
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.rate_review, color: colorPrimary),
              const SizedBox(width: 8),
              const Text('Ringkasan Penerimaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mohon periksa kembali data sebelum menyimpan.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _buildPreviewRow('No. Terima', _noTerimaController.text),
                  _buildPreviewRow('Supplier', _selectedSupplier!.namaSupplier),
                  _buildPreviewRow('Tanggal', DateFormat('dd MMMM yyyy').format(_selectedDate)),
                  const SizedBox(height: 12),
                  if (widget.photoPaths.isNotEmpty) ...[
                    const Text(
                      'Foto Bon:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.photoPaths.map((path) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(path),
                            height: 64,
                            width: 64,
                            fit: BoxFit.cover,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Daftar Barang:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        ...details.map((detail) {
                          final barang = provider.barangs.firstWhere(
                            (b) => b.id == detail.barangId,
                            orElse: () => Barang(id: '', kodeBarang: '', namaBarang: detail.barangNama, satuan: '', stok: 0),
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        detail.barangNama,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      '${detail.jumlah.toStringAsFixed(0)} ${barang.satuan}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                if (detail.batchNumber != null || detail.tglKadaluarsa != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      [
                                        if (detail.batchNumber != null) 'Batch: ${detail.batchNumber}',
                                        if (detail.tglKadaluarsa != null) 'Exp: ${detail.tglKadaluarsa}',
                                      ].join(' | '),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorOnSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Jumlah Item',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              totalQty.toStringAsFixed(0),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: colorPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal & Edit', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Konfirmasi & Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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

    final details = _currentValidDetails();

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Minimal harus ada 1 barang yang valid'),
          backgroundColor: colorError,
        ),
      );
      return;
    }

    final provider = context.read<InventoryProvider>();
    final duplicateWarnings = _findDuplicateWarnings(
      history: provider.history,
      details: details,
    );

    if (duplicateWarnings.isNotEmpty) {
      final shouldContinue = await _confirmDuplicateRisk(duplicateWarnings);
      if (!shouldContinue) {
        return;
      }
    }

    final shouldSave = await _showPreviewDialog(details, provider);
    if (!shouldSave) {
      return;
    }

    final penerimaan = PenerimaanBarang(
      noTerima: _noTerimaController.text,
      supplierId: _selectedSupplier!.id,
      supplierNama: _selectedSupplier!.namaSupplier,
      tglTerima: _selectedDate,
      fotoBonPaths: widget.photoPaths,
      details: details,
    );

    try {
      await provider.submitPenerimaan(penerimaan);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal terhubung ke server. Data tidak tersimpan.'),
            backgroundColor: colorError,
          ),
        );
      }
      return;
    }

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
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: widget.photoPaths.length > 1 ? 180 : 240,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: colorOutlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.photoPaths.length == 1
                        ? Image.file(File(widget.photoPaths.first), fit: BoxFit.cover)
                        : Row(
                            children: widget.photoPaths.map((path) {
                              return Expanded(
                                child: Image.file(File(path), fit: BoxFit.cover),
                              );
                            }).toList(),
                          ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
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
                              child: Icon(
                                Icons.add_a_photo,
                                color: colorPrimary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.photoPaths.length} Foto${widget.photoPaths.length > 1 ? '' : ''} Bon',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Tap untuk ganti foto',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
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
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Date',
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: _inputDecoration('').copyWith(
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: colorOnSurfaceVariant,
                            ),
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
                          border: Border.all(
                            color: colorOutlineVariant,
                            width: 2,
                          ),
                        ),
                        child: DropdownSearch<Supplier>(
                          items: provider.suppliers,
                          selectedItem: _selectedSupplier,
                          compareFn: (a, b) => a.id == b.id,
                          onChanged:
                              (val) => setState(() => _selectedSupplier = val),
                          filterFn:
                              (item, filter) => item.namaSupplier
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()),
                          dropdownBuilder: (context, selectedItem) {
                            return Text(
                              selectedItem?.namaSupplier ?? 'Select Supplier',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    selectedItem == null
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                color:
                                    selectedItem == null
                                        ? colorOutlineVariant
                                        : colorPrimary,
                              ),
                            );
                          },
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: colorOutlineVariant,
                                  ),
                                ),
                              ),
                            ),
                            itemBuilder:
                                (context, item, isSelected) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    item.namaSupplier,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedItems.length} Items Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorOnSurfaceVariant,
                      ),
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
                      separatorBuilder:
                          (context, index) => const Divider(
                            height: 1,
                            color: Color(0xFFC5C5D3),
                          ),
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
                        icon: Icon(
                          Icons.library_add,
                          size: 18,
                          color: colorPrimary,
                        ),
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
              _buildDuplicateRiskIndicator(provider),
              const SizedBox(height: 16),

              // Actions
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.task_alt),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  elevation: 4,
                  shadowColor: colorPrimary.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colorOutlineVariant, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: colorOnSurfaceVariant,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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

  Widget _buildDuplicateRiskIndicator(InventoryProvider provider) {
    final warnings = _findDuplicateWarnings(
      history: provider.history,
      details: _currentValidDetails(),
    );

    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        border: Border.all(color: const Color(0xFFFFC857)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFF9A6700)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Potensi input ganda',
                  style: TextStyle(
                    color: Color(0xFF6F4E00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ...warnings.map(
                  (warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      warning,
                      style: const TextStyle(
                        color: Color(0xFF6F4E00),
                        fontSize: 12,
                        height: 1.3,
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

  Widget _buildItemTableRow(int index, List<Barang> availableBarangs) {
    Barang? currentBarang;
    if (_selectedItems[index].barang != null) {
      try {
        currentBarang = availableBarangs.firstWhere(
          (b) => b.id == _selectedItems[index].barang!.id,
        );
      } catch (_) {
        currentBarang = null;
      }
    }

    final item = _selectedItems[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color:
          index % 2 == 1
              ? const Color(0xFFF8F9FF).withValues(alpha: 0.5)
              : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: SKU + Qty + Delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorOutlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: DropdownSearch<Barang>(
                    items: availableBarangs,
                    selectedItem: currentBarang,
                    compareFn: (a, b) => a.id == b.id,
                    filterFn:
                        (item, filter) =>
                            item.kodeBarang.toLowerCase().contains(
                              filter.toLowerCase(),
                            ) ||
                            item.namaBarang.toLowerCase().contains(
                              filter.toLowerCase(),
                            ),
                    onChanged: (val) => setState(() {
                      _selectedItems[index].barang = val;
                      if (val != null && _selectedItems[index].batchNumber == null) {
                        _selectedItems[index].batchNumber = 'BATCH-${val.kodeBarang}-${DateFormat('yyyyMMdd').format(_selectedDate)}';
                      }
                    }),
                    dropdownBuilder: (context, selectedItem) {
                      if (selectedItem == null) {
                        return const Text(
                          'Pilih SKU / Nama Barang',
                          style: TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        );
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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colorOutlineVariant),
                          ),
                        ),
                      ),
                      constraints: const BoxConstraints(maxHeight: 400),
                      itemBuilder:
                          (context, item, isSelected) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
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
              const SizedBox(width: 8),
              SizedBox(
                width: 65,
                child: TextFormField(
                  initialValue:
                      item.jumlah > 0 ? item.jumlah.toString() : '',
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF00236F),
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Qty',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: colorPrimary.withValues(alpha: 0.4),
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    isDense: true,
                    errorStyle: const TextStyle(height: 0),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: colorPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colorOutlineVariant),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      item.jumlah = int.tryParse(val) ?? 0;
                    });
                  },
                  validator:
                      (val) => (int.tryParse(val ?? '') ?? 0) <= 0 ? '' : null,
                ),
              ),
              SizedBox(
                width: 36,
                child: IconButton(
                  onPressed: () => _removeItemRow(index),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colorError.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Batch + Expiry
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.batchNumber ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Batch No (opsional)',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colorOutlineVariant,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorOutlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorOutlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorSecondary),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      item.batchNumber = val.isEmpty ? null : val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectExpiryDate(context, index),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: 'Tgl Exp (opsional)',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorOutlineVariant,
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: colorOnSurfaceVariant,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8F9FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorOutlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorOutlineVariant),
                      ),
                    ),
                    child: Text(
                      item.tglKadaluarsa != null
                          ? item.tglKadaluarsa!
                          : '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectExpiryDate(BuildContext context, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
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
    if (picked != null) {
      setState(() {
        _selectedItems[index].tglKadaluarsa =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
}

class DetailPenerimaanTemp {
  Barang? barang;
  int jumlah = 0;
  String? batchNumber;
  String? tglKadaluarsa;
}
