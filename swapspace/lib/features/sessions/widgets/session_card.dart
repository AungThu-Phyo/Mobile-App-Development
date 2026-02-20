import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/activity_session.dart';

class SessionCard extends StatelessWidget {
  final ActivitySession session;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(session.title, style: AppTextStyles.headingSmall),
                  ),
                  _StatusTag(label: session.interactionLevel),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primaryBlue, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                  Text(session.location, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.grey600, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_formatTime(), style: AppTextStyles.caption),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.star, color: AppColors.warningOrange, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Min. ${session.minPartnerRating}', style: AppTextStyles.caption),
                  const Spacer(),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onJoin,
                      child: const Text('Join'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime() {
    final h = session.startTime.hour;
    final m = session.startTime.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final minute = m.toString().padLeft(2, '0');
    final dur = session.durationMinutes;
    final durText = dur >= 60
        ? (dur % 60 == 0 ? '${dur ~/ 60}h' : '${dur ~/ 60}h${dur % 60}m')
        : '${dur}m';
    return '$hour:$minute $period - $durText';
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  const _StatusTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, text) = switch (label) {
      'Silent' => (AppColors.tagSilentBackground, AppColors.tagSilentText),
      'Social' => (AppColors.tagSocialBackground, AppColors.tagSocialText),
      'Colab' => (AppColors.tagColabBackground, AppColors.tagColabText),
      _ => (AppColors.grey100, AppColors.grey600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: text)),
    );
  }
}
