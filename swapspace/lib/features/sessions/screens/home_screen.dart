import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/session_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/join_request_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/session_provider.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/home_notifications_sheet.dart';
import '../widgets/session_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final sessionProvider = context.read<SessionProvider>();
      sessionProvider.setUserRating(authProvider.currentUser?.rating ?? 0.0);
      sessionProvider.setCurrentUid(authProvider.currentUser?.uid ?? '');
      sessionProvider.loadOpenSessions();
    });
  }

  /// Returns true if the session can still be edited (>= 1 hour before start).
  bool _canEdit(SessionModel session) {
    return SessionDateFormatter.canEditSession(session.date);
  }

  void _handleSessionAction({
    required BuildContext context,
    required SessionProvider provider,
    required SessionModel session,
    required bool isOwner,
  }) {
    provider.selectSession(session);
    if (isOwner && _canEdit(session)) {
      context.go(
        RouteNames.editSession,
        extra: session,
      );
      return;
    }

    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot edit session less than 1 hour before start',
          ),
        ),
      );
      return;
    }

    context.go(
      RouteNames.sessionDetail,
      extra: session,
    );
  }

  @override
  Widget build(BuildContext context) {
      final currentUid = context.read<AuthProvider>().userId ?? '';
    final userName = context.read<AuthProvider>().currentUser?.name ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: AppColors.primaryBlueLight,
              ),
              child: Icon(
                Icons.explore_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('SwapSpace', style: AppTextStyles.headingMedium),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          Consumer2<JoinRequestProvider, NotificationProvider>(
            builder: (context, reqProvider, notiProvider, _) {
              final count =
                  reqProvider.pendingIncomingCount + notiProvider.unreadCount;
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => _showNotificationsSheet(context),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
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
                  Text('Hi, $userName', style: AppTextStyles.headingSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Find a partner and start your next activity.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Consumer<SessionProvider>(
              builder: (context, provider, _) {
                return FilterTabs(
                  selectedFilter: provider.selectedFilter,
                  onFilterSelected: provider.setFilter,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Consumer<SessionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.errorRed,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(provider.error!, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () => provider.loadOpenSessions(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final sessions = provider.filteredSessions;

                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No sessions available',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Be the first to create an activity!',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create Session'),
                          onPressed: () => context.go(RouteNames.createSession),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadOpenSessions(),
                  child: ListView.builder(
                    itemCount:
                        sessions.length + (provider.isLoadingMoreOpenSessions ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= sessions.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (provider.hasMoreOpenSessions &&
                          !provider.isLoadingMoreOpenSessions &&
                          index >= sessions.length - 3) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            context.read<SessionProvider>().loadMoreOpenSessions();
                          }
                        });
                      }

                      final session = sessions[index];
                      final isOwner = session.creatorUid == currentUid;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ).copyWith(bottom: AppSpacing.sm),
                        child: SessionCard(
                          session: session,
                          isOwner: isOwner,
                          onTap: () {
                            provider.selectSession(session);
                            context.go(
                              RouteNames.sessionDetail,
                              extra: session,
                            );
                          },
                          onCreatorTap: () {
                            context.push(
                              RouteNames.userProfileById(session.creatorUid),
                            );
                          },
                          onAction: () {
                            _handleSessionAction(
                              context: context,
                              provider: provider,
                              session: session,
                              isOwner: isOwner,
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) =>
            HomeNotificationsSheet(scrollController: scrollController),
      ),
    );
  }
}
