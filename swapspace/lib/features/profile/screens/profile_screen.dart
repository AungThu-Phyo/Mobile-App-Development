import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/theme_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_appearance_card.dart';
import '../widgets/profile_hero.dart';
import '../widgets/profile_stats_card.dart';
import '../widgets/profile_details_card.dart';
import '../widgets/profile_sessions_card.dart';
import '../widgets/profile_privacy_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;
  String _loadedUid = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureHistoryLoaded());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureHistoryLoaded();
  }

  Future<void> _ensureHistoryLoaded() async {
    final uid = context.read<AuthProvider>().userId ?? '';
    if (uid.isEmpty) return;
    if (_loadedUid == uid) return;

    try {
      await context.read<SessionProvider>().loadMySessions(uid);
      if (!mounted) return;
      _loadedUid = uid;
    } catch (_) {
      // Keep _loadedUid unchanged so loading can be retried.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      if (authProvider.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final message = authProvider.error ?? 'Profile data could not be loaded.';
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off_rounded,
                  size: 64,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Unable to load profile',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          context.read<AuthProvider>().refreshCurrentUser(),
                      child: const Text('Retry'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.read<AuthProvider>().signOut(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
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
                ProfileHero(user: user),
                const SizedBox(height: AppSpacing.lg),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            ProfileStatsCard(user: user),
                            const SizedBox(height: AppSpacing.md),
                            ProfileDetailsCard(user: user),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ProfileSessionsCard(
                          selectedTab: _selectedTab,
                          onSelectTab: (index) =>
                              setState(() => _selectedTab = index),
                        ),
                      ),
                    ],
                  )
                else ...[
                  ProfileStatsCard(user: user),
                  const SizedBox(height: AppSpacing.md),
                  ProfileDetailsCard(user: user),
                  const SizedBox(height: AppSpacing.md),
                  ProfileSessionsCard(
                    selectedTab: _selectedTab,
                    onSelectTab: (index) =>
                        setState(() => _selectedTab = index),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                ProfileAppearanceCard(
                  isDarkMode: themeProvider.isDarkMode,
                  onChanged: (value) {
                    context.read<ThemeProvider>().setDarkMode(value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                ProfilePrivacyCard(authProvider: authProvider),
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
