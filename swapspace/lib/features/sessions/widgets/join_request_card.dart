import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/constants/session_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/join_request_model.dart';
import '../../../models/session_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/join_request_provider.dart';
import '../../../providers/session_provider.dart';
import 'request_review_card.dart';

class JoinRequestCard extends StatefulWidget {
  final JoinRequestModel request;

  const JoinRequestCard({required this.request});

  @override
  State<JoinRequestCard> createState() => _JoinRequestCardState();
}

class _JoinRequestCardState extends State<JoinRequestCard> {
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
        context.read<AuthProvider>().getUserById(widget.request.requesterUid),
        context.read<SessionProvider>().getSessionById(widget.request.sessionId),
      ]);
      _requester = results[0] as UserModel?;
      _session = results[1] as SessionModel?;
    } catch (e, stackTrace) {
      AppLogger.error('JoinRequestCard._loadDetails error', e, stackTrace);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.grey200),
        ),
        child: const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final isLeaveRequest = widget.request.requestType == JoinRequestType.leave;
    return RequestReviewCard(
      request: widget.request,
      requester: _requester,
      session: _session,
      onRequesterTap: _requester == null
          ? null
          : () => context.push(
                RouteNames.userProfileById(_requester!.uid),
              ),
      isActing: _acting,
      acceptLabel: isLeaveRequest ? 'Approve Leave' : 'Accept',
      rejectLabel: isLeaveRequest ? 'Deny Leave' : 'Reject',
      onAccept: () async {
        setState(() => _acting = true);
        final provider = context.read<JoinRequestProvider>();
        final success = await provider.acceptRequest(widget.request.requestId);
        if (context.mounted) {
          if (success) {
            context.read<SessionProvider>().loadOpenSessions();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isLeaveRequest
                      ? 'Leave request approved!'
                      : 'Request accepted!',
                ),
              ),
            );
          } else {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  provider.error ?? 'Failed to accept request',
                ),
              ),
            );
          }
        }
        if (mounted) setState(() => _acting = false);
      },
      onReject: () async {
        setState(() => _acting = true);
        final provider = context.read<JoinRequestProvider>();
        final success = await provider.rejectRequest(widget.request.requestId);
        if (context.mounted && success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLeaveRequest ? 'Leave request denied' : 'Request rejected',
              ),
            ),
          );
        }
        if (mounted) setState(() => _acting = false);
      },
    );
  }
}
