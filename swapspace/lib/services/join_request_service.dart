import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/session_constants.dart';
import '../models/join_request_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../repositories/paginated_query_result.dart';
import '../repositories/join_request_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/user_repository.dart';
import 'notification_service.dart';

class AcceptRequestResult {
  final String sessionId;
  final String creatorUid;
  final String creatorName;
  final String sessionTitle;
  final String acceptedRequesterUid;
  final bool sessionIsFull;
  final List<String> rejectedRequesterUids;

  const AcceptRequestResult({
    required this.sessionId,
    required this.creatorUid,
    required this.creatorName,
    required this.sessionTitle,
    required this.acceptedRequesterUid,
    required this.sessionIsFull,
    required this.rejectedRequesterUids,
  });
}

class JoinRequestPageResult {
  final List<JoinRequestModel> items;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const JoinRequestPageResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });
}

class JoinRequestService {
  final JoinRequestRepository _requestRepo;
  final SessionRepository _sessionRepo;
  final UserRepository _userRepo;
  final NotificationService _notificationService;

  JoinRequestService({
    required JoinRequestRepository requestRepository,
    required SessionRepository sessionRepository,
    required UserRepository userRepository,
    required NotificationService notificationService,
  })  : _requestRepo = requestRepository,
        _sessionRepo = sessionRepository,
        _userRepo = userRepository,
        _notificationService = notificationService;

  Future<Map<String, SessionModel>> loadSessionsByIds(List<String> sessionIds) {
    return _sessionRepo.getByIds(sessionIds);
  }

  Future<Map<String, UserModel>> loadUsersByIds(List<String> uids) {
    return _userRepo.getPublicUsersByIds(uids);
  }

  Stream<List<JoinRequestModel>> listenIncomingRequests(String uid) {
    return _requestRepo.streamForCreator(uid).map((requests) => requests.toList());
  }

  Future<List<JoinRequestModel>> loadIncomingRequests(String uid) async {
    final firstPage = await loadIncomingRequestsPage(uid: uid);
    return firstPage.items;
  }

  Future<JoinRequestPageResult> loadIncomingRequestsPage({
    required String uid,
    int pageSize = JoinRequestRepository.defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final PaginatedQueryResult<JoinRequestModel> page =
        await _requestRepo.getPendingForCreatorPage(
          uid: uid,
          pageSize: pageSize,
          startAfterDocument: startAfterDocument,
        );

    return JoinRequestPageResult(
      items: page.items,
      lastDocument: page.lastDocument,
      hasMore: page.hasMore,
    );
  }

  Future<List<JoinRequestModel>> loadOutgoingRequests(String uid) async {
    final firstPage = await loadOutgoingRequestsPage(uid: uid);
    return firstPage.items;
  }

  Future<JoinRequestPageResult> loadOutgoingRequestsPage({
    required String uid,
    int pageSize = JoinRequestRepository.defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final PaginatedQueryResult<JoinRequestModel> page =
        await _requestRepo.getFromUserPage(
          uid: uid,
          pageSize: pageSize,
          startAfterDocument: startAfterDocument,
        );

    return JoinRequestPageResult(
      items: page.items,
      lastDocument: page.lastDocument,
      hasMore: page.hasMore,
    );
  }

  Future<void> sendJoinRequest({
    required String sessionId,
    required String creatorUid,
    required String requesterUid,
    required String requesterName,
    required String sessionTitle,
    String message = '',
  }) async {
    final requestId = _requestRepo.createRequestId();
    final now = DateTime.now();

    final request = JoinRequestModel(
      requestId: requestId,
      sessionId: sessionId,
      requesterUid: requesterUid,
      creatorUid: creatorUid,
      requestType: JoinRequestType.join,
      message: message,
      status: JoinRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    await _requestRepo.create(request);

    await _sendNotification(
      recipientUid: creatorUid,
      senderUid: requesterUid,
      senderName: requesterName,
      sessionId: sessionId,
      sessionTitle: sessionTitle,
      type: NotificationType.joinRequest,
      message: '$requesterName requested to join your session "$sessionTitle"',
    );
  }

  /// Atomically accepts one request and applies all related updates.
  ///
  /// Transaction guarantees:
  /// - selected request becomes accepted
  /// - session participant list is updated exactly once
  /// - if session becomes full, every other pending request is rejected
  Future<AcceptRequestResult> acceptRequest({required String requestId}) async {
    final now = DateTime.now();

    String sessionId = '';
    String creatorUid = '';
    String creatorName = '';
    String sessionTitle = '';
    String acceptedRequesterUid = '';
    String requestType = JoinRequestType.join;
    bool sessionIsFull = false;
    final rejectedRequesterUids = <String>[];

    await _requestRepo.runTransaction((tx) async {
      final request = await _requestRepo.getByIdTx(tx, requestId);
      if (request == null) {
        throw StateError('request-not-found');
      }

      if (request.status != JoinRequestStatus.pending) {
        throw StateError('request-not-pending');
      }

      sessionId = request.sessionId;
      acceptedRequesterUid = request.requesterUid;
      requestType = request.requestType;
      if (sessionId.isEmpty || acceptedRequesterUid.isEmpty) {
        throw StateError('request-invalid');
      }

      final session = await _sessionRepo.getByIdTx(tx, sessionId);
      if (session == null) {
        throw StateError('session-not-found');
      }

      creatorUid = session.creatorUid;
      creatorName = session.creatorName;
      sessionTitle = session.title;

      final participants = List<String>.from(session.participantUids);
      final maxParticipants = session.maxParticipants;

      if (request.requestType == JoinRequestType.leave) {
        if (!participants.contains(acceptedRequesterUid)) {
          throw StateError('participant-not-found');
        }

        participants.remove(acceptedRequesterUid);
        sessionIsFull = false;
      } else {
        final alreadyJoined = participants.contains(acceptedRequesterUid);
        if (!alreadyJoined && participants.length >= maxParticipants) {
          throw StateError('session-full');
        }

        if (!alreadyJoined) {
          participants.add(acceptedRequesterUid);
        }
        if (participants.length > maxParticipants) {
          throw StateError('capacity-exceeded');
        }

        sessionIsFull = participants.length >= maxParticipants;
      }

      await _requestRepo.updateStatusTx(
        tx: tx,
        requestId: requestId,
        status: JoinRequestStatus.accepted,
        updatedAt: now,
      );

      final updatedSession = session.copyWith(
        participantUids: participants,
        partnerUid: request.requestType == JoinRequestType.leave
            ? ''
            : acceptedRequesterUid,
        status: sessionIsFull ? SessionStatus.matched : SessionStatus.open,
        updatedAt: now,
      );
      await _sessionRepo.updateTx(tx, updatedSession);
    });

    // Handle other pending requests after the transaction commits.
    // This avoids mixing non-transactional queries within a transaction callback.
    if (sessionId.isNotEmpty) {
      final pendingSameSession = await _requestRepo.getPendingForSession(sessionId);
      for (final other in pendingSameSession) {
        if (other.requestId == requestId || other.requestType != JoinRequestType.join) {
          continue;
        }

        final otherRequesterUid = other.requesterUid;
        if (otherRequesterUid.isNotEmpty) {
          rejectedRequesterUids.add(otherRequesterUid);
        }

        await _requestRepo.update(
          other.copyWith(
            status: JoinRequestStatus.rejected,
            updatedAt: now,
          ),
        );
      }
    }

    for (final uid in rejectedRequesterUids) {
      await _sendNotification(
        recipientUid: uid,
        senderUid: creatorUid,
        senderName: creatorName,
        sessionId: sessionId,
        sessionTitle: sessionTitle,
        type: NotificationType.requestRejected,
        message:
            '$creatorName could not accept your request to join "$sessionTitle" (session is full)',
      );
    }

    await _sendNotification(
      recipientUid: acceptedRequesterUid,
      senderUid: creatorUid,
      senderName: creatorName,
      sessionId: sessionId,
      sessionTitle: sessionTitle,
      type: NotificationType.requestAccepted,
      message: requestType == JoinRequestType.leave
          ? '$creatorName approved your leave request for "$sessionTitle"'
          : '$creatorName accepted your request to join "$sessionTitle"',
    );

    return AcceptRequestResult(
      sessionId: sessionId,
      creatorUid: creatorUid,
      creatorName: creatorName,
      sessionTitle: sessionTitle,
      acceptedRequesterUid: acceptedRequesterUid,
      sessionIsFull: sessionIsFull,
      rejectedRequesterUids: rejectedRequesterUids,
    );
  }

  Future<void> rejectRequest({required String requestId}) async {
    final request = await _requestRepo.getById(requestId);
    if (request == null) {
      throw StateError('request-not-found');
    }

    if (request.status != JoinRequestStatus.pending) {
      throw StateError('request-not-pending');
    }

    await _requestRepo.update(
      request.copyWith(
        status: JoinRequestStatus.rejected,
        updatedAt: DateTime.now(),
      ),
    );

    final session = await _sessionRepo.getById(request.sessionId);
    final creatorName = session?.creatorName ?? 'Host';
    final title = session?.title ?? 'session';

    await _sendNotification(
      recipientUid: request.requesterUid,
      senderUid: request.creatorUid,
      senderName: creatorName,
      sessionId: request.sessionId,
      sessionTitle: title,
      type: NotificationType.requestRejected,
      message: request.requestType == JoinRequestType.leave
          ? '$creatorName rejected your leave request for "$title"'
          : '$creatorName rejected your request to join "$title"',
    );
  }

  Future<void> cancelJoinRequest({required String requestId}) async {
    final request = await _requestRepo.getById(requestId);
    if (request == null) {
      throw StateError('request-not-found');
    }

    await _requestRepo.update(
      request.copyWith(
        status: JoinRequestStatus.cancelled,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> leaveSession({
    required String sessionId,
    required String uid,
    required String userName,
  }) async {
    final session = await _sessionRepo.getById(sessionId);
    if (session == null) {
      throw StateError('session-not-found');
    }

    if (!session.participantUids.contains(uid)) {
      throw StateError('not-a-participant');
    }

    final existing = await _requestRepo.getFromUser(uid);
    final hasPendingLeave = existing.any(
      (r) =>
          r.sessionId == sessionId &&
          r.requestType == JoinRequestType.leave &&
          r.status == JoinRequestStatus.pending,
    );
    if (hasPendingLeave) {
      throw StateError('leave-request-pending');
    }

    final now = DateTime.now();
    final leaveRequest = JoinRequestModel(
      requestId: _requestRepo.createRequestId(),
      sessionId: sessionId,
      requesterUid: uid,
      creatorUid: session.creatorUid,
      requestType: JoinRequestType.leave,
      message: 'Leave request',
      status: JoinRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await _requestRepo.create(leaveRequest);

    await _sendNotification(
      recipientUid: session.creatorUid,
      senderUid: uid,
      senderName: userName,
      sessionId: sessionId,
      sessionTitle: session.title,
      type: NotificationType.joinRequest,
      message: '$userName requested to leave your session "${session.title}"',
    );
  }

  Future<void> _sendNotification({
    required String recipientUid,
    required String senderUid,
    required String senderName,
    required String sessionId,
    required String sessionTitle,
    required String type,
    required String message,
  }) async {
    await _notificationService.sendNotification(
      recipientUid: recipientUid,
      senderUid: senderUid,
      senderName: senderName,
      sessionId: sessionId,
      sessionTitle: sessionTitle,
      type: type,
      message: message,
    );
  }
}
