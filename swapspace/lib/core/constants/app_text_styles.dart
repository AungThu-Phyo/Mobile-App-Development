import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  // Headings
  static const TextStyle headingLarge = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const TextStyle headingMedium = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle headingSmall = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  // Body
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary);

  // Labels
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle labelSmall = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5);

  // Button
  static const TextStyle buttonText = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white);

  // Caption
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary);
  static const TextStyle captionSmall = TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.textHint);
}
