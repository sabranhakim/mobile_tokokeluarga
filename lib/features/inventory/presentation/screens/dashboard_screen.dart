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
                  // Bento Grid
                  _buildBentoGrid(provider, colorScheme),

                  const SizedBox(height: 28),
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

  

  Widget _buildBentoGrid(InventoryProvider provider, ColorScheme colors) {
    return Column(
      children: [
        // Row 1: Total Barang (2x) + Stok Kritis (1x)
        Row(
          children: [
            Expanded(flex: 2, child: _bentoCard(
              icon: Icons.category_rounded,
              color: colors.primary,
              title: 'Total Barang',
              value: provider.totalBarang.toString(),
              height: 110,
            )),
            const SizedBox(width: 12),
            Expanded(child: _bentoCard(
              icon: Icons.error_rounded,
              color: colors.error,
              title: 'Stok Kritis',
              value: provider.stokKritis.toString(),
              height: 110,
              subtitle: 'Habis',
            )),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Stok Rendah (1x) + Total Stok (2x)
        Row(
          children: [
            Expanded(child: _bentoCard(
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFF9A6700),
              title: 'Stok Rendah',
              value: provider.stokRendah.toString(),
              height: 110,
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _bentoCard(
              icon: Icons.inventory_2,
              color: colors.secondary,
              title: 'Total Stok',
              value: provider.totalStok.toString(),
              height: 110,
            )),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Hari Ini (1x) + Supplier (1x) + Total Penerimaan (1x)
        Row(
          children: [
            Expanded(child: _bentoCard(
              icon: Icons.today,
              color: colors.secondary,
              title: 'Hari Ini',
              value: provider.penerimaanHariIni.toString(),
              height: 110,
            )),
            const SizedBox(width: 12),
            Expanded(child: _bentoCard(
              icon: Icons.business,
              color: const Color(0xFF004395),
              title: 'Supplier',
              value: provider.totalSupplier.toString(),
              height: 110,
            )),
            const SizedBox(width: 12),
            Expanded(child: _bentoCard(
              icon: Icons.receipt_long,
              color: colors.primary,
              title: 'Penerimaan',
              value: provider.totalPenerimaan.toString(),
              height: 110,
            )),
          ],
        ),
      ],
    );
  }

  Widget _bentoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    double height = 110,
    String? subtitle,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
