import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_card.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  int _selectedTab = 0; // 0: Cash Flow, 1: Kategori, 2: Laba Rugi

  final List<Map<String, dynamic>> _categoryBreakdown = [
    {
      'name': 'Makanan & Minuman',
      'amount': 1420000.0,
      'percentage': 38.9,
      'color': const Color(0xFFE07A5F),
    },
    {
      'name': 'Belanja & Kebutuhan',
      'amount': 950000.0,
      'percentage': 26.0,
      'color': const Color(0xFF3D5A80),
    },
    {
      'name': 'Transportasi & Bensin',
      'amount': 680000.0,
      'percentage': 18.6,
      'color': const Color(0xFF81B29A),
    },
    {
      'name': 'Tagihan & Utilitas',
      'amount': 450000.0,
      'percentage': 12.3,
      'color': const Color(0xFFF2CC8F),
    },
    {
      'name': 'Lainnya',
      'amount': 150000.0,
      'percentage': 4.2,
      'color': const Color(0xFF98A2B3),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Laporan Finansial',
          style: AppTypography.headlineMedium(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Insight Capsule Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accentDark.withOpacity(0.15)
                    : AppColors.accentSoft.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.accentDark.withOpacity(0.3) : AppColors.accentSoft,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insight Finansial Bulan Ini',
                          style: AppTypography.labelLarge(
                            color: isDark ? AppColors.accentDark : AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pengeluaran Anda lebih hemat 14% dari bulan lalu. Tabungan bersih bulan ini mencapai 57% dari total pendapatan.',
                          style: AppTypography.bodySmall(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Segment Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  _buildTab('Tren Arus Kas', 0),
                  _buildTab('Alokasi Kategori', 1),
                  _buildTab('Laba / Rugi', 2),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main Visual Chart Section
            if (_selectedTab == 0) _buildCashflowChart(isDark),
            if (_selectedTab == 1) _buildCategoryPieSection(isDark),
            if (_selectedTab == 2) _buildProfitLossSummary(isDark),

            const SizedBox(height: 24),

            // Category Breakdown Progress Bars
            Text(
              'Rincian Pengeluaran Terbesar',
              style: AppTypography.headlineMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categoryBreakdown.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final item = _categoryBreakdown[i];
                return GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: item['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item['name'],
                                style: AppTypography.bodyMedium(
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.format(item['amount']),
                            style: AppTypography.bodyMedium(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item['percentage'] as double) / 100,
                          backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurface : AppColors.lightBackground)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall(
              color: isSelected
                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashflowChart(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perbandingan 6 Bulan Terakhir',
            style: AppTypography.labelLarge(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const months = ['Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep'];
                        if (val.toInt() >= 0 && val.toInt() < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              months[val.toInt()],
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBarGroup(0, 6.2, 3.4),
                  _makeBarGroup(1, 7.0, 4.1),
                  _makeBarGroup(2, 6.8, 3.8),
                  _makeBarGroup(3, 7.5, 4.2),
                  _makeBarGroup(4, 8.0, 4.5),
                  _makeBarGroup(5, 8.5, 3.65),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(AppColors.positive, 'Pemasukan'),
              const SizedBox(width: 20),
              _buildLegend(AppColors.negative, 'Pengeluaran'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieSection(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: _categoryBreakdown.map((item) {
                  return PieChartSectionData(
                    color: item['color'] as Color,
                    value: item['percentage'] as double,
                    title: '${(item['percentage'] as double).toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: AppTypography.labelSmall(color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossSummary(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSummaryRow('Total Pendapatan', 18200000, AppColors.positive),
          const Divider(height: 24),
          _buildSummaryRow('Beban Operasional & HPP', 11400000, AppColors.negative),
          const Divider(height: 24),
          _buildSummaryRow('Laba Bersih (Net Profit)', 6800000, AppColors.accent, isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold ? AppTypography.bodyLarge(fontWeight: FontWeight.w600) : AppTypography.bodyMedium(),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: isBold
              ? AppTypography.headlineMedium(color: color)
              : AppTypography.bodyLarge(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  BarChartGroupData _makeBarGroup(int x, double income, double expense) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: income, color: AppColors.positive, width: 8, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: expense, color: AppColors.negative, width: 8, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: AppTypography.labelSmall()),
      ],
    );
  }
}
