import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/session_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/theme_provider.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
      if (uid.isNotEmpty) {
        context.read<SessionProvider>().loadMySessions(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primaryBlueLight,
              ),
              child: Icon(
                Icons.account_circle_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Profile'),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 860;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHero(user: user),
                const SizedBox(height: AppSpacing.lg),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _ProfileStatsCard(user: user),
                            const SizedBox(height: AppSpacing.md),
                            _ProfileDetailsCard(user: user),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SessionsCard(
                          selectedTab: _selectedTab,
                          onSelectTab: (index) =>
                              setState(() => _selectedTab = index),
                          authProvider: authProvider,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _ProfileStatsCard(user: user),
                  const SizedBox(height: AppSpacing.md),
                  _ProfileDetailsCard(user: user),
                  const SizedBox(height: AppSpacing.md),
                  _SessionsCard(
                    selectedTab: _selectedTab,
                    onSelectTab: (index) =>
                        setState(() => _selectedTab = index),
                    authProvider: authProvider,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _AppearanceCard(
                  isDarkMode: themeProvider.isDarkMode,
                  onChanged: (value) {
                    context.read<ThemeProvider>().setDarkMode(value);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.logout, color: AppColors.errorRed),
                    label: Text(
                      'Sign Out',
                      style: TextStyle(color: AppColors.errorRed),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.errorRed),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onPressed: () {
                      context.read<AuthProvider>().signOut();
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _AppearanceCard({required this.isDarkMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBlueLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dark Mode', style: AppTextStyles.headingSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Turn on a darker look for night use and lower glare.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch.adaptive(value: isDarkMode, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final UserModel user;
  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradientCoolToWarm,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your account',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryBlueDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProfileHeader(user: user),
        ],
      ),
    );
  }
}

class _ProfileStatsCard extends StatelessWidget {
  final UserModel user;
  const _ProfileStatsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Rating',
                    value: user.rating.toStringAsFixed(1),
                    accent: AppColors.primaryBlue,
                    icon: Icons.star_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatTile(
                    label: 'Sessions',
                    value: '${user.totalSessions}',
                    accent: AppColors.warningOrange,
                    icon: Icons.event_available_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i < user.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warningOrange,
                    size: 20,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${user.totalSessions} sessions completed',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  final UserModel user;
  const _ProfileDetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Details', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            if (user.bio.isNotEmpty) ...[
              Text(
                'About',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(user.bio, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.md),
            ],
            if (user.faculty.isNotEmpty)
              _InfoRow(
                icon: Icons.school_rounded,
                label: 'Faculty',
                value: user.faculty,
              ),
            _InfoRow(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Interaction',
              value:
                  user.interactionPreference[0].toUpperCase() +
                  user.interactionPreference.substring(1),
            ),
            if (user.activityPreferences.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Activities',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: user.activityPreferences.map<Widget>((activity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      activity[0].toUpperCase() + activity.substring(1),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionsCard extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onSelectTab;
  final AuthProvider authProvider;

  const _SessionsCard({
    required this.selectedTab,
    required this.onSelectTab,
    required this.authProvider,
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
                  child: _TabButton(
                    label: 'Created',
                    selected: selectedTab == 0,
                    onTap: () => onSelectTab(0),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TabButton(
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

                final uid = authProvider.firebaseUser?.uid ?? '';
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
                      child: _SessionRow(
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

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.headingMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.iconSm, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.labelLarge,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final SessionModel session;
  final bool isCreator;
  const _SessionRow({required this.session, required this.isCreator});

  IconData _activityIcon(String type) {
    return switch (type.toLowerCase()) {
      'study' => Icons.menu_book,
      'gym' => Icons.fitness_center,
      'football' => Icons.sports_soccer,
      'walking' => Icons.directions_walk,
      _ => Icons.group,
    };
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
                            child: Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              side: BorderSide(color: AppColors.grey600),
                            ),
                            onPressed: () => context.push(
                              RouteNames.sessionDetail,
                              extra: session,
                            ),
                            child: Text(
                              'View',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey600,
                              ),
                            ),
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

  String _formatDate(DateTime d) {
    const months = [
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
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
