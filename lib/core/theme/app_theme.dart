import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.expense,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: _buildTextTheme(base.textTheme, AppColors.textPrimary, AppColors.textSecondary),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense, width: 1),
        ),
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: _buttonTheme(AppColors.primary, AppColors.textOnPrimary),
      outlinedButtonTheme: _outlinedTheme(AppColors.primary),
      textButtonTheme: _textButtonTheme(AppColors.primary),
      floatingActionButtonTheme: _fabTheme(AppColors.primary, AppColors.textOnPrimary),
      bottomNavigationBarTheme: _bottomNavTheme(AppColors.surface, AppColors.primary, AppColors.textHint),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
      chipTheme: _chipTheme(AppColors.surfaceVariant, AppColors.primarySurface, AppColors.textPrimary),
      dialogTheme: _dialogTheme(AppColors.surface),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.textPrimary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: LightweightPageTransitionsBuilder(),
          TargetPlatform.iOS: LightweightPageTransitionsBuilder(),
          TargetPlatform.macOS: LightweightPageTransitionsBuilder(),
          TargetPlatform.windows: LightweightPageTransitionsBuilder(),
          TargetPlatform.linux: LightweightPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.accent,
        secondary: AppColors.primaryLight,
        surface: AppColors.surfaceDark,
        error: AppColors.expense,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      ),
      textTheme: _buildTextTheme(base.textTheme, AppColors.textPrimaryDark, AppColors.textSecondaryDark),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense, width: 1),
        ),
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHintDark),
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
      ),
      elevatedButtonTheme: _buttonTheme(AppColors.accent, Colors.white),
      outlinedButtonTheme: _outlinedTheme(AppColors.accent),
      textButtonTheme: _textButtonTheme(AppColors.accent),
      floatingActionButtonTheme: _fabTheme(AppColors.accent, Colors.white),
      bottomNavigationBarTheme: _bottomNavTheme(AppColors.surfaceDark, AppColors.accent, AppColors.textHintDark),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      chipTheme: _chipTheme(AppColors.surfaceVariantDark, AppColors.primarySurfaceDark, AppColors.textPrimaryDark),
      dialogTheme: _dialogTheme(AppColors.surfaceDark),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surfaceVariantDark,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: LightweightPageTransitionsBuilder(),
          TargetPlatform.iOS: LightweightPageTransitionsBuilder(),
          TargetPlatform.macOS: LightweightPageTransitionsBuilder(),
          TargetPlatform.windows: LightweightPageTransitionsBuilder(),
          TargetPlatform.linux: LightweightPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Helper theme builders for keeping the code clean and short
  static ElevatedButtonThemeData _buttonTheme(Color bg, Color fg) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedTheme(Color color) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(Color color) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static FloatingActionButtonThemeData _fabTheme(Color bg, Color fg) {
    return FloatingActionButtonThemeData(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 3,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static BottomNavigationBarThemeData _bottomNavTheme(Color bg, Color selected, Color unselected) {
    return BottomNavigationBarThemeData(
      backgroundColor: bg,
      selectedItemColor: selected,
      unselectedItemColor: unselected,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    );
  }

  static ChipThemeData _chipTheme(Color bg, Color selectedBg, Color textColor) {
    return ChipThemeData(
      backgroundColor: bg,
      selectedColor: selectedBg,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  static DialogThemeData _dialogTheme(Color bg) {
    return DialogThemeData(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color textColor, Color secondaryColor) {
    return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.w800,
        fontSize: 32,
        color: textColor,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.displayMedium,
        fontWeight: FontWeight.w700,
        fontSize: 26,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineLarge,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: textColor,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: textColor,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.titleMedium,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.bodyLarge,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.bodyMedium,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: secondaryColor,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        textStyle: base.bodySmall,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: secondaryColor.withValues(alpha: 0.7),
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.labelLarge,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: textColor,
      ),
    );
  }
}

class LightweightPageTransitionsBuilder extends PageTransitionsBuilder {
  const LightweightPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}
