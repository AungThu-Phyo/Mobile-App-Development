import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import 'app_notification_card.dart';

class AppNotificationsTab extends StatefulWidget {
  final ScrollController scrollController;

  const AppNotificationsTab({super.key, required this.scrollController});

  @override
  State<AppNotificationsTab> createState() => _AppNotificationsTabState();
}

class _AppNotificationsTabState extends State<AppNotificationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userId ?? '';
      if (uid.isEmpty) return;

      final provider = context.read<NotificationProvider>();
      provider.loadNotifications(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final uid = context.read<AuthProvider>().userId ?? '';
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
          controller: widget.scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount:
              notifications.length + (provider.isLoadingMoreNotifications ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index >= notifications.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (uid.isNotEmpty &&
                provider.hasMoreNotifications &&
                !provider.isLoadingMoreNotifications &&
                index >= notifications.length - 2) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.read<NotificationProvider>().loadMoreNotifications(uid);
                }
              });
            }

            return AppNotificationCard(notification: notifications[index]);
          },
        );
      },
    );
  }
}
