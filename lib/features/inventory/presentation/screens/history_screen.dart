import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Hari Ini';

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Penerimaan')),
      body: Column(
        children: [
          // Visual Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children:
                  ['Hari Ini', 'Semua', 'Sudah Sync', 'Belum Sync'].map((
                    filter,
                  ) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = filter);
                          }
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                final filteredHistory =
                    provider.history.where((item) {
                      if (_selectedFilter == 'Hari Ini') {
                        return _isToday(item.tglTerima);
                      }
                      if (_selectedFilter == 'Sudah Sync') {
                        return item.isSynced == 1;
                      }
                      if (_selectedFilter == 'Belum Sync') {
                        return item.isSynced == 0;
                      }
                      return true;
                    }).toList();

                if (filteredHistory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 64,
                          color: colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada riwayat ditemukan',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.init(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
                      final isSynced = item.isSynced == 1;
                      final isVerified = item.statusVerifikasi == 'verified';

                      Color badgeBgColor;
                      Color badgeTextColor;
                      String statusText;
                      IconData statusIcon;
                      Color iconColor;
                      Color iconBgColor;

                      if (!isSynced) {
                        badgeBgColor = colorScheme.errorContainer;
                        badgeTextColor = colorScheme.error;
                        statusText = 'PENDING SYNC';
                        statusIcon = Icons.sync_problem_rounded;
                        iconColor = colorScheme.error;
                        iconBgColor = colorScheme.errorContainer;
                      } else if (isVerified) {
                        badgeBgColor = const Color(0xFFE5FFEA);
                        badgeTextColor = const Color(0xFF00851D);
                        statusText = 'TERVERIFIKASI';
                        statusIcon = Icons.verified_rounded;
                        iconColor = const Color(0xFF00851D);
                        iconBgColor = const Color(0xFFE5FFEA);
                      } else {
                        badgeBgColor = const Color(0xFFE5EEFF);
                        badgeTextColor = const Color(0xFF00236F);
                        statusText = 'MENUNGGU VERIFIKASI';
                        statusIcon = Icons.cloud_done_outlined;
                        iconColor = const Color(0xFF0058BE);
                        iconBgColor = colorScheme.secondaryContainer;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: InkWell(
                          onTap: () {
                            // Detail view logic could go here
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: iconBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(statusIcon, color: iconColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.supplierNama,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy • HH:mm',
                                        ).format(item.tglTerima),
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.details.length} Item',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeBgColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: badgeTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
