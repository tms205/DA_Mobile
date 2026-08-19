import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/theme_provider.dart';
import '../categories/categories_screen.dart';
import '../security/pin_lock_screen.dart';
import 'about_screen.dart';
import 'currency_settings_screen.dart';
import 'local_backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _notificationsKey = 'settings_notifications_enabled';

  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildSection('Tài khoản', [
            _buildTile(
              context,
              Icons.category_outlined,
              AppStrings.categories,
              'Quản lý danh mục thu/chi',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
            _buildTile(
              context,
              Icons.currency_exchange,
              AppStrings.currency,
              'Đổi tiền tệ và cập nhật tỷ giá',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CurrencySettingsScreen(),
                ),
              ),
            ),
            _buildThemeSelector(context),
          ]),
          const SizedBox(height: 18),
          _buildSection('Thông báo', [
            _buildSwitchTile(
              context,
              Icons.notifications_outlined,
              AppStrings.notifications,
              'Nhận thông báo ngân sách và nhắc nhở',
            ),
          ]),
          const SizedBox(height: 18),
          _buildSection('Nâng cao', [
            _buildTile(
              context,
              Icons.backup_outlined,
              AppStrings.localBackup,
              'Sao lưu và khôi phục dữ liệu trên thiết bị',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocalBackupScreen()),
              ),
            ),
            _buildTile(
              context,
              Icons.security_outlined,
              AppStrings.security,
              'Đặt mã PIN bảo vệ ứng dụng',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PinSettingsScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          _buildSection('Thông tin', [
            _buildTile(
              context,
              Icons.info_outline_rounded,
              AppStrings.about,
              'Ứng dụng Quản lý Chi tiêu - Nhóm 9',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
            _buildTile(
              context,
              Icons.update_rounded,
              AppStrings.version,
              'v1.0.0',
              null,
            ),
          ]),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.cardGradientDark : AppColors.cardGradient;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.dynamicElevatedShadow(isDark),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
          width: 1.5,
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Người dùng cục bộ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Dữ liệu được lưu an toàn trên thiết bị này',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_user_rounded, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final titleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: titleColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.dynamicCardShadow(isDark),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                ...items.asMap().entries.map(
                  (entry) => Column(
                    children: [
                      entry.value,
                      if (entry.key < items.length - 1)
                        Divider(height: 1, indent: 56, color: dividerColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTileContainer({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.accent : AppColors.primary;
    final iconBg = isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface;
    final textPri = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textHintColor = isDark ? AppColors.textHintDark : AppColors.textHint;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPri),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: textHintColor, fontWeight: FontWeight.w500),
      ),
      trailing: trailing,
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textHintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    return _buildTileContainer(
      context: context,
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: onTap != null
          ? Icon(Icons.chevron_right_rounded, color: textHintColor)
          : null,
    );
  }

  Widget _buildSwitchTile(BuildContext context, IconData icon, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.accent : AppColors.primary;
    return _buildTileContainer(
      context: context,
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => _saveNotificationsEnabled(!_notificationsEnabled),
      trailing: Switch(
        value: _notificationsEnabled,
        activeTrackColor: iconColor,
        onChanged: _saveNotificationsEnabled,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    String themeName = 'Theo hệ thống';
    if (themeProvider.themeMode == ThemeMode.light) themeName = 'Chế độ sáng';
    if (themeProvider.themeMode == ThemeMode.dark) themeName = 'Chế độ tối';

    return _buildTile(
      context,
      Icons.dark_mode_outlined,
      'Giao diện ứng dụng',
      'Đang sử dụng: $themeName',
      () => _showThemeDialog(context),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBg,
          title: const Text('Chọn giao diện', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Chế độ sáng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                activeColor: isDark ? AppColors.accent : AppColors.primary,
                onChanged: (val) {
                  if (val != null) themeProvider.setThemeMode(val);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Chế độ tối', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                activeColor: isDark ? AppColors.accent : AppColors.primary,
                onChanged: (val) {
                  if (val != null) themeProvider.setThemeMode(val);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Theo hệ thống', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                activeColor: isDark ? AppColors.accent : AppColors.primary,
                onChanged: (val) {
                  if (val != null) themeProvider.setThemeMode(val);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    });
  }

  Future<void> _saveNotificationsEnabled(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }
}
