import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/join_request_model.dart';
import '../../../models/user_model.dart';
import '../../../models/session_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/join_request_provider.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/session_repository.dart';

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
        title: const Text('Requests', style: AppTextStyles.headingMedium),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.grey600,
          indicatorColor: AppColors.primaryBlue,
          tabs: [
            Consumer<JoinRequestProvider>(
              builder: (context, provider, _) {
                final count = provider.pendingIncomingCount;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Incoming'),
                      if (count > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            '$count',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(text: 'Outgoing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IncomingTab(onRefresh: _loadData),
          _OutgoingTab(onRefresh: _loadData),
        ],
      ),
    );
  }
}

// =============================================================================
// Incoming Tab
// =============================================================================

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: AppColors.grey400),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No incoming requests',
                  style: AppTextStyles.headingSmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'When someone wants to join your session,\nit will appear here.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
            // Session title
            if (_session != null)
              Text(
                _session!.title,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.primaryBlue),
              ),
            const SizedBox(height: AppSpacing.sm),

            // Requester info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
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
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.primaryBlue),
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
                        Text(
                          _requester!.faculty,
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.star,
                    color: AppColors.warningOrange, size: 14),
                const SizedBox(width: 2),
                Text(
                  (_requester?.rating ?? 0).toStringAsFixed(1),
                  style: AppTextStyles.labelLarge,
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
                  widget.request.message,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // Action buttons
            if (sessionOpen)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.errorRed),
                      ),
                      onPressed: () async {
                        final provider = context.read<JoinRequestProvider>();
                        final success =
                            await provider.rejectRequest(widget.request.requestId);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request rejected')),
                          );
                        }
                      },
                      child: const Text('Reject',
                          style: TextStyle(color: AppColors.errorRed)),
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
                                content: Text('Request accepted — matched!')),
                          );
                        }
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Session no longer open',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.grey600),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Outgoing Tab
// =============================================================================

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 64, color: AppColors.grey400),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No outgoing requests',
                  style: AppTextStyles.headingSmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'When you request to join a session,\nit will appear here.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
            // Session title + status badge
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

            // Creator info
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
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
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.primaryBlue),
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

            // Message
            if (widget.request.message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '"${widget.request.message}"',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],

            // Cancel button
            if (isPending) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorRed),
                  ),
                  onPressed: () async {
                    final provider = context.read<JoinRequestProvider>();
                    final success = await provider
                        .cancelJoinRequest(widget.request.requestId);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request cancelled')),
                      );
                    }
                  },
                  child: const Text('Cancel Request',
                      style: TextStyle(color: AppColors.errorRed)),
                ),
              ),
            ],
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
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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
