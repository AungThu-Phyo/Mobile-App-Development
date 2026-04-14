import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/session_model.dart';

class ProfileSessionRow extends StatelessWidget {
  final SessionModel session;
  final bool isCreator;

  const ProfileSessionRow({
    super.key,
    required this.session,
    required this.isCreator,
  });

  IconData _activityIcon(String type) {
    return switch (type.toLowerCase()) {
      'study' => Icons.menu_book,
      'gym' => Icons.fitness_center,
      'football' => Icons.sports_soccer,
      'walking' => Icons.directions_walk,
      _ => Icons.group,
    };
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeBg, badgeText) = switch (session.status) {
      'open' => (AppColors.successGreen, AppColors.successGreenLight, 'OPEN'),
      'matched' => (
        AppColors.primaryBlue,
        AppColors.primaryBlueLight,
        'MATCHED',
      ),
      'completed' => (AppColors.grey600, AppColors.grey100, 'DONE'),
      'cancelled' => (AppColors.errorRed, AppColors.errorRedSoft, 'CANCELLED'),
      _ => (AppColors.grey600, AppColors.grey100, session.status.toUpperCase()),
    };

    final now = DateTime.now();
    final cutoff = session.date.subtract(const Duration(hours: 1));
    final isFinished =
        session.status == 'completed' || session.status == 'cancelled';
    final canEdit = isCreator && !isFinished && now.isBefore(cutoff);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(RouteNames.sessionDetail, extra: session),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlueLight,
                ),
                child: Icon(
                  _activityIcon(session.activityType),
                  size: 20,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title, style: AppTextStyles.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_formatDate(session.date)} · ${session.location}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 34,
                    child: canEdit
                        ? OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              side: BorderSide(color: AppColors.primaryBlue),
                            ),
                            onPressed: () => context.push(
                              RouteNames.editSession,
                              extra: session,
                            ),
                            child: const Text('Edit'),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
