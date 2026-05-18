import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
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
          ]),
          const SizedBox(height: 16),
          _buildSection('Thông báo', [
            _buildSwitchTile(
              Icons.notifications_outlined,
              AppStrings.notifications,
              'Nhận thông báo ngân sách và nhắc nhở',
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('Nâng cao', [
            _buildTile(
              context,
              Icons.backup,
              AppStrings.localBackup,
              'Sao lưu và khôi phục dữ liệu trên thiết bị',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocalBackupScreen()),
              ),
            ),
            _buildTile(
              context,
              Icons.security,
              AppStrings.security,
              'Đặt mã PIN bảo vệ ứng dụng',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PinSettingsScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('Thông tin', [
            _buildTile(
              context,
              Icons.info_outline,
              AppStrings.about,
              'Ứng dụng Quản lý Chi tiêu - Nhóm 9',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
            _buildTile(
              context,
              Icons.update,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 36),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Dữ liệu được lưu trên thiết bị và có thể sao lưu cục bộ',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.phone_android_rounded, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              ...items.asMap().entries.map(
                (entry) => Column(
                  children: [
                    entry.value,
                    if (entry.key < items.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.textHint)
          : null,
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String subtitle) {
    return SwitchListTile(
      secondary: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
      ),
      value: _notificationsEnabled,
      activeThumbColor: AppColors.primary,
      onChanged: _saveNotificationsEnabled,
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
