import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/join_request_model.dart';
import '../providers/notification_provider.dart';
import '../repositories/join_request_repository.dart';
import '../repositories/session_repository.dart';

class JoinRequestProvider extends ChangeNotifier {
  final JoinRequestRepository _requestRepo = JoinRequestRepository();
  final SessionRepository _sessionRepo = SessionRepository();
  NotificationProvider? _notificationProvider;

  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  List<JoinRequestModel> _incomingRequests = [];
  List<JoinRequestModel> _outgoingRequests = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingSub;

  List<JoinRequestModel> get incomingRequests => _incomingRequests;
  List<JoinRequestModel> get outgoingRequests => _outgoingRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingIncomingCount =>
      _incomingRequests.where((r) => r.status == 'pending').length;

  // ---------------------------------------------------------------------------
  // Real-time stream for incoming requests (used for badge)
  // ---------------------------------------------------------------------------

  void listenIncomingRequests(String uid) {
    _incomingSub?.cancel();
    _incomingSub = FirebaseFirestore.instance
        .collection('joinRequests')
        .where('creatorUid', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      _incomingRequests = snapshot.docs
          .map((doc) => JoinRequestModel.fromMap(doc.data()))
          .where((r) => r.status == 'pending')
          .toList();
      notifyListeners();
    }, onError: (_) {});
  }

  // ---------------------------------------------------------------------------
  // Load methods
  // ---------------------------------------------------------------------------

  Future<void> loadIncomingRequests(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _incomingRequests = await _requestRepo.getRequestsForCreator(uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load incoming requests';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOutgoingRequests(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _outgoingRequests = await _requestRepo.getRequestsByUser(uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load outgoing requests';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Send / Cancel
  // ---------------------------------------------------------------------------

  Future<bool> sendJoinRequest({
    required String sessionId,
    required String creatorUid,
    required String requesterUid,
    required String requesterName,
    required String sessionTitle,
    String message = '',
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final requestId =
          FirebaseFirestore.instance.collection('joinRequests').doc().id;
      final now = DateTime.now();
      final request = JoinRequestModel(
        requestId: requestId,
        sessionId: sessionId,
        requesterUid: requesterUid,
        creatorUid: creatorUid,
        message: message,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      await _requestRepo.create(request);
      _outgoingRequests.insert(0, request);

      // Notify the creator about the join request
      _notificationProvider?.sendNotification(
        recipientUid: creatorUid,
        senderUid: requesterUid,
        senderName: requesterName,
        sessionId: sessionId,
        sessionTitle: sessionTitle,
        type: 'join_request',
        message: '$requesterName requested to join your session "$sessionTitle"',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to send request';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelJoinRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final existing = _outgoingRequests.firstWhere(
        (r) => r.requestId == requestId,
        orElse: () => JoinRequestModel.empty(),
      );
      if (existing.requestId.isEmpty) {
        _error = 'Request not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updated = existing.copyWith(
        status: 'cancelled',
        updatedAt: DateTime.now(),
      );
      await _requestRepo.update(updated);

      _outgoingRequests =
          _outgoingRequests.where((r) => r.requestId != requestId).toList();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to cancel request';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Accept / Reject
  // ---------------------------------------------------------------------------

  Future<bool> acceptRequest(
      String requestId, String sessionId, String requesterUid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 1. Update the accepted request status
      final request = _incomingRequests.firstWhere(
        (r) => r.requestId == requestId,
        orElse: () => JoinRequestModel.empty(),
      );
      if (request.requestId.isEmpty) {
        _error = 'Request not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Fetch latest session and check if already full
      final session = await _sessionRepo.getById(sessionId);
      if (session == null) {
        _error = 'Session not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (session.participantUids.length >= session.maxParticipants) {
        // Session already full — auto-reject this request
        await _requestRepo.update(request.copyWith(
          status: 'rejected',
          updatedAt: DateTime.now(),
        ));
        _notificationProvider?.sendNotification(
          recipientUid: requesterUid,
          senderUid: session.creatorUid,
          senderName: session.creatorName,
          sessionId: sessionId,
          sessionTitle: session.title,
          type: 'request_rejected',
          message:
              '${session.creatorName} could not accept your request to join "${session.title}" (session is full)',
        );
        _incomingRequests =
            _incomingRequests.where((r) => r.requestId != requestId).toList();
        _error = 'Session is already full';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Accept the request
      final acceptedRequest = request.copyWith(
        status: 'accepted',
        updatedAt: DateTime.now(),
      );
      await _requestRepo.update(acceptedRequest);

      // 4. Update session: add requester to participantUids
      final updatedUids = [...session.participantUids, requesterUid];
      final isFull = updatedUids.length >= session.maxParticipants;
      final matchedSession = session.copyWith(
        participantUids: updatedUids,
        partnerUid: requesterUid,
        status: isFull ? 'matched' : 'open',
        updatedAt: DateTime.now(),
      );
      await _sessionRepo.update(matchedSession);

      // 5. If session is now full, reject ALL other pending requests + notify
      if (isFull) {
        final allRequests =
            await _requestRepo.getRequestsForSession(sessionId);
        for (final other in allRequests) {
          if (other.requestId != requestId && other.status == 'pending') {
            await _requestRepo.update(other.copyWith(
              status: 'rejected',
              updatedAt: DateTime.now(),
            ));
            _notificationProvider?.sendNotification(
              recipientUid: other.requesterUid,
              senderUid: session.creatorUid,
              senderName: session.creatorName,
              sessionId: sessionId,
              sessionTitle: session.title,
              type: 'request_rejected',
              message:
                  '${session.creatorName} could not accept your request to join "${session.title}" (session is full)',
            );
          }
        }
        // Clear all remaining incoming requests for this session locally
        _incomingRequests = _incomingRequests
            .where((r) => r.sessionId != sessionId)
            .toList();
      } else {
        // Just remove the accepted one
        _incomingRequests =
            _incomingRequests.where((r) => r.requestId != requestId).toList();
      }

      // 6. Send acceptance notification to requester
      _notificationProvider?.sendNotification(
        recipientUid: requesterUid,
        senderUid: session.creatorUid,
        senderName: session.creatorName,
        sessionId: sessionId,
        sessionTitle: session.title,
        type: 'request_accepted',
        message:
            '${session.creatorName} accepted your request to join the session "${session.title}"',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to accept request';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final request = _incomingRequests.firstWhere(
        (r) => r.requestId == requestId,
        orElse: () => JoinRequestModel.empty(),
      );
      if (request.requestId.isEmpty) {
        _error = 'Request not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updated = request.copyWith(
        status: 'rejected',
        updatedAt: DateTime.now(),
      );
      await _requestRepo.update(updated);

      // Notify requester about rejection
      final session = await _sessionRepo.getById(request.sessionId);
      if (session != null) {
        _notificationProvider?.sendNotification(
          recipientUid: request.requesterUid,
          senderUid: request.creatorUid,
          senderName: session.creatorName,
          sessionId: request.sessionId,
          sessionTitle: session.title,
          type: 'request_rejected',
          message: '${session.creatorName} rejected your request to join \"${session.title}\"',
        );
      }

      _incomingRequests =
          _incomingRequests.where((r) => r.requestId != requestId).toList();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to reject request';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Leave session — user removes themselves from a joined session
  // ---------------------------------------------------------------------------

  Future<bool> leaveSession({
    required String sessionId,
    required String uid,
    required String userName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final session = await _sessionRepo.getById(sessionId);
      if (session == null) {
        _error = 'Session not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Remove user from participantUids
      final updatedUids =
          session.participantUids.where((u) => u != uid).toList();
      final updatedSession = session.copyWith(
        participantUids: updatedUids,
        status: 'open', // reopen if was matched
        updatedAt: DateTime.now(),
      );
      await _sessionRepo.update(updatedSession);

      // Cancel the corresponding join request
      final requests = await _requestRepo.getRequestsForSession(sessionId);
      for (final r in requests) {
        if (r.requesterUid == uid &&
            (r.status == 'accepted' || r.status == 'pending')) {
          await _requestRepo.update(r.copyWith(
            status: 'cancelled',
            updatedAt: DateTime.now(),
          ));
        }
      }

      // Notify creator that user left
      _notificationProvider?.sendNotification(
        recipientUid: session.creatorUid,
        senderUid: uid,
        senderName: userName,
        sessionId: sessionId,
        sessionTitle: session.title,
        type: 'participant_left',
        message: '$userName left your session ${session.title}',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to leave session';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    super.dispose();
  }
}
