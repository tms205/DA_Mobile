import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.about)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.cardGradientDark : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.dynamicElevatedShadow(isDark),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
                width: 1.5,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 44),
                SizedBox(height: 16),
                Text(
                  AppStrings.appName,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  AppStrings.appSubtitle,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(context, 'Mục tiêu', [
            'Ghi chép thu chi hằng ngày một cách rõ ràng.',
            'Theo dõi ngân sách theo từng danh mục.',
            'Phân tích tài chính cá nhân bằng báo cáo và biểu đồ.',
            'Quản lý nhiều tài khoản/ví trên cùng một ứng dụng.',
          ]),
          const SizedBox(height: 12),
          _section(context, 'Tính năng nổi bật', [
            'Giao dịch thu nhập, chi tiêu, chuyển khoản.',
            'Danh mục tùy chỉnh và danh mục mặc định.',
            'Ngân sách, cảnh báo vượt hạn mức.',
            'Đổi đơn vị tiền tệ theo tỷ giá.',
            'Sao lưu cục bộ và bảo mật bằng mã PIN.',
          ]),
          const SizedBox(height: 12),
          _section(context, 'Thông tin phiên bản', [
            'Phiên bản: 1.0.0',
            'Nhóm thực hiện: Nhóm 9 - Lập trình Di động',
            'Nền tảng: Flutter, Provider, Local JSON Storage',
          ]),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<String> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final textSec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.dynamicCardShadow(isDark),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: TextStyle(color: textSec)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
