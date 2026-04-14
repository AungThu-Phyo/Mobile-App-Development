import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class SessionStatusBadge extends StatelessWidget {
  final String status;
  const SessionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'open' => (AppColors.successGreenLight, AppColors.successGreen),
      'matched' => (AppColors.primaryBlueLight, AppColors.primaryBlue),
      'completed' => (AppColors.grey100, AppColors.grey600),
      'cancelled' => (AppColors.errorRedSoft, AppColors.errorRed),
      _ => (AppColors.grey100, AppColors.grey600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(color: fg),
      ),
    );
  }
}
