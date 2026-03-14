import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/join_request_model.dart';
import '../../../models/session_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/join_request_provider.dart';
import '../../../repositories/session_repository.dart';
import '../../../repositories/user_repository.dart';

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
    final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
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
            itemCount: provider.incomingRequests.length,
            itemBuilder: (context, index) {
              return _IncomingRequestCard(
                request: provider.incomingRequests[index],
              );
            },
          ),
        );
      },
    );
  }
}

class _IncomingRequestCard extends StatefulWidget {
  final JoinRequestModel request;
  const _IncomingRequestCard({required this.request});

  @override
  State<_IncomingRequestCard> createState() => _IncomingRequestCardState();
}

class _IncomingRequestCardState extends State<_IncomingRequestCard> {
  final UserRepository _userRepo = UserRepository();
  final SessionRepository _sessionRepo = SessionRepository();
  UserModel? _requester;
  SessionModel? _session;
  bool _loading = true;

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
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final sessionOpen = _session?.status == 'open';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_session != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  _session!.title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryBlueDark,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryBlueLight,
                  backgroundImage:
                      _requester != null && _requester!.avatarUrl.isNotEmpty
                      ? NetworkImage(_requester!.avatarUrl)
                      : null,
                  child: _requester == null || _requester!.avatarUrl.isEmpty
                      ? Text(
                          _requester?.name.isNotEmpty == true
                              ? _requester!.name[0]
                              : '?',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _requester?.name ?? 'Unknown',
                        style: AppTextStyles.labelLarge,
                      ),
                      if (_requester?.faculty.isNotEmpty == true)
                        Text(_requester!.faculty, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrangeLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: AppColors.warningOrange,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        (_requester?.rating ?? 0).toStringAsFixed(1),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.request.message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  widget.request.message,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (sessionOpen)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.errorRed),
                      ),
                      onPressed: () async {
                        final provider = context.read<JoinRequestProvider>();
                        final success = await provider.rejectRequest(
                          widget.request.requestId,
                        );
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request rejected')),
                          );
                        }
                      },
                      child: Text(
                        'Reject',
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final provider = context.read<JoinRequestProvider>();
                        final success = await provider.acceptRequest(
                          widget.request.requestId,
                          widget.request.sessionId,
                          widget.request.requesterUid,
                        );
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request accepted — matched!'),
                            ),
                          );
                        }
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  'Session no longer open',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ),
          ],
        ),
      ),
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
            itemCount: provider.outgoingRequests.length,
            itemBuilder: (context, index) {
              return _OutgoingRequestCard(
                request: provider.outgoingRequests[index],
              );
            },
          ),
        );
      },
    );
  }
}

class _OutgoingRequestCard extends StatefulWidget {
  final JoinRequestModel request;
  const _OutgoingRequestCard({required this.request});

  @override
  State<_OutgoingRequestCard> createState() => _OutgoingRequestCardState();
}

class _OutgoingRequestCardState extends State<_OutgoingRequestCard> {
  final SessionRepository _sessionRepo = SessionRepository();
  final UserRepository _userRepo = UserRepository();
  SessionModel? _session;
  UserModel? _creator;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      _session = await _sessionRepo.getById(widget.request.sessionId);
      if (_session != null) {
        _creator = await _userRepo.getUser(_session!.creatorUid);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final isPending = widget.request.status == 'pending';

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
                    _session?.title ?? 'Unknown Session',
                    style: AppTextStyles.headingSmall,
                  ),
                ),
                _RequestStatusBadge(status: widget.request.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryBlueLight,
                  backgroundImage:
                      _creator != null && _creator!.avatarUrl.isNotEmpty
                      ? NetworkImage(_creator!.avatarUrl)
                      : null,
                  child: _creator == null || _creator!.avatarUrl.isEmpty
                      ? Text(
                          _creator?.name.isNotEmpty == true
                              ? _creator!.name[0]
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
                  'by ${_creator?.name ?? 'Unknown'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            if (widget.request.message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '"${widget.request.message}"',
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
                      widget.request.requestId,
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
