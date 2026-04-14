import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/session_constants.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';

class AppNotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const AppNotificationCard({super.key, required this.notification});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = switch (notification.type) {
      NotificationType.requestAccepted => (
        Icons.check_circle_rounded,
        AppColors.successGreen,
      ),
      NotificationType.requestRejected => (
        Icons.cancel_rounded,
        AppColors.errorRed,
      ),
      NotificationType.sessionUpdated => (
        Icons.edit_rounded,
        AppColors.warningOrange,
      ),
      NotificationType.participantLeft => (
        Icons.exit_to_app_rounded,
        AppColors.grey600,
      ),
      _ => (Icons.notifications_rounded, AppColors.primaryBlue),
    };

    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          context.read<NotificationProvider>().markAsRead(
                notification.notificationId,
              );
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surface : AppColors.notifUnreadBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: notification.isRead
                ? AppColors.grey200
                : iconColor.withValues(alpha: 0.4),
            width: notification.isRead ? 1.0 : 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!notification.isRead) Container(width: 4, color: iconColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(
                              alpha: notification.isRead ? 0.1 : 0.18,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 20, color: iconColor),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.message,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                  color: notification.isRead
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: AppColors.grey400,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _timeAgo(notification.createdAt),
                                    style: AppTextStyles.captionSmall.copyWith(
                                      color: AppColors.grey400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: iconColor,
                              boxShadow: [
                                BoxShadow(
                                  color: iconColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
