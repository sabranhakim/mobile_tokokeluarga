import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../../data/models/penerimaan_barang_model.dart';
import '../../data/models/barang_keluar_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedSegment = 0;
  int _selectedFilter = 0;
  String _searchQuery = '';

  static const Color primaryDarkColor = Color(0xFF3B4856);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSegmentControl(),
                    const SizedBox(height: 16),
                    if (_selectedSegment == 0) ...[
                      _buildFilterChips(),
                      const SizedBox(height: 16),
                    ],
                    _buildSearchField(),
                    const SizedBox(height: 24),
                    _selectedSegment == 0
                        ? _buildPenerimaanList()
                        : _buildBarangKeluarList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'TOKO KELUARGA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12, width: 1),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: () => _showLogoutDialog(context),
          ),
        ),
      ],
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

  Widget _buildSegmentControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBECEE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSegment(0, 'Penerimaan')),
          Expanded(child: _buildSegment(1, 'Barang Keluar')),
        ],
      ),
    );
  }

  Widget _buildSegment(int index, String label) {
    final isSelected = _selectedSegment == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedSegment = index;
        _selectedFilter = 0;
        _searchQuery = '';
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black87 : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(0, 'Semua'),
          const SizedBox(width: 8),
          _buildFilterChip(1, 'Sudah verifikasi'),
          const SizedBox(width: 8),
          _buildFilterChip(2, 'Belum verifikasi'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryDarkColor : const Color(0xFFEBECEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: _selectedSegment == 0
            ? 'Cari no. terima atau supplier'
            : 'Cari no. keluar atau jenis',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
        fillColor: const Color(0xFFF1F2F4),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPenerimaanList() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        var history = provider.history;

        if (_searchQuery.isNotEmpty) {
          history = history.where((item) {
            final query = _searchQuery.toLowerCase();
            return (item.noTerima ?? '').toLowerCase().contains(query) ||
                item.supplierNama.toLowerCase().contains(query);
          }).toList();
        }

        if (_selectedFilter == 1) {
          history = history.where((e) => e.statusVerifikasi == 'verified').toList();
        } else if (_selectedFilter == 2) {
          history = history.where((e) => e.statusVerifikasi != 'verified').toList();
        }

        if (history.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${history.length} PENERIMAAN',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            ...history.map((item) => _buildPenerimaanCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildPenerimaanCard(PenerimaanBarang item) {
    final isVerified = item.statusVerifikasi == 'verified';
    final totalQty = item.details.fold<int>(0, (sum, d) => sum + d.jumlah);

    String timeText;
    final now = DateTime.now();
    final diff = now.difference(item.tglTerima);
    if (diff.inDays == 0) {
      timeText = 'Hari ini';
    } else if (diff.inDays == 1) {
      timeText = 'Kemarin';
    } else {
      timeText = DateFormat('dd MMM yyyy').format(item.tglTerima);
    }

    return GestureDetector(
      onTap: () => _showPenerimaanDetail(context, item),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.noTerima ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBECEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isVerified ? 'Sudah verifikasi' : 'Belum verifikasi',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.supplierNama,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '$totalQty unit',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (!isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.black87,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (!isVerified) ...[
              const SizedBox(height: 6),
              Text(
                'Tekan untuk verifikasi penerimaan',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBarangKeluarList() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        var history = provider.barangKeluarHistory;

        if (_searchQuery.isNotEmpty) {
          history = history.where((item) {
            final query = _searchQuery.toLowerCase();
            return (item.noKeluar ?? '').toLowerCase().contains(query) ||
                _jenisKeluarLabel(item.jenisKeluar).toLowerCase().contains(query);
          }).toList();
        }

        if (history.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${history.length} BARANG KELUAR',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            ...history.map((item) => _buildBarangKeluarCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildBarangKeluarCard(BarangKeluar item) {
    final totalQty = item.details.fold<int>(0, (sum, d) => sum + d.jumlah);

    String timeText;
    final now = DateTime.now();
    final diff = now.difference(item.tglKeluar);
    if (diff.inDays == 0) {
      timeText = 'Hari ini';
    } else if (diff.inDays == 1) {
      timeText = 'Kemarin';
    } else {
      timeText = DateFormat('dd MMM yyyy').format(item.tglKeluar);
    }

    return GestureDetector(
      onTap: () => _showBarangKeluarDetail(context, item),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.noKeluar ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBECEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _jenisKeluarLabel(item.jenisKeluar),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _jenisKeluarLabel(item.jenisKeluar),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '$totalQty unit',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 56,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada riwayat ditemukan',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _jenisKeluarLabel(String? jenis) {
    switch (jenis) {
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

  void _showPenerimaanDetail(BuildContext context, PenerimaanBarang item) {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final isVerified = item.statusVerifikasi == 'verified';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.supplierNama,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('dd MMM yyyy')
                                  .format(item.tglTerima),
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBECEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isVerified ? 'Sudah verifikasi' : 'Belum verifikasi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailInfoCard([
                    _buildDetailInfoRow(
                      Icons.receipt_outlined,
                      'No. Terima',
                      item.noTerima ?? '-',
                    ),
                    _buildDetailInfoRow(
                      Icons.inventory_2_outlined,
                      'Total Item',
                      '${item.details.length} barang',
                    ),
                    _buildDetailInfoRow(
                      Icons.straighten_outlined,
                      'Total Unit',
                      '${item.details.fold<int>(0, (s, d) => s + d.jumlah)} unit',
                    ),
                  ]),
                  if (!isVerified) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.verified_user_outlined,
                          size: 20,
                        ),
                        label: const Text(
                          'Verifikasi Penerimaan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryDarkColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final catatan = await _showVerifyDialog(context);
                          if (catatan == null) return;
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          try {
                            await provider.verifyPenerimaan(
                              item,
                              catatan: catatan,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Penerimaan berhasil diverifikasi',
                                  ),
                                  backgroundColor: Color(0xFF00851D),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Gagal memverifikasi penerimaan',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                  if (isVerified &&
                      item.catatanVerifikasi != null &&
                      item.catatanVerifikasi!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5FFEA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF00851D),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Catatan Verifikasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF00851D),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.catatanVerifikasi!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF00851D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (item.fotoBonPaths.isNotEmpty) ...[
                    const Text(
                      'Foto Bon',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.fotoBonPaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final path = item.fotoBonPaths[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: path.startsWith('http')
                                ? Image.network(
                                    path,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Daftar Barang',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...item.details.asMap().entries.map((entry) {
                    final i = entry.key;
                    final d = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBECEE),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.barangNama,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                if (d.tglKadaluarsa != null)
                                  Text(
                                    'Exp: ${d.tglKadaluarsa}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black.withValues(alpha: 0.4),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${d.jumlah}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBarangKeluarDetail(BuildContext context, BarangKeluar item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.88,
          minChildSize: 0.4,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.noKeluar ?? '-',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('dd MMM yyyy').format(item.tglKeluar),
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBECEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _jenisKeluarLabel(item.jenisKeluar),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailInfoCard([
                    _buildDetailInfoRow(
                      Icons.receipt_outlined,
                      'No. Keluar',
                      item.noKeluar ?? '-',
                    ),
                    _buildDetailInfoRow(
                      Icons.category_outlined,
                      'Jenis',
                      _jenisKeluarLabel(item.jenisKeluar),
                    ),
                    _buildDetailInfoRow(
                      Icons.inventory_2_outlined,
                      'Total Item',
                      '${item.details.length} barang',
                    ),
                    _buildDetailInfoRow(
                      Icons.straighten_outlined,
                      'Total Unit',
                      '${item.details.fold<int>(0, (s, d) => s + d.jumlah)} unit',
                    ),
                    if (item.keterangan != null && item.keterangan!.isNotEmpty)
                      _buildDetailInfoRow(
                        Icons.notes_outlined,
                        'Keterangan',
                        item.keterangan!,
                      ),
                  ]),
                  const SizedBox(height: 20),
                  const Text(
                    'Daftar Barang',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...item.details.asMap().entries.map((entry) {
                    final i = entry.key;
                    final d = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE5E5),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFBA1A1A),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              d.barangNama,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${d.jumlah} ${d.barangSatuan ?? ''}'.trim(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showVerifyDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Verifikasi Penerimaan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Mis. Barang sesuai bon',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: primaryDarkColor,
                  width: 1.5,
                ),
              ),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDarkColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Verifikasi'),
            ),
          ],
        );
      },
    );
  }
}
