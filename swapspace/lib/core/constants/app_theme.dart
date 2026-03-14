import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

abstract class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(isDark: false);
  }

  static ThemeData get darkTheme {
    return _buildTheme(isDark: true);
  }

  static ThemeData _buildTheme({required bool isDark}) {
    final primary = isDark
        ? AppColors.darkPrimaryBlue
        : AppColors.lightPrimaryBlue;
    final primaryAccent = isDark
        ? AppColors.darkPrimaryBlueDark
        : AppColors.lightPrimaryBlueDark;
    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final card = isDark
        ? AppColors.darkCardBackground
        : AppColors.lightCardBackground;
    final border = isDark ? AppColors.darkGrey200 : AppColors.lightGrey200;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final buttonForeground = isDark ? AppColors.darkBackground : Colors.white;
    final error = isDark ? AppColors.darkErrorRed : AppColors.lightErrorRed;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: buttonForeground,
        secondary: primaryAccent,
        onSecondary: textPrimary,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: surface.withValues(alpha: isDark ? 0.96 : 0.9),
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.headingSmall.copyWith(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: buttonForeground,
          textStyle: AppTextStyles.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? card : surface,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        side: BorderSide(color: border),
        backgroundColor: isDark ? card : Colors.white,
        selectedColor: primary,
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        secondaryLabelStyle: AppTextStyles.bodyMedium.copyWith(
          color: buttonForeground,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: textSecondary),
        titleMedium: AppTextStyles.labelLarge.copyWith(color: textPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return isDark ? AppColors.darkGrey400 : AppColors.lightGrey400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.35);
          }
          return isDark ? AppColors.darkGrey200 : AppColors.lightGrey200;
        }),
      ),
    );
  }
}
