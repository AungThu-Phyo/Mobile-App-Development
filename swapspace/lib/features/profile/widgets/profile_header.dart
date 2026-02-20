import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primaryBlueLight,
            backgroundImage: user.avatarUrl.isNotEmpty
                ? NetworkImage(user.avatarUrl)
                : null,
            child: user.avatarUrl.isEmpty
                ? Text(
                    user.name.isNotEmpty ? user.name[0] : '?',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(user.name, style: AppTextStyles.headingMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            user.email,
            style: AppTextStyles.caption.copyWith(color: AppColors.primaryBlue),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Active since ${user.activeSince}',
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}