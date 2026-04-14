import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/constants/session_constants.dart';
import '../../../models/join_request_model.dart';
import '../../../models/session_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/join_request_provider.dart';
import '../widgets/request_review_card.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
      final uid = context.read<AuthProvider>().userId ?? '';
    if (uid.isEmpty) return;
    final provider = context.read<JoinRequestProvider>();
    provider.loadIncomingRequests(uid);
    provider.loadOutgoingRequests(uid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Icons.mail_outline_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Requests', style: AppTextStyles.headingMedium),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
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
              child: Text(
                'Manage people who want to join your sessions and track the requests you already sent.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.grey600,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                indicator: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                tabs: [
                  Consumer<JoinRequestProvider>(
                    builder: (context, provider, _) {
                      final count = provider.pendingIncomingCount;
                      return Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Incoming'),
                              if (count > 0) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorRed,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text('Outgoing'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _IncomingTab(onRefresh: _loadData),
                _OutgoingTab(onRefresh: _loadData),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _IncomingTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<JoinRequestProvider>(
      builder: (context, provider, _) {
        final uid = context.read<AuthProvider>().userId ?? '';

        if (provider.isLoading && provider.incomingRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.incomingRequests.isEmpty) {
          return const _EmptyRequestsState(
            icon: Icons.inbox_rounded,
            title: 'No incoming requests',
            subtitle:
                'When someone wants to join your session, it will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: provider.incomingRequests.length +
                (provider.isLoadingMoreIncomingRequests ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.incomingRequests.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (uid.isNotEmpty &&
                  provider.hasMoreIncomingRequests &&
                  !provider.isLoadingMoreIncomingRequests &&
                  index >= provider.incomingRequests.length - 2) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.read<JoinRequestProvider>().loadMoreIncomingRequests(uid);
                  }
                });
              }

              return _IncomingRequestCard(
                request: provider.incomingRequests[index],
                requester: provider.getCachedUser(
                  provider.incomingRequests[index].requesterUid,
                ),
                session: provider.getCachedSession(
                  provider.incomingRequests[index].sessionId,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  final JoinRequestModel request;
  final UserModel? requester;
  final SessionModel? session;

  const _IncomingRequestCard({
    required this.request,
    required this.requester,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final isLeaveRequest = request.requestType == JoinRequestType.leave;

    return RequestReviewCard(
      request: request,
      requester: requester,
      session: session,
      onRequesterTap: requester == null
          ? null
          : () => context.push(
                RouteNames.userProfileById(requester!.uid),
              ),
      isActing: false,
      acceptLabel: isLeaveRequest ? 'Approve Leave' : 'Accept',
      rejectLabel: isLeaveRequest ? 'Deny Leave' : 'Reject',
      onAccept: () async {
        final provider = context.read<JoinRequestProvider>();
        final success = await provider.acceptRequest(request.requestId);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLeaveRequest
                    ? 'Leave request approved'
                    : 'Request accepted — matched!',
              ),
            ),
          );
        }
      },
      onReject: () async {
        final provider = context.read<JoinRequestProvider>();
        final success = await provider.rejectRequest(request.requestId);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLeaveRequest ? 'Leave request denied' : 'Request rejected',
              ),
            ),
          );
        }
      },
    );
  }
}

class _OutgoingTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _OutgoingTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<JoinRequestProvider>(
      builder: (context, provider, _) {
        final uid = context.read<AuthProvider>().userId ?? '';

        if (provider.isLoading && provider.outgoingRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.outgoingRequests.isEmpty) {
          return const _EmptyRequestsState(
            icon: Icons.send_rounded,
            title: 'No outgoing requests',
            subtitle:
                'When you request to join a session, it will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: provider.outgoingRequests.length +
                (provider.isLoadingMoreOutgoingRequests ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.outgoingRequests.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (uid.isNotEmpty &&
                  provider.hasMoreOutgoingRequests &&
                  !provider.isLoadingMoreOutgoingRequests &&
                  index >= provider.outgoingRequests.length - 2) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.read<JoinRequestProvider>().loadMoreOutgoingRequests(uid);
                  }
                });
              }

              return _OutgoingRequestCard(
                request: provider.outgoingRequests[index],
                session: provider.getCachedSession(
                  provider.outgoingRequests[index].sessionId,
                ),
                creator: (() {
                  final session = provider.getCachedSession(
                    provider.outgoingRequests[index].sessionId,
                  );
                  if (session == null) return null;
                  return provider.getCachedUser(session.creatorUid);
                })(),
              );
            },
          ),
        );
      },
    );
  }
}

class _OutgoingRequestCard extends StatelessWidget {
  final JoinRequestModel request;
  final SessionModel? session;
  final UserModel? creator;

  const _OutgoingRequestCard({
    required this.request,
    required this.session,
    required this.creator,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session?.title ?? 'Unknown Session',
                    style: AppTextStyles.headingSmall,
                  ),
                ),
                _RequestStatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: creator == null
                  ? null
                  : () => context.push(
                        RouteNames.userProfileById(creator!.uid),
                      ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 2,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryBlueLight,
                      backgroundImage:
                          creator != null && creator!.avatarUrl.isNotEmpty
                          ? NetworkImage(creator!.avatarUrl)
                          : null,
                        child: creator == null || creator!.avatarUrl.isEmpty
                          ? Text(
                            creator?.name.isNotEmpty == true
                              ? creator!.name[0]
                                  : '?',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'by ${creator?.name ?? 'Unknown'}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
            if (request.message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '"${request.message}"',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.errorRed),
                  ),
                  onPressed: () async {
                    final provider = context.read<JoinRequestProvider>();
                    final success = await provider.cancelJoinRequest(
                      request.requestId,
                    );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request cancelled')),
                      );
                    }
                  },
                  child: Text(
                    'Cancel Request',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyRequestsState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyRequestsState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.grey400),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestStatusBadge extends StatelessWidget {
  final String status;
  const _RequestStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'pending' => (AppColors.warningOrangeLight, AppColors.warningOrange),
      'accepted' => (AppColors.successGreenLight, AppColors.successGreen),
      'rejected' => (const Color(0xFFFFEBEE), AppColors.errorRed),
      'cancelled' => (AppColors.grey100, AppColors.grey600),
      _ => (AppColors.grey100, AppColors.grey600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(color: fg),
      ),
    );
  }
}
