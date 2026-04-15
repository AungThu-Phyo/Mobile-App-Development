import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/constants/session_constants.dart';
import '../../../models/join_request_model.dart';
import '../../../providers/join_request_provider.dart';
import '../../../providers/session_provider.dart';
import 'request_review_card.dart';

class JoinRequestCard extends StatelessWidget {
  final JoinRequestModel request;

  const JoinRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final joinRequestProvider = context.read<JoinRequestProvider>();
    final isActing = context.select<JoinRequestProvider, bool>(
      (provider) => provider.isRequestActing(request.requestId),
    );
    final isAccepting = context.select<JoinRequestProvider, bool>(
      (provider) => provider.isRequestAccepting(request.requestId),
    );
    final isRejecting = context.select<JoinRequestProvider, bool>(
      (provider) => provider.isRequestRejecting(request.requestId),
    );
    final requester = joinRequestProvider.getCachedUser(request.requesterUid);
    final session = joinRequestProvider.getCachedSession(request.sessionId);
    final isLeaveRequest = request.requestType == JoinRequestType.leave;

    return RequestReviewCard(
      request: request,
      requester: requester,
      session: session,
      onRequesterTap: requester == null
          ? null
          : () => context.push(
                RouteNames.userProfileById(requester.uid),
              ),
      isActing: isActing,
      acceptLabel: isLeaveRequest ? 'Approve Leave' : 'Accept',
      rejectLabel: isLeaveRequest ? 'Deny Leave' : 'Reject',
      isAccepting: isAccepting,
      isRejecting: isRejecting,
      onAccept: () async {
        final provider = context.read<JoinRequestProvider>();
        final success = await provider.acceptRequest(request.requestId);
        if (context.mounted) {
          if (success) {
            context.read<SessionProvider>().loadOpenSessions();
            _dismissPopupIfOpen(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isLeaveRequest
                      ? 'You approved the leave request.'
                      : 'You accepted the join request.',
                ),
              ),
            );
          } else {
            _dismissPopupIfOpen(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  provider.error ?? 'Failed to accept request',
                ),
              ),
            );
          }
        }
      },
      onReject: () async {
        final provider = context.read<JoinRequestProvider>();
        final success = await provider.rejectRequest(request.requestId);
        if (context.mounted && success) {
          _dismissPopupIfOpen(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  isLeaveRequest
                      ? 'You denied the leave request.'
                      : 'You rejected the join request.',
              ),
            ),
          );
        }
      },
    );
  }

  void _dismissPopupIfOpen(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route is PopupRoute && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
