import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/notification_provider.dart';
import 'app_notification_card.dart';

class AppNotificationsTab extends StatelessWidget {
  final ScrollController scrollController;

  const AppNotificationsTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final notifications = provider.notifications;

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 48,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No notifications yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            return AppNotificationCard(notification: notifications[index]);
          },
        );
      },
    );
  }
}
