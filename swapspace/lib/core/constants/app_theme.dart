import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

abstract class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryBlueDark,
        background: AppColors.background,
        surface: AppColors.surface,
        error: AppColors.errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headingSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 24,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: AppSpacing.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: AppTextStyles.bodyMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        titleMedium: AppTextStyles.labelLarge,
      ),
    );
  }
}
