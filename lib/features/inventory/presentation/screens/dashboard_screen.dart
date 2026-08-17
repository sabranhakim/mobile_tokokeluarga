import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/time_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/inventory_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().init();
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text(
              'Apakah Anda yakin ingin keluar dari aplikasi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AuthProvider>().logout();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer2<AuthProvider, InventoryProvider>(
        builder: (context, auth, provider, child) {
          if (provider.isLoading &&
              provider.barangs.isEmpty &&
              provider.history.isEmpty &&
              provider.barangKeluarHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.init(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(auth),
                  const SizedBox(height: 20),
                  _buildSummaryGrid(provider),
                  const SizedBox(height: 22),
                  BarChartCard(
                    title: 'Penerimaan barang',
                    subtitle: 'Aktivitas penerimaan terkini',
                    weekData: provider.getChartData('Minggu'),
                    monthData: provider.getChartData('Bulan'),
                    barColor: const Color(0xFF8C9BAE),
                  ),
                  const SizedBox(height: 16),
                  BarChartCard(
                    title: 'Barang keluar',
                    subtitle: 'Aktivitas pengeluaran barang terkini',
                    weekData: provider.getBarangKeluarChartData('Minggu'),
                    monthData: provider.getBarangKeluarChartData('Bulan'),
                    barColor: const Color(0xFF5A6B7C),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    final now = TimeService.instance.now();
    final userName = auth.user?.name ?? 'Nadia';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOKO KELUARGA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7A8492),
                letterSpacing: 0.8,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E6EA)),
              ),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded, size: 20),
                color: const Color(0xFF2C3540),
                onPressed: _showLogoutDialog,
              ),
            ),
          ],
        ),
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E252D),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat pagi,',
                  style: TextStyle(fontSize: 14, color: Color(0xFF7A8492)),
                ),
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E252D),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFF1E252D),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEBED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatDate(now),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF505A69),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(InventoryProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildSummaryCard(
                icon: Icons.inventory_2_outlined,
                title: provider.totalBarang.toString(),
                subtitle: 'Stok Barang',
                caption: '${provider.stokRendah} stok rendah',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: _buildSummaryCard(
                icon: Icons.move_to_inbox_outlined,
                title: provider.penerimaanBulanIni.toString(),
                subtitle: 'Penerimaan bulan ini',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: _buildSummaryCard(
                icon: Icons.outbox_outlined,
                title: provider.barangKeluarBulanIni.toString(),
                subtitle: 'Barang keluar bulan ini',
                hasBadge: provider.barangKeluarHariIni > 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildSummaryCard(
                icon: Icons.warning_amber_rounded,
                title: provider.stokKritis.toString(),
                subtitle: 'Stok kritis',
                hasBadge: provider.stokKritis > 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _buildSummaryCard(
                icon: Icons.shopping_bag_outlined,
                title: provider.totalStok.toString(),
                subtitle: 'Total Stok',
                caption: '${provider.penerimaanHariIni} masuk hari ini',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: _buildSummaryCard(
                icon: Icons.add,
                title: provider.penerimaanHariIni.toString(),
                subtitle: 'Masuk hari ini',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? caption,
    bool hasBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 132,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBEF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF2C3540)),
              ),
              if (hasBadge)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF505A69),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E252D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF656F7D),
              height: 1.2,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption,
              style: const TextStyle(fontSize: 9, color: Color(0xFF7D8795)),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class BarChartCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Map<String, double> weekData;
  final Map<String, double> monthData;
  final Color barColor;

  const BarChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.weekData,
    required this.monthData,
    required this.barColor,
  });

  @override
  State<BarChartCard> createState() => _BarChartCardState();
}

class _BarChartCardState extends State<BarChartCard> {
  int _selectedPeriodIndex = 0;
  int? _selectedBarIndex;

  Map<String, double> get _currentData =>
      _selectedPeriodIndex == 0 ? widget.weekData : widget.monthData;

  @override
  Widget build(BuildContext context) {
    final entries = _currentData.entries.toList();
    final values = entries.map((entry) => entry.value).toList();
    final maxValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxValue <= 0 ? 1.0 : maxValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E252D),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7A8492),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEBED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildToggleOption('Minggu', 0),
                    _buildToggleOption('Bulan', 1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(entries.length, (index) {
                final entry = entries[index];
                return _buildBarPill(
                  index: index,
                  day: entry.key,
                  value: entry.value,
                  fillRatio: entry.value / effectiveMax,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, int index) {
    final bool isSelected = _selectedPeriodIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedPeriodIndex = index;
        _selectedBarIndex = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color:
                isSelected ? const Color(0xFF1E252D) : const Color(0xFF7A8492),
          ),
        ),
      ),
    );
  }

  Widget _buildBarPill({
    required int index,
    required String day,
    required double value,
    required double fillRatio,
  }) {
    final bool isSelected = _selectedBarIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedBarIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  if (isSelected)
                    Positioned(
                      top: -28,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E252D),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEBED),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  FractionallySizedBox(
                    heightFactor: fillRatio.clamp(0.0, 1.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 28,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? widget.barColor.withValues(alpha: 0.95)
                                : widget.barColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: widget.barColor.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : [],
                      ),
                    ),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 5),
          Text(
            day,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A8492),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
