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
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: _activityColor()),
              Expanded(
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlueLight,
                                  AppColors.primaryBlueLight.withValues(
                                    alpha: 0.5,
                                  ),
                                ],
                              ),
                            ),
                            child: Icon(
                              _activityIcon(),
                              size: 18,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              session.title,
                              style: AppTextStyles.headingSmall,
                            ),
                          ),
                          if (session.minRating > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warningOrangeLight,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 12,
                                    color: AppColors.warningOrange,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${session.minRating.toStringAsFixed(1)}+',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.warningOrange,
                                    ),
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
                            Icon(
                              Icons.person,
                              size: 14,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'by ${session.creatorName}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.primaryBlue,
                            size: AppSpacing.iconSm,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              session.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.group,
                            color: AppColors.primaryBlue,
                            size: AppSpacing.iconSm,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${session.participantUids.length}/${session.maxParticipants} joined',
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  session.participantUids.length >=
                                      session.maxParticipants
                                  ? AppColors.successGreen
                                  : AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.grey600,
                              size: 14,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(_formatTime(), style: AppTextStyles.caption),
                            const SizedBox(width: AppSpacing.md),
                            Icon(
                              Icons.timer_outlined,
                              color: AppColors.grey600,
                              size: 14,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _formatDuration(),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            if (session.status == 'matched')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreenLight,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  'MATCHED',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.successGreen,
                                  ),
                                ),
                              ),
                            if (session.status == 'completed')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  'COMPLETED',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: onAction,
                                style:
                                    (isOwner
                                            ? ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.warningOrange,
                                                foregroundColor: Colors.white,
                                              )
                                            : ElevatedButton.styleFrom())
                                        .copyWith(
                                          minimumSize:
                                              const WidgetStatePropertyAll(
                                                Size(92, 36),
                                              ),
                                          padding: const WidgetStatePropertyAll(
                                            EdgeInsets.symmetric(
                                              horizontal: AppSpacing.md,
                                            ),
                                          ),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                child: Text(
                                  isOwner ? 'Update' : 'View',
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _activityColor() {
    return switch (session.activityType.toLowerCase()) {
      'study' => AppColors.primaryBlue,
      'gym' => AppColors.successGreen,
      'football' => AppColors.warningOrange,
      'walking' => AppColors.successGreen,
      _ => AppColors.primaryBlue,
    };
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
    final days = dur ~/ (24 * 60);
    final remain = dur % (24 * 60);
    final hours = remain ~/ 60;
    final mins = remain % 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (mins > 0 || parts.isEmpty) parts.add('${mins}m');
    return parts.join(' ');
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
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
