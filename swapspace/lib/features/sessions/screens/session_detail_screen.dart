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

  @override
  void initState() {
    super.initState();
    _loadCreator();
  }

  Future<void> _loadCreator() async {
    try {
      _creator = await _userRepo.getUser(widget.session.creatorUid);
    } catch (_) {}
    if (mounted) setState(() => _loadingCreator = false);
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
              child: SizedBox(
                width: double.infinity,
                child: _buildActionButton(context, currentUid, isCreator, isOpen),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String currentUid, bool isCreator, bool isOpen) {
    final hasJoined = widget.session.participantUids.contains(currentUid);

    if (isCreator) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.cancel, color: AppColors.errorRed),
        label: const Text('Cancel Session', style: TextStyle(color: AppColors.errorRed)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.errorRed),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        onPressed: isOpen
            ? () async {
                final provider = context.read<SessionProvider>();
                final success = await provider.cancelSession(widget.session.sessionId);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session cancelled')),
                  );
                  context.go(RouteNames.home);
                }
              }
            : null,
      );
    }

    if (hasJoined) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.exit_to_app, color: AppColors.errorRed),
        label: const Text('Leave Session', style: TextStyle(color: AppColors.errorRed)),
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
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add),
      label: const Text('Request to Join'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      onPressed: isOpen ? () => _showJoinDialog(context, currentUid) : null,
    );
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
              final success = await provider.sendJoinRequest(
                sessionId: widget.session.sessionId,
                creatorUid: widget.session.creatorUid,
                requesterUid: currentUid,
                message: messageController.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Join request sent!'
                        : provider.error ?? 'Failed to send request'),
                  ),
                );
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
    if (dur >= 60) {
      return dur % 60 == 0 ? '${dur ~/ 60}h' : '${dur ~/ 60}h ${dur % 60}m';
    }
    return '${dur}m';
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
