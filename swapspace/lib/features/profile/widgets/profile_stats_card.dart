import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/user_model.dart';
import 'profile_stat_tile.dart';

class ProfileStatsCard extends StatelessWidget {
  final UserModel user;

  const ProfileStatsCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ProfileStatTile(
                    label: 'Rating',
                    value: user.rating.toStringAsFixed(1),
                    accent: AppColors.primaryBlue,
                    icon: Icons.star_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ProfileStatTile(
                    label: 'Sessions',
                    value: '${user.totalSessions}',
                    accent: AppColors.warningOrange,
                    icon: Icons.event_available_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i < user.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warningOrange,
                    size: 20,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${user.totalSessions} sessions completed',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
