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
import 'transaction_success_screen.dart';

class InputBarangFormScreen extends StatefulWidget {
  final List<String> photoPaths;
  const InputBarangFormScreen({super.key, required this.photoPaths});

  @override
  State<InputBarangFormScreen> createState() => _InputBarangFormScreenState();
}

class _InputBarangFormScreenState extends State<InputBarangFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noTerimaController = TextEditingController();
  final _tanggalController = TextEditingController();
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
  static const Color primaryDarkColor = Color(0xFF3B4856);

  @override
  void initState() {
    super.initState();

    final now =
        TimeService.instance.isInitialized
            ? TimeService.instance.now()
            : DateTime.now();
    _selectedDate = now;
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(now);
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
            _tanggalController.text = DateFormat(
              'yyyy-MM-dd',
            ).format(serverNow);
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
    _tanggalController.dispose();
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

  String _formatRupiah(num value) {
    final formatted = NumberFormat(
      '#,##0',
      'en_US',
    ).format(value).replaceAll(',', '.');
    return 'Rp $formatted';
  }

  int get _totalHargaMasuk {
    var total = 0;
    for (final item in _selectedItems) {
      final harga = item.barang?.hargaBeli ?? 0;
      total += item.jumlah * harga;
    }
    return total;
  }

  List<DetailPenerimaan> _currentValidDetails() {
    return _selectedItems.where((e) => e.barang != null && e.jumlah > 0).map((
      e,
    ) {
      return DetailPenerimaan(
        barangId: e.barang!.id,
        barangNama: e.barang!.namaBarang,
        jumlah: e.jumlah,
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
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<bool> _showPreviewDialog(
    List<DetailPenerimaan> details,
    InventoryProvider provider,
  ) async {
    final double totalQty = details.fold<double>(
      0,
      (sum, item) => sum + item.jumlah,
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.rate_review, color: colorPrimary),
              const SizedBox(width: 8),
              const Text(
                'Ringkasan Penerimaan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
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
                  _buildPreviewRow(
                    'Tanggal',
                    DateFormat('dd MMMM yyyy').format(_selectedDate),
                  ),
                  const SizedBox(height: 12),
                  if (widget.photoPaths.isNotEmpty) ...[
                    const Text(
                      'Foto Bon:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          widget.photoPaths.map((path) {
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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
                            orElse:
                                () => Barang(
                                  id: '',
                                  kodeBarang: '',
                                  namaBarang: detail.barangNama,
                                  satuan: '',
                                  stok: 0,
                                ),
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        detail.barangNama,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${detail.jumlah.toStringAsFixed(0)} ${barang.satuan}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (detail.tglKadaluarsa != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Exp: ${detail.tglKadaluarsa}',
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
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              totalQty.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: colorPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Harga Beli',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatRupiah(_totalHargaMasuk),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF047857),
                              ),
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
              child: const Text(
                'Batal & Edit',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Konfirmasi & Simpan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
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
            content: const Text(
              'Gagal terhubung ke server. Data tidak tersimpan.',
            ),
            backgroundColor: colorError,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionSuccessScreen(
            type: TransactionType.penerimaan,
            noTransaksi: penerimaan.noTerima,
            tanggal: penerimaan.tglTerima,
            pihakLabel: 'Supplier',
            pihakValue: penerimaan.supplierNama,
            items: details.map(
              (d) => MapEntry(
                d.barangNama,
                d.jumlah.toStringAsFixed(0),
              ),
            ).toList(),
            totalLabel: 'Total Harga Beli',
            totalValue: _formatRupiah(_totalHargaMasuk),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBECEE),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E4E8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child:
                                widget.photoPaths.isNotEmpty
                                    ? (widget.photoPaths.length == 1
                                        ? Image.file(
                                          File(widget.photoPaths.first),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                        : Row(
                                          children:
                                              widget.photoPaths.map((path) {
                                                return Expanded(
                                                  child: Image.file(
                                                    File(path),
                                                    fit: BoxFit.cover,
                                                    height: 100,
                                                  ),
                                                );
                                              }).toList(),
                                        ))
                                    : Container(
                                      color: const Color(0xFFCFD4DA),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.receipt_long,
                                        color: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                          ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Bon diterima',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foto bon terlampir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bon berhasil dibaca. Periksa data sebelum menyimpan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.5),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Ganti foto',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryDarkColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NO. TERIMA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black45,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _noTerimaController,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration('e.g. GR-99238'),
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Wajib diisi'
                                        : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TANGGAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black45,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _tanggalController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration('').copyWith(
                              suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'SUPPLIER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownSearch<Supplier>(
                  items: provider.suppliers,
                  selectedItem: _selectedSupplier,
                  compareFn: (a, b) => a.id == b.id,
                  filterFn:
                      (item, filter) => item.namaSupplier
                          .toLowerCase()
                          .contains(filter.toLowerCase()),
                  onChanged: (val) => setState(() => _selectedSupplier = val),
                  dropdownBuilder: (context, selectedItem) {
                    if (selectedItem == null) {
                      return const Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 19,
                            color: Color(0xFF7A8492),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Cari atau pilih supplier',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7A8492),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 19,
                          color: primaryDarkColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedItem.namaSupplier,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E252D),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorOutlineVariant,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorOutlineVariant,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorSecondary,
                          width: 1.5,
                        ),
                      ),
                      isDense: true,
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    constraints: const BoxConstraints(maxHeight: 380),
                    menuProps: MenuProps(
                      borderRadius: BorderRadius.circular(12),
                      elevation: 4,
                    ),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Cari nama supplier',
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
                                item.namaSupplier,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected
                                          ? colorPrimary
                                          : colorOnSurfaceVariant,
                                ),
                              ),
                              if (item.noTelp != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.noTelp!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorOnSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Item barang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${_selectedItems.length} SKU',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: colorOutlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
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
                      _buildDashedAddButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    border: Border.all(color: const Color(0xFF6EE7B7)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Harga (Harga Beli)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatRupiah(_totalHargaMasuk),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildDuplicateRiskIndicator(provider),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryDarkColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submit,
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildDashedAddButton() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        onTap: _addItemRow,
        child: CustomPaint(
          painter: _DashedRectPainter(
            color: const Color(0xFFBFC5CE),
            strokeWidth: 1.2,
            dashWidth: 8,
            dashGap: 5,
            radius: 16,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 18,
                  color: colorOnSurfaceVariant.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tambah item',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorOnSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(14),
      color:
          index % 2 == 1
              ? const Color(0xFFF8F9FF).withValues(alpha: 0.5)
              : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
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
                  onChanged:
                      (val) => setState(() {
                        _selectedItems[index].barang = val;
                      }),
                  dropdownBuilder: (context, selectedItem) {
                    if (selectedItem == null) {
                      return const Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 19,
                            color: Color(0xFF7A8492),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pilih SKU atau nama barang',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7A8492),
                              ),
                            ),
                          ),
                        ],
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
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          selectedItem.namaBarang,
                          style: TextStyle(
                            color: colorOnSurfaceVariant,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    );
                  },
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorOutlineVariant,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorOutlineVariant,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorSecondary,
                          width: 1.5,
                        ),
                      ),
                      errorStyle: const TextStyle(height: 0),
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
                        hintText: 'Cari SKU atau nama barang',
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintStyle: TextStyle(color: colorOutlineVariant),
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
                                  fontSize: 14,
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
              const SizedBox(width: 12),
              SizedBox(
                width: 78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextFormField(
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
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: colorPrimary.withValues(alpha: 0.4),
                          fontWeight: FontWeight.normal,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 10,
                        ),
                        isDense: true,
                        errorStyle: const TextStyle(height: 0),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorPrimary.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorOutlineVariant),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          item.jumlah = int.tryParse(val) ?? 0;
                        });
                      },
                      validator:
                          (val) =>
                              (int.tryParse(val ?? '') ?? 0) <= 0 ? '' : null,
                    ),
                    if (currentBarang != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        currentBarang.satuan,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 36,
                child: Align(
                  alignment: Alignment.topCenter,
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
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _selectExpiryDate(context, index),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: 'Tanggal kedaluwarsa (opsional)',
                hintStyle: TextStyle(fontSize: 13, color: colorOutlineVariant),
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: colorOnSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorOutlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorOutlineVariant),
                ),
              ),
              child: Text(
                item.tglKadaluarsa ?? 'Pilih tanggal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      item.tglKadaluarsa == null
                          ? FontWeight.w400
                          : FontWeight.w600,
                  color:
                      item.tglKadaluarsa == null
                          ? colorOutlineVariant
                          : const Color(0xFF1E252D),
                ),
              ),
            ),
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
        _selectedItems[index].tglKadaluarsa = DateFormat(
          'yyyy-MM-dd',
        ).format(picked);
      });
    }
  }
}

class DetailPenerimaanTemp {
  Barang? barang;
  int jumlah = 0;
  String? tglKadaluarsa;
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double radius;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    void drawDashedPath(Path path) {
      for (final metric in path.computeMetrics()) {
        double distance = 0.0;
        while (distance < metric.length) {
          final currentDash = dashWidth;
          final next = (distance + currentDash).clamp(0.0, metric.length);
          canvas.drawPath(metric.extractPath(distance, next), paint);
          distance += currentDash + dashGap;
        }
      }
    }

    final path = Path()..addRRect(rect);
    drawDashedPath(path);
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.radius != radius;
  }
}
