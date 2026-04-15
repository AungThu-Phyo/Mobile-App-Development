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
      onAccept: () async {
        final provider = context.read<JoinRequestProvider>();
        final success = await provider.acceptRequest(request.requestId);
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
      },
      onReject: () async {
        final provider = context.read<JoinRequestProvider>();
        final success = await provider.rejectRequest(request.requestId);
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
      },
    );
  }
}
