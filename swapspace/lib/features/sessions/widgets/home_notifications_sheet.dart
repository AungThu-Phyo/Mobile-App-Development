import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/join_request_provider.dart';
import '../../../providers/notification_provider.dart';
import 'join_requests_tab.dart';
import 'app_notifications_tab.dart';

class HomeNotificationsSheet extends StatelessWidget {
  final ScrollController scrollController;

  const HomeNotificationsSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Consumer2<JoinRequestProvider, NotificationProvider>(
                  builder: (context, joinRequestProvider, notificationProvider, _) {
                    final count =
                        joinRequestProvider.pendingIncomingCount +
                        notificationProvider.unreadCount;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        '$count new',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.grey600,
            indicatorColor: AppColors.primaryBlue,
            indicatorWeight: 3,
            labelStyle: AppTextStyles.labelLarge,
            unselectedLabelStyle: AppTextStyles.bodyMedium,
            dividerColor: AppColors.grey200,
            tabs: const [
              Tab(text: 'Join Requests'),
              Tab(text: 'Updates'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                JoinRequestsTab(scrollController: scrollController),
                AppNotificationsTab(scrollController: scrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
