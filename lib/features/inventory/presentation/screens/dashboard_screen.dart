import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedFilter = 'Minggu';

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
      appBar: AppBar(
        title: const Text('Dashboard GrosirKue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi Data',
            onPressed: () => context.read<InventoryProvider>().syncData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final colorScheme = Theme.of(context).colorScheme;
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => provider.init(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSyncStatus(provider.unsyncedCount),
                  const SizedBox(height: 8),

                  Text(
                    'Statistik Stok',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _buildSummaryRow(
                        'Total Jenis Barang',
                        provider.totalBarang.toString(),
                        Icons.category_rounded,
                        colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'Total Stok',
                        provider.totalStok.toString(),
                        Icons.inventory_2,
                        colorScheme.secondary,
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'Stok Kritis',
                        provider.stokKritis.toString(),
                        Icons.error_rounded,
                        colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'Stok Rendah',
                        provider.stokRendah.toString(),
                        Icons.warning_amber_rounded,
                        const Color(0xFF9A6700),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Aktivitas Penerimaan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _buildSummaryRow(
                        'Diterima Hari Ini',
                        provider.penerimaanHariIni.toString(),
                        Icons.today,
                        colorScheme.secondary,
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'Supplier Aktif',
                        provider.totalSupplier.toString(),
                        Icons.business,
                        const Color(0xFF004395),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'Total Penerimaan',
                        provider.totalPenerimaan.toString(),
                        Icons.receipt_long,
                        colorScheme.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Receiving Trends',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildFilterButtons(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chart Section
                  _buildChart(provider.getChartData(_selectedFilter)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncStatus(int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            count > 0
                ? LinearGradient(
                  colors: [
                    colorScheme.errorContainer,
                    colorScheme.onErrorContainer.withValues(alpha: 0.05),
                  ],
                )
                : LinearGradient(
                  colors: [
                    colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    colorScheme.secondaryContainer.withValues(alpha: 0.1),
                  ],
                ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              count > 0
                  ? colorScheme.error.withValues(alpha: 0.2)
                  : colorScheme.secondary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: count > 0 ? colorScheme.error : colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              count > 0 ? Icons.sync_problem : Icons.cloud_done_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count > 0 ? '$count Data Tertunda' : 'Status Sinkron',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        count > 0
                            ? colorScheme.error
                            : colorScheme.onSecondaryContainer,
                  ),
                ),
                Text(
                  count > 0
                      ? 'Segera sinkronkan ke server'
                      : 'Data Anda sudah aman di server',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        count > 0
                            ? colorScheme.error.withValues(alpha: 0.7)
                            : colorScheme.onSecondaryContainer.withValues(
                              alpha: 0.7,
                            ),
                  ),
                ),
              ],
            ),
          ),
          if (count > 0)
            FilledButton.tonal(
              onPressed: () => context.read<InventoryProvider>().syncData(),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sync'),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'Minggu',
          label: Text('Minggu'),
          icon: Icon(Icons.view_week),
        ),
        ButtonSegment(
          value: 'Bulan',
          label: Text('Bulan'),
          icon: Icon(Icons.calendar_month),
        ),
      ],
      selected: {_selectedFilter},
      onSelectionChanged: (newSelection) {
        setState(() => _selectedFilter = newSelection.first);
      },
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
    );
  }

  Widget _buildChart(Map<String, double> chartData) {
    if (chartData.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: const Text('Belum ada data visual'),
        ),
      );
    }

    final keys = chartData.keys.toList();
    final values = chartData.values.toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue == 0 ? 5 : maxValue + (maxValue * 0.2),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.secondaryContainer,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${keys[groupIndex]}\n',
                      TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: rod.toY.toInt().toString(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < keys.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            keys[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.outline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.outline,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine:
                    (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(keys.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.tertiary],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
