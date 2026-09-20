import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_card.dart';

class AccountsOverviewScreen extends StatelessWidget {
  const AccountsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accounts = [
      {
        'name': 'Uang Tunai (Cash)',
        'type': 'cash',
        'balance': 1850000.0,
        'icon': Icons.payments_outlined,
      },
      {
        'name': 'Rekening BCA Utama',
        'type': 'bank',
        'balance': 11500000.0,
        'icon': Icons.account_balance_outlined,
      },
      {
        'name': 'GoPay & OVO',
        'type': 'ewallet',
        'balance': 1500000.0,
        'icon': Icons.account_balance_wallet_outlined,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelola Dompet & Akun',
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
            Text(
              'Daftar Dompet Tersimpan',
              style: AppTypography.headlineMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: accounts.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final acc = accounts[i];
                return GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.accentDark.withOpacity(0.15) : AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          acc['icon'] as IconData,
                          color: isDark ? AppColors.accentDark : AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc['name'] as String,
                              style: AppTypography.bodyLarge(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saldo',
                              style: AppTypography.bodySmall(
                                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(acc['balance'] as double),
                        style: AppTypography.headlineMedium(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
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
        label: Text('Tambah Dompet', style: AppTypography.labelLarge(color: Colors.white)),
      ),
    );
  }
}
