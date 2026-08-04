import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/penerimaan_barang_model.dart';
import '../../data/models/barang_keluar_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Semua';
  int _selectedTab = 0; // 0 = Penerimaan, 1 = Barang Keluar

  void _showDetailModal(BuildContext context, PenerimaanBarang item) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final isSynced = item.isSynced == 1;
    final isVerified = item.statusVerifikasi == 'verified';

    String statusText;
    Color badgeBgColor;
    Color badgeTextColor;

    if (!isSynced) {
      badgeBgColor = colorScheme.errorContainer;
      badgeTextColor = colorScheme.error;
      statusText = 'PENDING SYNC';
    } else if (isVerified) {
      badgeBgColor = const Color(0xFFE5FFEA);
      badgeTextColor = const Color(0xFF00851D);
      statusText = 'TERVERIFIKASI';
    } else {
      badgeBgColor = const Color(0xFFE5EEFF);
      badgeTextColor = const Color(0xFF00236F);
      statusText = 'MENUNGGU VERIFIKASI';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
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
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy • HH:mm').format(item.tglTerima),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (item.noTerima != null) ...[
                    _infoRow(colorScheme, 'No. Terima', item.noTerima!),
                    const SizedBox(height: 4),
                  ],
                  _infoRow(colorScheme, 'Total Item', '${item.details.length} barang'),
                  const SizedBox(height: 4),
                  _infoRow(colorScheme, 'Status Sinkron', isSynced ? 'Tersinkron' : 'Belum Sinkron'),

                  if (isSynced && !isVerified) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('Verifikasi Penerimaan'),
                        onPressed: () async {
                          final catatan = await _showVerifyDialog(context);
                          if (catatan != null) {
                            Navigator.pop(context);
                            try {
                              await provider.verifyPenerimaan(item, catatan: catatan);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Penerimaan berhasil diverifikasi'),
                                    backgroundColor: Color(0xFF00851D),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Gagal memverifikasi penerimaan'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],

                  if (isVerified) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5FFEA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF00851D)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Terverifikasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00851D),
                                  ),
                                ),
                                if (item.catatanVerifikasi != null &&
                                    item.catatanVerifikasi!.isNotEmpty)
                                  Text(
                                    item.catatanVerifikasi!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF00851D),
                                    ),
                                  ),
                                if (item.verifiedAt != null)
                                  Text(
                                    DateFormat('dd MMM yyyy • HH:mm').format(item.verifiedAt!),
                                    style: const TextStyle(
                                      fontSize: 11,
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

                  const Divider(height: 32),

                  // Photos
                  if (item.fotoBonPaths.isNotEmpty) ...[
                    Text('Foto Bon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.fotoBonPaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final path = item.fotoBonPaths[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: path.startsWith('http')
                              ? Image.network(path, width: 120, height: 120, fit: BoxFit.cover)
                              : Image.file(File(path), width: 120, height: 120, fit: BoxFit.cover),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Detail Items
                  Text('Daftar Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                  const SizedBox(height: 8),
                  ...item.details.asMap().entries.map((entry) {
                    final i = entry.key;
                    final d = entry.value;
                    final batchInfo = d.batchNumber != null ? 'Batch: ${d.batchNumber}' : null;
                    final expiryInfo = d.tglKadaluarsa != null ? 'Exp: ${d.tglKadaluarsa}' : null;
                    final subtitle = [batchInfo, expiryInfo].where((e) => e != null).join(' | ');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.barangNama,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${d.jumlah}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(ColorScheme colorScheme, String label, String value) {
    return Row(
      children: [
        Text('$label : ', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
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

  Future<String?> _showVerifyDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Verifikasi Penerimaan'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Mis. Barang sesuai bon',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Verifikasi'),
            ),
          ],
        );
      },
    );
  }

  void _showBarangKeluarDetailModal(BuildContext context, BarangKeluar item) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSynced = item.isSynced == 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.8,
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
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Barang Keluar', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd MMM yyyy').format(item.tglKeluar), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSynced ? const Color(0xFFE5FFEA) : colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isSynced ? 'TERSINKRON' : 'PENDING SYNC',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSynced ? const Color(0xFF00851D) : colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (item.noKeluar != null) ...[
                    _infoRow(colorScheme, 'No. Keluar', item.noKeluar!),
                    const SizedBox(height: 4),
                  ],
                  _infoRow(colorScheme, 'Jenis', _jenisKeluarLabel(item.jenisKeluar)),
                  const SizedBox(height: 4),
                  _infoRow(colorScheme, 'Total Item', '${item.details.length} barang'),
                  const SizedBox(height: 4),
                  if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
                    _infoRow(colorScheme, 'Keterangan', item.keterangan!),
                    const SizedBox(height: 4),
                  ],
                  const Divider(height: 32),
                  Text('Daftar Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                  const SizedBox(height: 8),
                  ...item.details.asMap().entries.map((entry) {
                    final i = entry.key;
                    final d = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28, height: 28, alignment: Alignment.center,
                            decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(8)),
                            child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A), fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.barangNama, style: const TextStyle(fontSize: 15)),
                                if (d.barangIsi > 1 && d.jumlah >= d.barangIsi)
                                  Text(
                                    '${d.jumlah ~/ d.barangIsi} ${d.barangSatuan ?? ''}${d.jumlah % d.barangIsi > 0 ? ' + ${d.jumlah % d.barangIsi} pcs' : ''}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${d.jumlah}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              if (d.barangIsi > 1 && d.jumlah >= d.barangIsi)
                                Text('pcs', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Penerimaan', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 1, label: Text('Barang Keluar', style: TextStyle(fontSize: 12))),
                      ],
                      selected: {_selectedTab},
                      onSelectionChanged: (val) => setState(() => _selectedTab = val.first),
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children:
                  ['Semua', 'Sudah Sync', 'Belum Sync'].map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildPenerimaanHistory(colorScheme)
                : _buildBarangKeluarHistory(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildPenerimaanHistory(ColorScheme colorScheme) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final filteredHistory = provider.history.where((item) {
          if (_selectedFilter == 'Sudah Sync') return item.isSynced == 1;
          if (_selectedFilter == 'Belum Sync') return item.isSynced == 0;
          return true;
        }).toList();

        if (filteredHistory.isEmpty) {
          return _buildEmptyState(colorScheme, provider.unsyncedCount, provider.isSyncing, () => provider.syncData());
        }

        return RefreshIndicator(
          onRefresh: () => provider.init(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredHistory.length + (_selectedFilter == 'Belum Sync' ? 1 : 0),
            itemBuilder: (context, index) {
              if (_selectedFilter == 'Belum Sync' && index == 0) {
                return _buildSyncCard(colorScheme, provider.unsyncedCount, provider.isSyncing, () => provider.syncData());
              }
              final adjustedIndex = _selectedFilter == 'Belum Sync' ? index - 1 : index;
              final item = filteredHistory[adjustedIndex];
              final isSynced = item.isSynced == 1;
              final isVerified = item.statusVerifikasi == 'verified';

              Color badgeBgColor, badgeTextColor; String statusText; IconData statusIcon; Color iconColor, iconBgColor;

              if (!isSynced) {
                badgeBgColor = colorScheme.errorContainer; badgeTextColor = colorScheme.error; statusText = 'PENDING SYNC';
                statusIcon = Icons.sync_problem_rounded; iconColor = colorScheme.error; iconBgColor = colorScheme.errorContainer;
              } else if (isVerified) {
                badgeBgColor = const Color(0xFFE5FFEA); badgeTextColor = const Color(0xFF00851D); statusText = 'TERVERIFIKASI';
                statusIcon = Icons.verified_rounded; iconColor = const Color(0xFF00851D); iconBgColor = const Color(0xFFE5FFEA);
              } else {
                badgeBgColor = const Color(0xFFE5EEFF); badgeTextColor = const Color(0xFF00236F); statusText = 'MENUNGGU VERIFIKASI';
                statusIcon = Icons.cloud_done_outlined; iconColor = const Color(0xFF0058BE); iconBgColor = colorScheme.secondaryContainer;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: InkWell(
                  onTap: () => _showDetailModal(context, item),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)), child: Icon(statusIcon, color: iconColor)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.supplierNama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd MMM yyyy • HH:mm').format(item.tglTerima), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${item.details.length} Item', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(6)),
                            child: Text(statusText, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeTextColor))),
                        ]),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBarangKeluarHistory(ColorScheme colorScheme) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        final filteredHistory = provider.barangKeluarHistory.where((item) {
          if (_selectedFilter == 'Sudah Sync') return item.isSynced == 1;
          if (_selectedFilter == 'Belum Sync') return item.isSynced == 0;
          return true;
        }).toList();

        if (filteredHistory.isEmpty) {
          return _buildEmptyState(colorScheme, provider.unsyncedBarangKeluarCount, provider.isSyncing, () => provider.syncData());
        }

        return RefreshIndicator(
          onRefresh: () => provider.init(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredHistory.length + (_selectedFilter == 'Belum Sync' ? 1 : 0),
            itemBuilder: (context, index) {
              if (_selectedFilter == 'Belum Sync' && index == 0) {
                return _buildSyncCard(colorScheme, provider.unsyncedBarangKeluarCount, provider.isSyncing, () => provider.syncData());
              }
              final adjustedIndex = _selectedFilter == 'Belum Sync' ? index - 1 : index;
              final item = filteredHistory[adjustedIndex];
              final isSynced = item.isSynced == 1;

              Color badgeBgColor, badgeTextColor; String statusText;

              if (!isSynced) {
                badgeBgColor = colorScheme.errorContainer; badgeTextColor = colorScheme.error; statusText = 'PENDING SYNC';
              } else {
                badgeBgColor = const Color(0xFFE5FFEA); badgeTextColor = const Color(0xFF00851D); statusText = 'TERSINKRON';
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: InkWell(
                  onTap: () => _showBarangKeluarDetailModal(context, item),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.output, color: const Color(0xFFBA1A1A))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Barang Keluar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd MMM yyyy').format(item.tglKeluar), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${item.details.length} Item', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(6)),
                            child: Text(statusText, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeTextColor))),
                        ]),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, int count, bool isSyncing, VoidCallback onSync) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: colorScheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Tidak ada riwayat ditemukan', style: TextStyle(color: colorScheme.outline)),
          if (_selectedFilter == 'Belum Sync' && count > 0) ...[
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: isSyncing ? null : onSync,
              icon: isSyncing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
              label: Text(isSyncing ? 'Menyinkronkan...' : 'Sinkronkan Sekarang'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncCard(ColorScheme colorScheme, int count, bool isSyncing, VoidCallback onSync) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.cloud_upload, color: colorScheme.primary)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Sinkronkan $count data', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Kirim data yang belum tersinkron ke server', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
              ]),
            ),
            FilledButton.tonal(
              onPressed: isSyncing ? null : onSync,
              child: isSyncing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
            ),
          ],
        ),
      ),
    );
  }
}
