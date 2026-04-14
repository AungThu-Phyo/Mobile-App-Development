import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/user_model.dart';
import 'profile_info_row.dart';

class ProfileDetailsCard extends StatelessWidget {
  final UserModel user;

  const ProfileDetailsCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Details', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            if (user.bio.isNotEmpty) ...[
              Text(
                'About',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(user.bio, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.md),
            ],
            if (user.faculty.isNotEmpty)
              ProfileInfoRow(
                icon: Icons.school_rounded,
                label: 'Faculty',
                value: user.faculty,
              ),
            ProfileInfoRow(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Interaction',
              value:
                  user.interactionPreference[0].toUpperCase() +
                  user.interactionPreference.substring(1),
            ),
            if (user.activityPreferences.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Activities',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: user.activityPreferences.map<Widget>((activity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      activity[0].toUpperCase() + activity.substring(1),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
