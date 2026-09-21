import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/quick_action_button.dart';
import '../../spaces/presentation/space_switcher_header.dart';
import '../../transactions/presentation/add_transaction_modal.dart';
import '../data/dashboard_repository.dart';

class DashboardHomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToReports;
  final VoidCallback onNavigateToInvoices;
  final VoidCallback onNavigateToAccounts;
  final VoidCallback? onLogout;

  const DashboardHomeScreen({
    super.key,
    required this.onNavigateToReports,
    required this.onNavigateToInvoices,
    required this.onNavigateToAccounts,
    this.onLogout,
  });

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final _dashboardRepo = DashboardRepository(ApiClient());

  bool _isLoading = true;
  bool _isBalanceVisible = true;

  List<Map<String, dynamic>> _spaces = [];
  Map<String, dynamic>? _activeSpace;
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _transactions = [];

  double _totalBalance = 0;
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;

  String get _activeSpaceId => _activeSpace?['id']?.toString() ?? '';
  String get _activeSpaceName => _activeSpace?['name']?.toString() ?? 'Keuangan Pribadi';
  String get _activeSpaceType => _activeSpace?['type']?.toString() ?? 'personal';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final spaces = await _dashboardRepo.getSpaces();
      _spaces = spaces;

      if (_spaces.isNotEmpty) {
        if (_activeSpace == null || !_spaces.any((s) => s['id'] == _activeSpace!['id'])) {
          _activeSpace = _spaces.first;
        }
      }

      if (_activeSpace != null) {
        await _loadSpaceDetails(_activeSpaceId);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSpaceDetails(String spaceId) async {
    final accounts = await _dashboardRepo.getAccounts(spaceId);
    final categories = await _dashboardRepo.getCategories(spaceId);
    final transactions = await _dashboardRepo.getTransactions(spaceId);
    final summary = await _dashboardRepo.getSummary(spaceId);

    double totalBal = 0;
    for (var acc in accounts) {
      final bal = double.tryParse(acc['balance']?.toString() ?? '0') ?? 0;
      totalBal += bal;
    }

    if (mounted) {
      setState(() {
        _accounts = accounts;
        _categories = categories;
        _transactions = transactions;
        _totalBalance = totalBal;
        _monthlyIncome = double.tryParse(summary?['total_income']?.toString() ?? '0') ?? 0;
        _monthlyExpense = double.tryParse(summary?['total_expense']?.toString() ?? '0') ?? 0;
      });
    }
  }

  IconData _getCategoryIcon(String? iconName, String? type) {
    if (iconName != null) {
      switch (iconName) {
        case 'coffee':
        case 'restaurant':
          return Icons.restaurant_outlined;
        case 'briefcase':
        case 'work':
          return Icons.work_outline;
        case 'wallet':
          return Icons.account_balance_wallet_outlined;
        case 'trending-up':
          return Icons.trending_up_outlined;
        case 'shopping-bag':
          return Icons.shopping_bag_outlined;
        case 'navigation':
        case 'car':
          return Icons.directions_car_outlined;
        case 'file-text':
        case 'receipt':
          return Icons.receipt_long_outlined;
        case 'film':
          return Icons.movie_outlined;
        case 'activity':
          return Icons.medical_services_outlined;
      }
    }
    return type == 'income' ? Icons.arrow_downward_rounded : Icons.shopping_bag_outlined;
  }

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
            ..._spaces.map((sp) {
              final isCurrent = sp['id'] == _activeSpace?['id'];
              final isBus = sp['type'] == 'business';
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isBus
                        ? AppColors.businessSoft.withOpacity(0.4)
                        : AppColors.accentSoft.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBus ? Icons.storefront : Icons.person,
                    color: isBus ? AppColors.businessAccent : AppColors.accent,
                  ),
                ),
                title: Text(sp['name'] ?? '', style: AppTypography.bodyLarge()),
                subtitle: Text(isBus ? 'Ruang Bisnis UMKM' : 'Ruang Personal', style: AppTypography.bodySmall()),
                trailing: isCurrent
                    ? Icon(Icons.check_circle, color: isBus ? AppColors.businessAccent : AppColors.accent)
                    : null,
                onTap: () {
                  setState(() => _activeSpace = sp);
                  Navigator.pop(ctx);
                  _loadSpaceDetails(sp['id']);
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _openAddTransactionModal() {
    if (_activeSpaceId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionModal(
        spaceId: _activeSpaceId,
        spaceType: _activeSpaceType,
        accounts: _accounts,
        categories: _categories,
        onSave: (data) async {
          final amt = data['amount'] as double;
          final type = data['type'] as String;
          final note = data['note'] as String?;
          final date = data['date'] as String;
          final accountId = data['account_id'] as String?;
          final categoryId = data['category_id'] as String?;

          final success = await _dashboardRepo.createTransaction(
            spaceId: _activeSpaceId,
            accountId: accountId,
            categoryId: categoryId,
            amount: amt,
            type: type,
            note: note,
            transactionDate: date,
          );

          if (success) {
            _loadSpaceDetails(_activeSpaceId);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusiness = _activeSpaceType == 'business';

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: isBusiness ? AppColors.businessAccent : AppColors.accent,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                  onLogout: widget.onLogout,
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
                    if (_transactions.isNotEmpty)
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
                if (_transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada transaksi',
                          style: AppTypography.bodyMedium(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Klik tombol "Catat Transaksi" untuk mulai mencatat.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final txn = _transactions[i];
                      final isExpense = txn['type'] == 'expense';
                      final amt = double.tryParse(txn['amount']?.toString() ?? '0') ?? 0;
                      final catName = txn['category_name'] ?? txn['category'] ?? 'Umum';
                      final accName = txn['account_name'] ?? txn['account'] ?? 'Tunai';
                      final dateStr = txn['transaction_date'] ?? '';

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
                                _getCategoryIcon(txn['category_icon'], txn['type']),
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
                                    txn['note'] != null && (txn['note'] as String).isNotEmpty
                                        ? txn['note']
                                        : catName,
                                    style: AppTypography.bodyMedium(
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$accName • $dateStr',
                                    style: AppTypography.bodySmall(
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Amount
                            Text(
                              '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amt)}',
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
