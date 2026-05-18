import 'package:flutter/material.dart';

/// Bảng màu ứng dụng - lấy cảm hứng từ Hasaki (tông màu xanh lá đậm)
class AppColors {
  AppColors._();

  // ── Primary Palette (Hasaki Green) ─────────────────────────
  static const Color primary = Color(0xFF1A6B3C);        // Xanh lá chủ đạo
  static const Color primaryDark = Color(0xFF0F4A28);    // Xanh đậm hơn
  static const Color primaryLight = Color(0xFF2E8B57);   // Xanh nhạt hơn
  static const Color primarySurface = Color(0xFFE8F5EE); // Nền xanh nhạt

  // ── Accent / Secondary ──────────────────────────────────────
  static const Color accent = Color(0xFF4CAF7D);         // Xanh mint
  static const Color accentGold = Color(0xFFFFB347);     // Vàng cam (thu nhập)
  static const Color accentRed = Color(0xFFE53935);      // Đỏ (chi tiêu)

  // ── Background ──────────────────────────────────────────────
  static const Color background = Color(0xFFF4F8F5);     // Nền trắng xanh nhẹ
  static const Color surface = Color(0xFFFFFFFF);        // Card / Dialog
  static const Color surfaceVariant = Color(0xFFEDF5F0); // Surface phụ

  // ── Text ────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C2D26);    // Chữ chính
  static const Color textSecondary = Color(0xFF5A7A65);  // Chữ phụ
  static const Color textHint = Color(0xFF9BB5A4);       // Placeholder
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // Chữ trên nền xanh

  // ── Status ──────────────────────────────────────────────────
  static const Color income = Color(0xFF2E8B57);         // Thu nhập (xanh)
  static const Color expense = Color(0xFFE53935);        // Chi tiêu (đỏ)
  static const Color warning = Color(0xFFFFA726);        // Cảnh báo
  static const Color info = Color(0xFF29B6F6);           // Thông tin

  // ── Chart Colors ────────────────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFF1A6B3C),
    Color(0xFF4CAF7D),
    Color(0xFFFFB347),
    Color(0xFF29B6F6),
    Color(0xFFE53935),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF7043),
  ];

  // ── Gradient ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A6B3C), Color(0xFF2E8B57)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A6B3C), Color(0xFF4CAF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF2E8B57), Color(0xFF4CAF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFEF9A9A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadow ──────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF1A6B3C).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}
