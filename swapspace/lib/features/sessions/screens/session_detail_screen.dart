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
import '../../../providers/feedback_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/join_request_provider.dart';
import '../../../repositories/user_repository.dart';

class SessionDetailScreen extends StatefulWidget {
  final SessionModel session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final UserRepository _userRepo = UserRepository();
  UserModel? _creator;
  bool _loadingCreator = true;
  bool _requestSent = false;
  bool _feedbackSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadCreator();
    _checkFeedback();
  }

  Future<void> _loadCreator() async {
    try {
      _creator = await _userRepo.getUser(widget.session.creatorUid);
    } catch (_) {}
    if (mounted) setState(() => _loadingCreator = false);
  }

  Future<void> _checkFeedback() async {
    if (widget.session.status != 'completed') return;
    final currentUid =
        context.read<AuthProvider>().firebaseUser?.uid ?? '';
    if (currentUid.isEmpty) return;
    final otherCount = widget.session.participantUids
        .where((uid) => uid != currentUid)
        .length;
    final submitted = await context
        .read<FeedbackProvider>()
        .hasAllFeedbackSubmitted(
            widget.session.sessionId, currentUid, otherCount);
    if (mounted) setState(() => _feedbackSubmitted = submitted);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
    final isCreator = widget.session.creatorUid == currentUid;
    final isOpen = widget.session.status == 'open';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Session Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              height: 180,
              width: double.infinity,
              color: AppColors.primaryBlueLight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_activityIcon(), size: 56, color: AppColors.primaryBlue),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.session.activityType[0].toUpperCase() +
                          widget.session.activityType.substring(1),
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryBlue),
                    ),
                  ],
                ),
              ),
            ),

            // Title + status
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.session.title, style: AppTextStyles.headingMedium),
                  ),
                  _StatusBadge(status: widget.session.status),
                ],
              ),
            ),

            // Description
            if (widget.session.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  widget.session.description,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            // Creator info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: _loadingCreator
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primaryBlueLight,
                              backgroundImage: _creator != null && _creator!.avatarUrl.isNotEmpty
                                  ? NetworkImage(_creator!.avatarUrl)
                                  : null,
                              child: _creator == null || _creator!.avatarUrl.isEmpty
                                  ? Text(
                                      _creator?.name.isNotEmpty == true
                                          ? _creator!.name[0]
                                          : '?',
                                      style: AppTextStyles.headingSmall
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
                                    _creator?.name ??
                                        (widget.session.creatorName.isNotEmpty
                                            ? widget.session.creatorName
                                            : 'Unknown'),
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  if (_creator?.faculty.isNotEmpty == true)
                                    Text(
                                      _creator!.faculty,
                                      style: AppTextStyles.caption
                                          .copyWith(color: AppColors.primaryBlue),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.star, color: AppColors.warningOrange, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              (_creator?.rating ?? 0).toStringAsFixed(1),
                              style: AppTextStyles.labelLarge,
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Details card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: const Text('Activity Details', style: AppTextStyles.headingSmall),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    children: [
                      _DetailRow(
                          icon: Icons.category,
                          label: 'Type',
                          value: widget.session.activityType[0].toUpperCase() +
                              widget.session.activityType.substring(1)),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.calendar_today, label: 'Date', value: _formatDate()),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.access_time, label: 'Time', value: _formatTime()),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.timer, label: 'Duration', value: _formatDuration()),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.location_on, label: 'Location', value: widget.session.location),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.group, label: 'Participants', value: '${widget.session.participantUids.length}/${widget.session.maxParticipants} joined'),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(
                        icon: widget.session.interactionPreference == 'silent'
                            ? Icons.volume_off
                            : Icons.chat_bubble_outline,
                        label: 'Interaction',
                        value: widget.session.interactionPreference[0].toUpperCase() +
                            widget.session.interactionPreference.substring(1),
                      ),
                      if (widget.session.faculty.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _DetailRow(icon: Icons.school, label: 'Faculty', value: widget.session.faculty),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.star, label: 'Min Rating Required', value: widget.session.minRating.toStringAsFixed(1)),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildActionButtons(context, currentUid, isCreator, isOpen),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String currentUid, bool isCreator, bool isOpen) {
    final hasJoined = widget.session.participantUids.contains(currentUid);
    final isMatched = widget.session.status == 'matched';
    final isCompleted = widget.session.status == 'completed';

    final buttons = <Widget>[];

    // "Complete Session" — only for creator of a matched session
    if (isCreator && isMatched) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            onPressed: () => _completeSession(context),
          ),
        ),
      );
      buttons.add(const SizedBox(height: AppSpacing.sm));
    }

    // "Give Feedback" — for anyone involved in a completed session (if not already submitted)
    if (isCompleted && (isCreator || hasJoined) && !_feedbackSubmitted) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.rate_review),
            label: const Text('Give Feedback'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            onPressed: () =>
                context.go(RouteNames.feedback, extra: widget.session),
          ),
        ),
      );
      buttons.add(const SizedBox(height: AppSpacing.sm));
    }

    // Cancel — for creator of open/matched session
    if (isCreator && (isOpen || isMatched)) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.cancel, color: AppColors.errorRed),
            label: const Text('Cancel Session',
                style: TextStyle(color: AppColors.errorRed)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.errorRed),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            onPressed: () async {
              final provider = context.read<SessionProvider>();
              final success =
                  await provider.cancelSession(widget.session.sessionId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session cancelled')),
                );
                context.go(RouteNames.home);
              }
            },
          ),
        ),
      );
    }

    // Leave — for non-creator participants of open/matched sessions
    if (!isCreator && hasJoined && (isOpen || isMatched)) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.exit_to_app, color: AppColors.errorRed),
            label: const Text('Leave Session',
                style: TextStyle(color: AppColors.errorRed)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.errorRed),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final userName = authProvider.currentUser?.name ?? '';
              final provider = context.read<JoinRequestProvider>();
              final success = await provider.leaveSession(
                sessionId: widget.session.sessionId,
                uid: currentUid,
                userName: userName,
              );
              if (success && mounted) {
                context.read<SessionProvider>().loadOpenSessions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You left the session')),
                );
                context.go(RouteNames.home);
              }
            },
          ),
        ),
      );
    }

    // Request to Join — for non-creator, non-joined users on sessions with room
    final hasRoom = widget.session.participantUids.length < widget.session.maxParticipants;
    if (!isCreator && !hasJoined && (isOpen || (isMatched && hasRoom))) {
      if (_requestSent) {
        final creatorName = _creator?.name ?? widget.session.creatorName;
        buttons.add(
          Card(
            color: AppColors.successGreenLight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.successGreen),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Your request has been sent to $creatorName',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.successGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Request to Join'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              onPressed: () => _showJoinDialog(context, currentUid),
            ),
          ),
        );
      }
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Column(children: buttons);
  }

  Future<void> _completeSession(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Session'),
        content: const Text(
          'Mark this session as completed? Both you and participants will be prompted to give feedback.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<SessionProvider>();
    final updated = widget.session.copyWith(
      status: 'completed',
      isActive: false,
      updatedAt: DateTime.now(),
    );
    final success = await provider.updateSession(updated);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session completed! Please give feedback.')),
      );
      context.go(RouteNames.feedback, extra: updated);
    }
  }

  void _showJoinDialog(BuildContext context, String currentUid) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request to Join'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            hintText: 'Add a message (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<JoinRequestProvider>();
              final authProvider = context.read<AuthProvider>();
              final userName = authProvider.currentUser?.name ?? 'Someone';
              final success = await provider.sendJoinRequest(
                sessionId: widget.session.sessionId,
                creatorUid: widget.session.creatorUid,
                requesterUid: currentUid,
                requesterName: userName,
                sessionTitle: widget.session.title,
                message: messageController.text.trim(),
              );
              if (mounted) {
                if (success) {
                  setState(() => _requestSent = true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.error ?? 'Failed to send request'),
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  IconData _activityIcon() {
    return switch (widget.session.activityType.toLowerCase()) {
      'study' => Icons.menu_book,
      'gym' => Icons.fitness_center,
      'football' => Icons.sports_soccer,
      'walking' => Icons.directions_walk,
      _ => Icons.group,
    };
  }

  String _formatDate() {
    final d = widget.session.date;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime() {
    final d = widget.session.date;
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDuration() {
    final dur = widget.session.durationMinutes;
    final days = dur ~/ (24 * 60);
    final remain = dur % (24 * 60);
    final hours = remain ~/ 60;
    final mins = remain % 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (mins > 0 || parts.isEmpty) parts.add('${mins}m');
    return parts.join(' ');
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'open' => (AppColors.successGreenLight, AppColors.successGreen),
      'matched' => (AppColors.primaryBlueLight, AppColors.primaryBlue),
      'completed' => (AppColors.grey100, AppColors.grey600),
      'cancelled' => (const Color(0xFFFFEBEE), AppColors.errorRed),
      _ => (AppColors.grey100, AppColors.grey600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSpacing.iconSm, color: AppColors.primaryBlue),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(value, style: AppTextStyles.labelLarge, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
