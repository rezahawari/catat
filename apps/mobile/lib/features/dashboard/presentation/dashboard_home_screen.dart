import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/quick_action_button.dart';
import '../../spaces/presentation/space_switcher_header.dart';
import '../../transactions/presentation/add_transaction_modal.dart';

class DashboardHomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToReports;
  final VoidCallback onNavigateToInvoices;
  final VoidCallback onNavigateToAccounts;

  const DashboardHomeScreen({
    super.key,
    required this.onNavigateToReports,
    required this.onNavigateToInvoices,
    required this.onNavigateToAccounts,
  });

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  String _activeSpaceName = 'Keuangan Pribadi';
  String _activeSpaceType = 'personal'; // 'personal' or 'business'
  bool _isBalanceVisible = true;

  // Sample dynamic data (synced with state/Drift)
  double _totalBalance = 14850000;
  double _monthlyIncome = 8500000;
  double _monthlyExpense = 3650000;

  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Kopi & Snack Meeting',
      'category': 'Makanan & Minuman',
      'account': 'GoPay',
      'amount': 45000.0,
      'type': 'expense',
      'date': 'Hari ini, 14:30',
      'icon': Icons.coffee_outlined,
    },
    {
      'title': 'Gaji Proyek UI/UX Desain',
      'category': 'Freelance',
      'account': 'BCA Rekening',
      'amount': 3500000.0,
      'type': 'income',
      'date': 'Kemarin',
      'icon': Icons.laptop_chromebook_outlined,
    },
    {
      'title': 'Belanja Mingguan Supermarket',
      'category': 'Belanja',
      'account': 'Cash',
      'amount': 320000.0,
      'type': 'expense',
      'date': '14 Sep',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'title': 'Langganan Cloud & Software',
      'category': 'Tagihan',
      'account': 'BCA Rekening',
      'amount': 149000.0,
      'type': 'expense',
      'date': '12 Sep',
      'icon': Icons.receipt_long_outlined,
    },
  ];

  void _switchSpaceModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih Ruang Kerja',
              style: AppTypography.headlineMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.accent),
              ),
              title: Text('Keuangan Pribadi', style: AppTypography.bodyLarge()),
              subtitle: Text('1 Dompet • 14 Transaksi bulan ini', style: AppTypography.bodySmall()),
              trailing: _activeSpaceType == 'personal'
                  ? const Icon(Icons.check_circle, color: AppColors.accent)
                  : null,
              onTap: () {
                setState(() {
                  _activeSpaceName = 'Keuangan Pribadi';
                  _activeSpaceType = 'personal';
                  _totalBalance = 14850000;
                  _monthlyIncome = 8500000;
                  _monthlyExpense = 3650000;
                });
                Navigator.pop(ctx);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.businessSoft.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, color: AppColors.businessAccent),
              ),
              title: Text('Katering Dapur Sarah (Bisnis)', style: AppTypography.bodyLarge()),
              subtitle: Text('3 Invoice aktif • Laba Bersih Rp 4.2jt', style: AppTypography.bodySmall()),
              trailing: _activeSpaceType == 'business'
                  ? const Icon(Icons.check_circle, color: AppColors.businessAccent)
                  : null,
              onTap: () {
                setState(() {
                  _activeSpaceName = 'Dapur Sarah (Bisnis)';
                  _activeSpaceType = 'business';
                  _totalBalance = 24500000;
                  _monthlyIncome = 18200000;
                  _monthlyExpense = 11400000;
                });
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _openAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionModal(
        spaceId: 'current',
        spaceType: _activeSpaceType,
        onSave: (data) {
          setState(() {
            final amt = data['amount'] as double;
            final isExpense = data['type'] == 'expense';
            if (isExpense) {
              _totalBalance -= amt;
              _monthlyExpense += amt;
            } else {
              _totalBalance += amt;
              _monthlyIncome += amt;
            }
            _transactions.insert(0, {
              'title': data['category'],
              'category': data['category'],
              'account': data['account'],
              'amount': amt,
              'type': data['type'],
              'date': 'Baru saja',
              'icon': isExpense ? Icons.shopping_bag_outlined : Icons.add_circle_outline,
            });
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusiness = _activeSpaceType == 'business';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Switcher
              SpaceSwitcherHeader(
                activeSpaceName: _activeSpaceName,
                activeSpaceType: _activeSpaceType,
                onSwitchSpace: _switchSpaceModal,
                onOpenNotifications: () {},
              ),
              const SizedBox(height: 20),

              // Hero Net Worth / Cash Balance Card
              GlassCard(
                hasGlow: true,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBusiness ? 'TOTAL SALDO USAHA' : 'TOTAL SALDO TERSEDIA',
                          style: AppTypography.labelSmall(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _isBalanceVisible = !_isBalanceVisible);
                          },
                          child: Icon(
                            _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isBalanceVisible ? CurrencyFormatter.format(_totalBalance) : '••••••••',
                      style: AppTypography.displayLarge(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Income vs Expense row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.positive.withOpacity(0.12)
                                  : AppColors.positiveSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_downward_rounded,
                                        size: 14, color: AppColors.positive),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pemasukan',
                                      style: AppTypography.labelSmall(color: AppColors.positive),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(_monthlyIncome),
                                  style: AppTypography.bodyMedium(
                                    color: AppColors.positive,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.negative.withOpacity(0.12)
                                  : AppColors.negativeSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_upward_rounded,
                                        size: 14, color: AppColors.negative),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pengeluaran',
                                      style: AppTypography.labelSmall(color: AppColors.negative),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(_monthlyExpense),
                                  style: AppTypography.bodyMedium(
                                    color: AppColors.negative,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Aksi Cepat',
                style: AppTypography.headlineMedium(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickActionButton(
                    icon: Icons.add_rounded,
                    label: 'Catat\nTransaksi',
                    onTap: _openAddTransactionModal,
                  ),
                  QuickActionButton(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Kelola\nDompet',
                    onTap: widget.onNavigateToAccounts,
                  ),
                  QuickActionButton(
                    icon: isBusiness ? Icons.receipt_outlined : Icons.pie_chart_outline_rounded,
                    label: isBusiness ? 'Invoice\nBisnis' : 'Anggaran\n& Goals',
                    onTap: isBusiness ? widget.onNavigateToInvoices : widget.onNavigateToReports,
                  ),
                  QuickActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Laporan\nKeuangan',
                    onTap: widget.onNavigateToReports,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Recent Transactions Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Terbaru',
                    style: AppTypography.headlineMedium(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Lihat Semua',
                      style: AppTypography.labelLarge(
                        color: isDark ? AppColors.accentDark : AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Transactions Feed
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final txn = _transactions[i];
                  final isExpense = txn['type'] == 'expense';
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Category Icon Circle
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isExpense
                                ? (isDark ? AppColors.negative.withOpacity(0.15) : AppColors.negativeSoft)
                                : (isDark ? AppColors.positive.withOpacity(0.15) : AppColors.positiveSoft),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            txn['icon'] as IconData,
                            size: 22,
                            color: isExpense ? AppColors.negative : AppColors.positive,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Account
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                txn['title'],
                                style: AppTypography.bodyMedium(
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${txn['account']} • ${txn['date']}',
                                style: AppTypography.bodySmall(
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Amount
                        Text(
                          '${isExpense ? '-' : '+'}${CurrencyFormatter.format(txn['amount'])}',
                          style: AppTypography.bodyLarge(
                            color: isExpense ? AppColors.negative : AppColors.positive,
                            fontWeight: FontWeight.w600,
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransactionModal,
        backgroundColor: isBusiness ? AppColors.businessAccent : AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Catat', style: AppTypography.labelLarge(color: Colors.white)),
      ),
    );
  }
}
