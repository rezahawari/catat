import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_card.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  String _selectedType = 'receivable'; // 'receivable' (Piutang) or 'payable' (Utang)

  final List<Map<String, dynamic>> _records = [
    {
      'counterparty': 'Pak Budi (Supplier)',
      'type': 'payable',
      'amount': 1500000.0,
      'dueDate': '25 Sep 2026',
      'status': 'unpaid',
    },
    {
      'counterparty': 'Klien Sarah Bakery',
      'type': 'receivable',
      'amount': 3200000.0,
      'dueDate': '18 Sep 2026',
      'status': 'unpaid',
    },
    {
      'counterparty': 'CV Mitra Grafika',
      'type': 'receivable',
      'amount': 850000.0,
      'dueDate': '12 Sep 2026',
      'status': 'paid',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _records.where((r) => r['type'] == _selectedType).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Utang & Piutang',
          style: AppTypography.headlineMedium(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Segment Switch
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton('Piutang Saya (Uang Masuk)', 'receivable', isDark),
                  ),
                  Expanded(
                    child: _buildSegmentButton('Utang Saya (Harus Bayar)', 'payable', isDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final item = filtered[i];
                final isPaid = item['status'] == 'paid';

                return GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['counterparty'],
                            style: AppTypography.bodyLarge(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jatuh tempo: ${item['dueDate']}',
                            style: AppTypography.bodySmall(
                              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(item['amount']),
                            style: AppTypography.bodyLarge(
                              color: isPaid
                                  ? (isDark ? AppColors.textMutedDark : AppColors.textMuted)
                                  : (_selectedType == 'receivable' ? AppColors.positive : AppColors.negative),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? (isDark ? AppColors.positive.withOpacity(0.2) : AppColors.positiveSoft)
                                  : (isDark ? AppColors.warning.withOpacity(0.2) : AppColors.warningSoft),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isPaid ? 'Lunas' : 'Belum Lunas',
                              style: AppTypography.labelSmall(
                                color: isPaid ? AppColors.positive : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Catat Baru', style: AppTypography.labelLarge(color: Colors.white)),
      ),
    );
  }

  Widget _buildSegmentButton(String label, String value, bool isDark) {
    final isSelected = _selectedType == value;
    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : AppColors.lightBackground)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall(
            color: isSelected
                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
