import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../home/home_screen.dart';
import '../transactions/transaction_list_screen.dart';
import '../budget/budget_screen.dart';
import '../reports/reports_screen.dart';
import '../accounts/accounts_screen.dart';
import '../onboarding/onboarding_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<bool> _visitedTabs = [true, false, false, false, false];
  bool _isOnboardingChecking = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    if (!completed) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _isOnboardingChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnboardingChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _visitedTabs.length,
          (index) => _visitedTabs[index]
              ? _buildScreen(index)
              : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _selectTab(int index) {
    if (index < 0 || index > 4) return;
    setState(() {
      _visitedTabs[index] = true;
      _currentIndex = index;
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(onNavigateToTab: _selectTab);
      case 1:
        return const TransactionListScreen();
      case 2:
        return const BudgetScreen();
      case 3:
        return const ReportsScreen();
      case 4:
        return const AccountsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.accent : AppColors.primary;
    final inactiveColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return SafeArea(
      bottom: true,
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.dynamicCardShadow(isDark),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, AppStrings.navHome, activeColor, inactiveColor),
              _buildNavItem(1, Icons.receipt_long_outlined, Icons.receipt_long_rounded, AppStrings.navTransactions, activeColor, inactiveColor),
              _buildNavItem(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, AppStrings.navBudget, activeColor, inactiveColor),
              _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart_rounded, AppStrings.navReports, activeColor, inactiveColor),
              _buildNavItem(4, Icons.credit_card_outlined, Icons.credit_card_rounded, AppStrings.navAccounts, activeColor, inactiveColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
