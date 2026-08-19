import 'package:flutter/material.dart';

/// Bảng màu ứng dụng - hỗ trợ Light và Dark Mode lấy cảm hứng từ Hasaki (Emerald/Forest Green)
class AppColors {
  AppColors._();

  // ── Adaptive Helpers (tự chọn Light / Dark) ─────────────────
  static Color bg(bool d) => d ? backgroundDark : background;
  static Color sf(bool d) => d ? surfaceDark : surface;
  static Color sfVariant(bool d) => d ? surfaceVariantDark : surfaceVariant;
  static Color txt(bool d) => d ? textPrimaryDark : textPrimary;
  static Color txtSec(bool d) => d ? textSecondaryDark : textSecondary;
  static Color hint(bool d) => d ? textHintDark : textHint;
  static Color brd(bool d) => d ? borderDark : borderLight;
  static Color dvd(bool d) => d ? dividerDark : dividerLight;
  static Color pSf(bool d) => d ? primarySurfaceDark : primarySurface;
  static Color pc(bool d) => d ? accent : primary;

  // ── Primary Palette (Premium Blue) ─────────────────────────
  static const Color primary = Color(0xFF1A73E8);        // Xanh dương chủ đạo
  static const Color primaryDark = Color(0xFF0D47A1);    // Xanh đậm
  static const Color primaryLight = Color(0xFF4285F4);   // Xanh dương sáng
  static const Color primarySurface = Color(0xFFE8F0FE); // Nền xanh nhạt (Light)
  static const Color primarySurfaceDark = Color(0xFF0D253F); // Nền xanh nhạt (Dark)

  // ── Accent / Secondary ──────────────────────────────────────
  static const Color accent = Color(0xFF00B0FF);         // Xanh da trời (accent)
  static const Color accentGold = Color(0xFFFF9E22);     // Vàng cam ấm
  static const Color accentRed = Color(0xFFE53935);      // Đỏ chi tiêu

  // ── Light Theme Background & Surface ────────────────────────
  static const Color background = Color(0xFFF4F7FB);     // Nền sáng cool blue nhẹ
  static const Color surface = Color(0xFFFFFFFF);        // Card / Dialog sáng
  static const Color surfaceVariant = Color(0xFFE8F0FE); // Container phụ sáng

  // ── Dark Theme Background & Surface ─────────────────────────
  static const Color backgroundDark = Color(0xFF0B0F19);     // Nền tối midnight blue
  static const Color surfaceDark = Color(0xFF151D30);        // Card / Dialog tối blue-gray
  static const Color surfaceVariantDark = Color(0xFF1E293B); // Container phụ tối slate

  // ── Light Theme Text ────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);    // Chữ chính sáng
  static const Color textSecondary = Color(0xFF475569);  // Chữ phụ sáng
  static const Color textHint = Color(0xFF94A3B8);       // Placeholder sáng
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // Chữ trên nền xanh

  // ── Dark Theme Text ─────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF8FAFC);  // Chữ chính tối
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Chữ phụ tối
  static const Color textHintDark = Color(0xFF64748B);      // Placeholder tối

  // ── Borders & Dividers ─────────────────────────────────────
  static const Color borderLight = Color(0xFFE2E8F0);     // Viền sáng
  static const Color borderDark = Color(0xFF1E293B);      // Viền tối
  static const Color dividerLight = Color(0xFFEDF2F7);    // Phân cách sáng
  static const Color dividerDark = Color(0xFF1E293B);     // Phân cách tối

  // ── Status Colors ───────────────────────────────────────────
  static const Color income = Color(0xFF2E8B57);         // Thu nhập (xanh)
  static const Color expense = Color(0xFFE53935);        // Chi tiêu (đỏ)
  static const Color warning = Color(0xFFFFA726);        // Cảnh báo
  static const Color info = Color(0xFF29B6F6);           // Thông tin

  // ── Chart Colors ────────────────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFF1A73E8),
    Color(0xFF00B0FF),
    Color(0xFFFF9E22),
    Color(0xFF29B6F6),
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFFF7043),
  ];

  // ── Gradients ───────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF092A54), Color(0xFF0F4C81)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF2E8B57), Color(0xFF3CA86D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFEF9A9A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ──────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1A73E8).withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> dynamicCardShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
    }
    return cardShadow;
  }

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> dynamicElevatedShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
    }
    return elevatedShadow;
  }
}
