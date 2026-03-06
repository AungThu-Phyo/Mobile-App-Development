import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/join_request_model.dart';
import '../../../models/notification_model.dart';
import '../../../models/user_model.dart';
import '../../../models/session_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/join_request_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/session_repository.dart';
import '../widgets/filter_tabs.dart';
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
    final now = DateTime.now();
    final cutoff = session.date.subtract(const Duration(hours: 1));
    return now.isBefore(cutoff);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().firebaseUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SwapSpace', style: AppTextStyles.headingMedium),
        automaticallyImplyLeading: false,
        actions: [
          Consumer2<JoinRequestProvider, NotificationProvider>(
            builder: (context, reqProvider, notiProvider, _) {
              final count = reqProvider.pendingIncomingCount + notiProvider.unreadCount;
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
                        const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
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
                        Icon(Icons.event_busy, size: 64, color: AppColors.grey400),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No sessions available',
                          style: AppTextStyles.headingSmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
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
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
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
                            context.go(RouteNames.sessionDetail, extra: session);
                          },
                          onAction: () {
                            provider.selectSession(session);
                            if (isOwner && _canEdit(session)) {
                              context.go(RouteNames.editSession, extra: session);
                            } else if (isOwner) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cannot edit session less than 1 hour before start'),
                                ),
                              );
                            } else {
                              context.go(RouteNames.sessionDetail, extra: session);
                            }
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => _NotificationsSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }
}

// =============================================================================
// Notifications bottom sheet — shows join requests + app notifications
// =============================================================================

class _NotificationsSheet extends StatelessWidget {
  final ScrollController scrollController;
  const _NotificationsSheet({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                const Text('Notifications', style: AppTextStyles.headingMedium),
                const Spacer(),
                Consumer2<JoinRequestProvider, NotificationProvider>(
                  builder: (context, reqP, notiP, _) {
                    final count = reqP.pendingIncomingCount + notiP.unreadCount;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text('$count new',
                          style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.grey600,
            indicatorColor: AppColors.primaryBlue,
            tabs: [
              Tab(text: 'Join Requests'),
              Tab(text: 'Updates'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: incoming join requests (for session creators)
                _JoinRequestsTab(scrollController: scrollController),
                // Tab 2: app notifications (accepted, rejected, updated, left)
                _AppNotificationsTab(scrollController: scrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Tab 1: Join Requests (same as before) ----
class _JoinRequestsTab extends StatelessWidget {
  final ScrollController scrollController;
  const _JoinRequestsTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<JoinRequestProvider>(
      builder: (context, provider, _) {
        final requests = provider.incomingRequests;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 48, color: AppColors.grey400),
                const SizedBox(height: AppSpacing.sm),
                Text('No pending requests',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            return _JoinRequestCard(request: requests[index]);
          },
        );
      },
    );
  }
}

// ---- Tab 2: App Notifications ----
class _AppNotificationsTab extends StatelessWidget {
  final ScrollController scrollController;
  const _AppNotificationsTab({required this.scrollController});

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
                Icon(Icons.notifications_none, size: 48, color: AppColors.grey400),
                const SizedBox(height: AppSpacing.sm),
                Text('No notifications yet',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
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
            return _AppNotificationCard(notification: notifications[index]);
          },
        );
      },
    );
  }
}

// ---- App notification card ----
class _AppNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _AppNotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = switch (notification.type) {
      'request_accepted' => (Icons.check_circle, AppColors.successGreen),
      'request_rejected' => (Icons.cancel, AppColors.errorRed),
      'session_updated' => (Icons.edit, AppColors.warningOrange),
      'participant_left' => (Icons.exit_to_app, AppColors.grey600),
      _ => (Icons.notifications, AppColors.primaryBlue),
    };

    return Card(
      color: notification.isRead ? Colors.white : AppColors.primaryBlueLight,
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationProvider>().markAsRead(notification.notificationId);
          }
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withValues(alpha: 0.15),
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
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ---- Join request card (unchanged logic) ----
class _JoinRequestCard extends StatefulWidget {
  final JoinRequestModel request;
  const _JoinRequestCard({required this.request});

  @override
  State<_JoinRequestCard> createState() => _JoinRequestCardState();
}

class _JoinRequestCardState extends State<_JoinRequestCard> {
  final UserRepository _userRepo = UserRepository();
  final SessionRepository _sessionRepo = SessionRepository();
  UserModel? _requester;
  SessionModel? _session;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final results = await Future.wait([
        _userRepo.getUser(widget.request.requesterUid),
        _sessionRepo.getById(widget.request.sessionId),
      ]);
      _requester = results[0] as UserModel?;
      _session = results[1] as SessionModel?;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      );
    }

    final requesterName = _requester?.name ?? 'Someone';
    final sessionTitle = _session?.title ?? 'your session';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requester row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryBlueLight,
                  backgroundImage:
                      _requester != null && _requester!.avatarUrl.isNotEmpty
                          ? NetworkImage(_requester!.avatarUrl)
                          : null,
                  child: _requester == null || _requester!.avatarUrl.isEmpty
                      ? Text(
                          requesterName.isNotEmpty ? requesterName[0] : '?',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.primaryBlue),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium,
                      children: [
                        TextSpan(
                          text: requesterName,
                          style: AppTextStyles.labelLarge,
                        ),
                        const TextSpan(text: ' wants to join '),
                        TextSpan(
                          text: sessionTitle,
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Message
            if (widget.request.message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '"${widget.request.message}"',
                  style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // Accept / Reject buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.errorRed),
                    ),
                    onPressed: _acting
                        ? null
                        : () async {
                            setState(() => _acting = true);
                            final provider = context.read<JoinRequestProvider>();
                            final success = await provider.rejectRequest(widget.request.requestId);
                            if (context.mounted && success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request rejected')),
                              );
                            }
                          },
                    child: const Text('Reject', style: TextStyle(color: AppColors.errorRed)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                    ),
                    onPressed: _acting
                        ? null
                        : () async {
                            setState(() => _acting = true);
                            final provider = context.read<JoinRequestProvider>();
                            final success = await provider.acceptRequest(
                              widget.request.requestId,
                              widget.request.sessionId,
                              widget.request.requesterUid,
                            );
                            if (context.mounted) {
                              if (success) {
                                // Refresh home sessions so matched session disappears
                                context.read<SessionProvider>().loadOpenSessions();
                                Navigator.pop(context); // close bottom sheet
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Request accepted!')),
                                );
                              } else {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(provider.error ?? 'Failed to accept request'),
                                  ),
                                );
                              }
                            }
                          },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
