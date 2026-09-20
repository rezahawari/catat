import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_card.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  String _selectedStatus = 'all';

  final List<Map<String, dynamic>> _invoices = [
    {
      'number': 'INV-2026-001',
      'client': 'PT Nusantara Digital',
      'dueDate': '20 Sep 2026',
      'amount': 4500000.0,
      'status': 'sent',
    },
    {
      'number': 'INV-2026-002',
      'client': 'Studio Desain Mahakarya',
      'dueDate': '15 Sep 2026',
      'amount': 2800000.0,
      'status': 'paid',
    },
    {
      'number': 'INV-2026-003',
      'client': 'Kafe Kopi Kenangan Kita',
      'dueDate': '10 Sep 2026',
      'amount': 1250000.0,
      'status': 'overdue',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoice Bisnis',
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
            // Status Chips Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua', 'all', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Terkirim', 'sent', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Lunas', 'paid', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Jatuh Tempo', 'overdue', isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Invoices List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _invoices.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final inv = _invoices[i];
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            inv['number'],
                            style: AppTypography.labelLarge(
                              color: isDark ? AppColors.accentDark : AppColors.accent,
                            ),
                          ),
                          _buildStatusBadge(inv['status'], isDark),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        inv['client'],
                        style: AppTypography.bodyLarge(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jatuh tempo: ${inv['dueDate']}',
                            style: AppTypography.bodySmall(
                              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(inv['amount']),
                            style: AppTypography.bodyLarge(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
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
        backgroundColor: AppColors.businessAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Buat Invoice', style: AppTypography.labelLarge(color: Colors.white)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStatus = value);
      },
      selectedColor: isDark ? AppColors.accentDark : AppColors.accent,
      labelStyle: AppTypography.labelSmall(
        color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color color;
    Color bg;
    String label;

    switch (status) {
      case 'paid':
        color = AppColors.positive;
        bg = isDark ? AppColors.positive.withOpacity(0.2) : AppColors.positiveSoft;
        label = 'Lunas';
        break;
      case 'sent':
        color = AppColors.info;
        bg = isDark ? AppColors.info.withOpacity(0.2) : AppColors.infoSoft;
        label = 'Terkirim';
        break;
      case 'overdue':
        color = AppColors.negative;
        bg = isDark ? AppColors.negative.withOpacity(0.2) : AppColors.negativeSoft;
        label = 'Jatuh Tempo';
        break;
      default:
        color = AppColors.textSecondary;
        bg = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        label = 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTypography.labelSmall(color: color)),
    );
  }
}
