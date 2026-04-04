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
                if (provider.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final uid = context.read<AuthProvider>().userId ?? '';

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
                              : () => context
                                    .read<SessionProvider>()
                                    .loadMySessions(uid),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final sessions = selectedTab == 0
                    ? provider.mySessions
                          .where((s) => s.creatorUid == uid)
                          .toList()
                    : provider.mySessions
                          .where(
                            (s) =>
                                s.creatorUid != uid &&
                                (s.partnerUid == uid ||
                                    s.participantUids.contains(uid)),
                          )
                          .toList();

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
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
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
          ],
        ),
      ),
    );
  }
}
