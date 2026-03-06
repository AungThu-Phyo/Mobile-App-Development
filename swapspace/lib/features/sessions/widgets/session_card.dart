import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/session_model.dart';

class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onTap;
  final VoidCallback onAction;
  final bool isOwner;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    required this.onAction,
    this.isOwner = false,
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlueLight,
                    ),
                    child: Icon(_activityIcon(), size: 18, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(session.title, style: AppTextStyles.headingSmall),
                  ),
                  if (session.minRating > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${session.minRating.toStringAsFixed(1)}+',
                            style: AppTextStyles.labelSmall.copyWith(color: Colors.amber.shade800),
                          ),
                        ],
                      ),
                    ),
                  _InteractionTag(label: session.interactionPreference),
                ],
              ),
              if (session.creatorName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 44),
                    const Icon(Icons.person, size: 14, color: AppColors.grey600),
                    const SizedBox(width: 4),
                    Text(
                      'by ${session.creatorName}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primaryBlue, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                  Text(session.location, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  Icon(Icons.group, color: AppColors.primaryBlue, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${session.participantUids.length}/${session.maxParticipants} joined',
                    style: AppTextStyles.caption.copyWith(
                      color: session.participantUids.length >= session.maxParticipants
                          ? AppColors.successGreen
                          : AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.grey600, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_formatTime(), style: AppTextStyles.caption),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.timer_outlined, color: AppColors.grey600, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_formatDuration(), style: AppTextStyles.caption),
                  const Spacer(),
                  if (session.status == 'matched')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.successGreenLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'MATCHED',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.successGreen),
                      ),
                    ),
                  if (session.status == 'completed')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'COMPLETED',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey600),
                      ),
                    ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: isOwner
                          ? ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warningOrange,
                            )
                          : null,
                      child: Text(isOwner ? 'Update' : 'View'),
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

  IconData _activityIcon() {
    return switch (session.activityType.toLowerCase()) {
      'study' => Icons.menu_book,
      'gym' => Icons.fitness_center,
      'football' => Icons.sports_soccer,
      'walking' => Icons.directions_walk,
      _ => Icons.group,
    };
  }

  String _formatTime() {
    final h = session.date.hour;
    final m = session.date.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final minute = m.toString().padLeft(2, '0');
    return '${session.date.month}/${session.date.day} $hour:$minute $period';
  }

  String _formatDuration() {
    final dur = session.durationMinutes;
    if (dur >= 60) {
      return dur % 60 == 0 ? '${dur ~/ 60}h' : '${dur ~/ 60}h${dur % 60}m';
    }
    return '${dur}m';
  }
}

class _InteractionTag extends StatelessWidget {
  final String label;
  const _InteractionTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, text) = switch (label.toLowerCase()) {
      'silent' => (AppColors.tagSilentBackground, AppColors.tagSilentText),
      'social' => (AppColors.tagSocialBackground, AppColors.tagSocialText),
      _ => (AppColors.grey100, AppColors.grey600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: AppTextStyles.labelSmall.copyWith(color: text),
      ),
    );
  }
}
