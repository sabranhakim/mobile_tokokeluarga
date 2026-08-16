import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../../core/time_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../../data/models/barang_model.dart';
import '../../data/models/barang_keluar_model.dart';
import '../../data/models/detail_barang_keluar_model.dart';

class BarangKeluarFormScreen extends StatefulWidget {
  const BarangKeluarFormScreen({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  State<BarangKeluarFormScreen> createState() => _BarangKeluarFormScreenState();
}

class _BarangKeluarFormScreenState extends State<BarangKeluarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _jenisKeluar = 'penjualan';
  final _keteranganController = TextEditingController();
  final List<DetailBarangKeluarTemp> _selectedItems = [];

  final Color colorPrimary = const Color(0xFF00236F);
  final Color colorSecondary = const Color(0xFF0058BE);
  final Color colorBackground = const Color(0xFFF8F9FF);
  final Color colorOutlineVariant = const Color(0xFFC5C5D3);
  final Color colorOnSurfaceVariant = const Color(0xFF444651);
  final Color colorError = const Color(0xFFBA1A1A);

  @override
  void initState() {
    super.initState();
    final now =
        TimeService.instance.isInitialized
            ? TimeService.instance.now()
            : DateTime.now();
    _selectedDate = now;
    _addItemRow();

    if (!TimeService.instance.isInitialized) {
      TimeService.instance.init().then((_) {
        if (mounted) {
          setState(() {
            _selectedDate = TimeService.instance.now();
          });
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().init();
    });
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  void _addItemRow() {
    setState(() {
      _selectedItems.add(DetailBarangKeluarTemp());
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      if (_selectedItems.length > 1) {
        _selectedItems.removeAt(index);
      }
    });
  }

  String get _jenisKeluarLabel {
    switch (_jenisKeluar) {
      case 'kerusakan':
        return 'Kerusakan';
      case 'kadaluarsa':
        return 'Kadaluarsa';
      case 'pemakaian_internal':
        return 'Pemakaian Internal';
      default:
        return 'Penjualan';
    }
  }

  String _formatRupiah(num value) {
    final formatted = NumberFormat(
      '#,##0',
      'en_US',
    ).format(value).replaceAll(',', '.');
    return 'Rp $formatted';
  }

  int get _totalHargaKeluar {
    if (_jenisKeluar != 'penjualan') return 0;

    var total = 0;
    for (final item in _selectedItems) {
      final harga = item.barang?.hargaJual ?? 0;
      total += item.jumlah * harga;
    }
    return total;
  }

  List<DetailBarangKeluar> _currentValidDetails() {
    return _selectedItems.where((e) => e.barang != null && e.jumlah > 0).map((
      e,
    ) {
      return DetailBarangKeluar(
        barangId: e.barang!.id,
        barangNama: e.barang!.namaBarang,
        barangSatuan: e.barang!.satuan,
        barangIsi: e.barang!.isi,
        jumlah: e.jumlah,
      );
    }).toList();
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

  List<String> _findDuplicateWarnings({
    required List<DetailBarangKeluar> details,
  }) {
    final warnings = <String>[];
    final itemCounts = <String, int>{};
    for (final detail in details) {
      itemCounts[detail.barangId] = (itemCounts[detail.barangId] ?? 0) + 1;
    }
    if (itemCounts.values.any((count) => count > 1)) {
      warnings.add('Ada barang yang dipilih lebih dari sekali di form ini.');
    }
    return warnings;
  }

  Future<bool> _showPreviewDialog(List<DetailBarangKeluar> details) async {
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
                'Ringkasan Barang Keluar',
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
                  _buildPreviewRow(
                    'Tanggal',
                    DateFormat('dd MMMM yyyy').format(_selectedDate),
                  ),
                  _buildPreviewRow('Jenis', _jenisKeluarLabel),
                  if (_keteranganController.text.isNotEmpty)
                    _buildPreviewRow('Keterangan', _keteranganController.text),
                  const SizedBox(height: 12),
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  '${detail.jumlah} ${detail.barangSatuan}'
                                      .trim(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
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
                        if (_jenisKeluar == 'penjualan') ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Harga Penjualan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatRupiah(_totalHargaKeluar),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0058BE),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFC857)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF9A6700),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Stok akan langsung berkurang setelah disimpan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6F4E00),
                            ),
                          ),
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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mohon lengkapi data'),
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

    for (var detail in details) {
      final barang = provider.barangs.firstWhere(
        (b) => b.id == detail.barangId,
        orElse:
            () => Barang(
              id: '',
              kodeBarang: '',
              namaBarang: '',
              satuan: '',
              stok: 0,
            ),
      );
      if (barang.stok < detail.jumlah) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stok ${barang.namaBarang} tidak mencukupi. Tersedia: ${barang.stok}',
            ),
            backgroundColor: colorError,
          ),
        );
        return;
      }
    }

    final duplicateWarnings = _findDuplicateWarnings(details: details);
    if (duplicateWarnings.isNotEmpty) {
      final shouldContinue = await _confirmDuplicateRisk(duplicateWarnings);
      if (!shouldContinue) return;
    }

    final shouldSave = await _showPreviewDialog(details);
    if (!shouldSave) return;

    final barangKeluar = BarangKeluar(
      tglKeluar: _selectedDate,
      jenisKeluar: _jenisKeluar,
      keterangan:
          _keteranganController.text.isNotEmpty
              ? _keteranganController.text
              : null,
      details: details,
    );

    try {
      await provider.submitBarangKeluar(barangKeluar);
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
      _resetForm();
      widget.onSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Barang keluar berhasil dicatat dan stok telah diperbarui',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetForm() {
    _keteranganController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _selectedDate =
          TimeService.instance.isInitialized
              ? TimeService.instance.now()
              : DateTime.now();
      _jenisKeluar = 'penjualan';
      _selectedItems
        ..clear()
        ..add(DetailBarangKeluarTemp());
    });
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBECEE),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        color: Colors.black87,
                        onPressed: () => _showLogoutDialog(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBECEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B4856),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.outbox_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'BARANG KELUAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black45,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Catat barang yang keluar.',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E252D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pilih jenis transaksi dan barang agar stok diperbarui dengan tepat.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'TANGGAL',
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        'Pilih tanggal',
                      ).copyWith(
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                      ),
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  label: 'JENIS',
                  child: DropdownButtonFormField<String>(
                    value: _jenisKeluar,
                    items: const [
                      DropdownMenuItem(
                        value: 'penjualan',
                        child: Text('Penjualan'),
                      ),
                      DropdownMenuItem(
                        value: 'kerusakan',
                        child: Text('Kerusakan'),
                      ),
                      DropdownMenuItem(
                        value: 'kadaluarsa',
                        child: Text('Kadaluarsa'),
                      ),
                      DropdownMenuItem(
                        value: 'pemakaian_internal',
                        child: Text('Pemakaian Internal'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _jenisKeluar = value);
                      }
                    },
                    decoration: _inputDecoration('Pilih jenis'),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  label: 'KETERANGAN (OPSIONAL)',
                  child: TextFormField(
                    controller: _keteranganController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      'Tambahkan catatan jika diperlukan',
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Item barang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E252D),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EBEF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_selectedItems.length} SKU',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF505A69),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E4E8)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFFF5F6F8),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'ITEM / SKU',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorOnSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'QTY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorOnSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'STOK',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorOnSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 36),
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
                        itemBuilder:
                            (context, index) =>
                                _buildItemTableRow(index, provider.barangs),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: OutlinedButton.icon(
                          onPressed: _addItemRow,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah item'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            foregroundColor: const Color(0xFF505A69),
                            side: const BorderSide(
                              color: Color(0xFFBFC5CE),
                              style: BorderStyle.solid,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_jenisKeluar == 'penjualan')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      border: Border.all(color: const Color(0xFF6EE7B7)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Harga Penjualan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatRupiah(_totalHargaKeluar),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: colorOnSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Estimasi harga penjualan hanya ditampilkan untuk jenis Penjualan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF444651),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B4856),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 2),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorOutlineVariant, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFFF8F9FF),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorOutlineVariant, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorOutlineVariant, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorSecondary, width: 1.5),
      ),
      errorStyle: const TextStyle(height: 0),
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
      child: Row(
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
                onChanged:
                    (val) => setState(() => _selectedItems[index].barang = val),
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
                      hintText: 'Cari barang',
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 65,
                child: TextFormField(
                  initialValue: item.jumlah > 0 ? item.jumlah.toString() : '',
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
              if (currentBarang != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    currentBarang.satuan,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    currentBarang != null ? '${currentBarang.stok}' : '-',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color:
                          currentBarang != null && currentBarang.stok == 0
                              ? colorError
                              : colorOnSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
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
    );
  }
}

class DetailBarangKeluarTemp {
  Barang? barang;
  int jumlah = 0;
}
