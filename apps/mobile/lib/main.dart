import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/dashboard/presentation/dashboard_home_screen.dart';
import 'features/reports/presentation/financial_report_screen.dart';
import 'features/invoices/presentation/invoice_management_screen.dart';
import 'features/accounts/presentation/accounts_overview_screen.dart';
import 'features/debts/presentation/debts_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CatatApp()));
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class CatatApp extends ConsumerWidget {
  const CatatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Catat - Manajemen Keuangan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isLoggedIn = true;

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: () => setState(() => _isLoggedIn = true),
        onNavigateToRegister: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterScreen(
                onRegisterSuccess: () {
                  Navigator.pop(context);
                  setState(() => _isLoggedIn = true);
                },
                onNavigateToLogin: () => Navigator.pop(context),
              ),
            ),
          );
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      DashboardHomeScreen(
        onNavigateToReports: () => setState(() => _currentIndex = 1),
        onNavigateToInvoices: () => setState(() => _currentIndex = 2),
        onNavigateToAccounts: () => setState(() => _currentIndex = 3),
      ),
      const FinancialReportScreen(),
      const InvoiceManagementScreen(),
      const AccountsOverviewScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          indicatorColor: isDark ? AppColors.accentDark.withOpacity(0.2) : AppColors.accentSoft,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.accent),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.accent),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.accent),
              label: 'Invoice',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent),
              label: 'Dompet',
            ),
          ],
        ),
      ),
    );
  }
}
