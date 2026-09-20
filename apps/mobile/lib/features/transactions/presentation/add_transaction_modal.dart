import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/amount_keypad_sheet.dart';

class AddTransactionModal extends StatefulWidget {
  final String spaceId;
  final String spaceType; // 'personal' or 'business'
  final Function(Map<String, dynamic> transactionData) onSave;

  const AddTransactionModal({
    super.key,
    required this.spaceId,
    required this.spaceType,
    required this.onSave,
  });

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  String _type = 'expense'; // 'expense' or 'income'
  double _amount = 0;
  String? _selectedCategory;
  String _selectedAccount = 'Uang Tunai (Cash)';
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Categories list
  List<Map<String, dynamic>> get _categories {
    if (widget.spaceType == 'business') {
      return _type == 'expense'
          ? [
              {'name': 'Bahan Baku', 'icon': Icons.inventory_2_outlined},
              {'name': 'Operasional', 'icon': Icons.build_circle_outlined},
              {'name': 'Gaji Pegawai', 'icon': Icons.people_outline},
              {'name': 'Sewa Tempat', 'icon': Icons.storefront_outlined},
              {'name': 'Iklan/Ads', 'icon': Icons.campaign_outlined},
              {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded},
            ]
          : [
              {'name': 'Penjualan Produk', 'icon': Icons.shopping_bag_outlined},
              {'name': 'Jasa / Fee', 'icon': Icons.work_outline},
              {'name': 'Modal Usaha', 'icon': Icons.account_balance_outlined},
              {'name': 'Lainnya', 'icon': Icons.add_circle_outline},
            ];
    }

    return _type == 'expense'
        ? [
            {'name': 'Makanan & Minuman', 'icon': Icons.restaurant_outlined},
            {'name': 'Transportasi', 'icon': Icons.directions_car_outlined},
            {'name': 'Belanja', 'icon': Icons.shopping_bag_outlined},
            {'name': 'Tagihan', 'icon': Icons.receipt_long_outlined},
            {'name': 'Hiburan', 'icon': Icons.movie_outlined},
            {'name': 'Kesehatan', 'icon': Icons.medical_services_outlined},
            {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded},
          ]
        : [
            {'name': 'Gaji Bulanan', 'icon': Icons.account_balance_wallet_outlined},
            {'name': 'Freelance', 'icon': Icons.laptop_chromebook_outlined},
            {'name': 'Investasi', 'icon': Icons.trending_up_outlined},
            {'name': 'Lainnya', 'icon': Icons.add_circle_outline},
          ];
  }

  void _openKeypad() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AmountKeypadSheet(
        initialAmount: _amount,
        onAmountConfirmed: (val) {
          setState(() {
            _amount = val;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
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
            const SizedBox(height: 16),

            // Segmented Switch (Pengeluaran vs Pemasukan)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      label: 'Pengeluaran',
                      isActive: _type == 'expense',
                      activeColor: AppColors.negative,
                      onTap: () {
                        setState(() {
                          _type = 'expense';
                          _selectedCategory = null;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildTypeButton(
                      label: 'Pemasukan',
                      isActive: _type == 'income',
                      activeColor: AppColors.positive,
                      onTap: () {
                        setState(() {
                          _type = 'income';
                          _selectedCategory = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount Input Trigger
            InkWell(
              onTap: _openKeypad,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _amount > 0
                        ? (_type == 'expense' ? AppColors.negative : AppColors.positive)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nominal',
                          style: AppTypography.labelSmall(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _amount > 0 ? CurrencyFormatter.format(_amount) : 'Rp 0',
                          style: AppTypography.headlineLarge(
                            color: _amount > 0
                                ? (_type == 'expense' ? AppColors.negative : AppColors.positive)
                                : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.edit_outlined,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Selector Chips
            Text(
              'Kategori',
              style: AppTypography.labelLarge(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat['name'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.accentDark.withOpacity(0.2) : AppColors.accentSoft)
                          : (isDark ? AppColors.darkCard : AppColors.lightBackground),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppColors.accentDark : AppColors.accent)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'],
                          size: 16,
                          color: isSelected
                              ? (isDark ? AppColors.accentDark : AppColors.accent)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat['name'],
                          style: AppTypography.labelSmall(
                            color: isSelected
                                ? (isDark ? AppColors.accentDark : AppColors.accent)
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Account & Note Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedAccount,
                            style: AppTypography.bodySmall(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          CurrencyFormatter.formatDate(_selectedDate),
                          style: AppTypography.bodySmall(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Note TextField
            TextField(
              controller: _noteController,
              style: AppTypography.bodyMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Catatan tambahan (opsional)...',
                hintStyle: AppTypography.bodySmall(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
                prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _amount > 0 && _selectedCategory != null
                    ? () {
                        widget.onSave({
                          'type': _type,
                          'amount': _amount,
                          'category': _selectedCategory,
                          'account': _selectedAccount,
                          'note': _noteController.text.trim(),
                          'date': _selectedDate.toIso8601String().substring(0, 10),
                        });
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == 'expense' ? AppColors.negative : AppColors.positive,
                ),
                child: Text(
                  'Simpan Transaksi',
                  style: AppTypography.labelLarge(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelLarge(
            color: isActive
                ? Colors.white
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
