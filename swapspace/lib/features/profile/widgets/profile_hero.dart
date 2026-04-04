import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/user_model.dart';
import 'profile_header.dart';

class ProfileHero extends StatelessWidget {
  final UserModel user;

  const ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradientCoolToWarm,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your account',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryBlueDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProfileHeader(user: user),
        ],
      ),
    );
  }
}
