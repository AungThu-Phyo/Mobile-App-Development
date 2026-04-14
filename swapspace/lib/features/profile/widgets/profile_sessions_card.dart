import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import 'profile_session_row.dart';
import 'profile_tab_button.dart';

class ProfileSessionsCard extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onSelectTab;

  const ProfileSessionsCard({
    super.key,
    required this.selectedTab,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Sessions', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Track what you created and what you joined.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ProfileTabButton(
                    label: 'Created',
                    selected: selectedTab == 0,
                    onTap: () => onSelectTab(0),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ProfileTabButton(
                    label: 'Joined',
                    selected: selectedTab == 1,
                    onTap: () => onSelectTab(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Consumer<SessionProvider>(
              builder: (context, provider, _) {
                final uid = context.read<AuthProvider>().userId ?? '';
                final isCreatedTab = selectedTab == 0;
                final isJoinedTab = !isCreatedTab;

                if ((isCreatedTab && provider.isLoadingCreatedSessions) ||
                    (isJoinedTab && provider.isLoadingJoinedSessions)) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (provider.error != null && provider.error!.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.errorRed,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: uid.isEmpty
                              ? null
                              : () {
                                  final sessionProvider =
                                      context.read<SessionProvider>();
                                  if (isCreatedTab) {
                                    sessionProvider.loadCreatedSessions(uid);
                                  } else {
                                    sessionProvider.loadJoinedSessions(uid);
                                  }
                                },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final sessions = isCreatedTab
                    ? provider.createdSessions
                  : provider.joinedSessions;

                if (sessions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Center(
                      child: Text(
                        selectedTab == 0
                            ? 'No sessions created yet'
                            : 'No sessions joined yet',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length +
                      (((isCreatedTab && provider.isLoadingMoreCreatedSessions) ||
                          (isJoinedTab && provider.isLoadingMoreJoinedSessions))
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (index >= sessions.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == sessions.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: ProfileSessionRow(
                        session: sessions[index],
                        isCreator: selectedTab == 0,
                      ),
                    );
                  },
                );
              },
            ),
            if (selectedTab == 0 || selectedTab == 1)
              Consumer<SessionProvider>(
                builder: (context, provider, _) {
                  final uid = context.read<AuthProvider>().userId ?? '';
                  final canLoadMore = selectedTab == 0
                      ? provider.hasMoreCreatedSessions
                      : provider.hasMoreJoinedSessions;
                  if (!canLoadMore || uid.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final isLoadingMore = selectedTab == 0
                      ? provider.isLoadingMoreCreatedSessions
                      : provider.isLoadingMoreJoinedSessions;

                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: isLoadingMore
                            ? null
                            : () {
                                final sessionProvider =
                                    context.read<SessionProvider>();
                                if (selectedTab == 0) {
                                  sessionProvider.loadMoreCreatedSessions(uid);
                                } else {
                                  sessionProvider.loadMoreJoinedSessions(uid);
                                }
                              },
                        child: Text(
                          isLoadingMore
                              ? 'Loading...'
                              : 'Load More',
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
