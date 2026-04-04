import 'dart:async';
import 'base_state_provider.dart';
import '../core/utils/app_logger.dart';
import '../models/join_request_model.dart';
import '../services/join_request_service.dart';

class JoinRequestProvider extends BaseStateProvider {
  final JoinRequestService _service;

  JoinRequestProvider({required JoinRequestService service})
      : _service = service;

  List<JoinRequestModel> _incomingRequests = [];
  List<JoinRequestModel> _outgoingRequests = [];
  StreamSubscription<List<JoinRequestModel>>? _incomingSub;

  List<JoinRequestModel> get incomingRequests => _incomingRequests;
  List<JoinRequestModel> get outgoingRequests => _outgoingRequests;

  int get pendingIncomingCount => _incomingRequests.length;

  // ---------------------------------------------------------------------------
  // Real-time stream for incoming requests (used for badge)
  // ---------------------------------------------------------------------------

  void listenIncomingRequests(String uid) {
    _incomingSub?.cancel();
    _incomingSub = _service.listenIncomingRequests(uid).listen((requests) {
      _incomingRequests = requests;
      notifyListeners();
    }, onError: (e, stackTrace) {
      AppLogger.error('JoinRequestProvider.listenIncomingRequests error', e, stackTrace);
    });
  }

  // ---------------------------------------------------------------------------
  // Load methods
  // ---------------------------------------------------------------------------

  Future<void> loadIncomingRequests(String uid) async {
    _incomingRequests = await runWithLoading<List<JoinRequestModel>>(
      debugLabel: 'JoinRequestProvider.loadIncomingRequests',
      errorMessage: 'Unable to load incoming requests',
      action: () => _service.loadIncomingRequests(uid),
    );
  }

  Future<void> loadOutgoingRequests(String uid) async {
    _outgoingRequests = await runWithLoading<List<JoinRequestModel>>(
      debugLabel: 'JoinRequestProvider.loadOutgoingRequests',
      errorMessage: 'Unable to load outgoing requests',
      action: () => _service.loadOutgoingRequests(uid),
    );
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
    return runWithLoading<bool>(
      debugLabel: 'JoinRequestProvider.sendJoinRequest',
      errorMessage: 'Unable to send request',
      action: () async {
        await _service.sendJoinRequest(
          sessionId: sessionId,
          creatorUid: creatorUid,
          requesterUid: requesterUid,
          requesterName: requesterName,
          sessionTitle: sessionTitle,
          message: message,
        );

        _outgoingRequests = await _service.loadOutgoingRequests(requesterUid);
        return true;
      },
    );
  }

  Future<bool> cancelJoinRequest(String requestId) async {
    return runWithLoading<bool>(
      debugLabel: 'JoinRequestProvider.cancelJoinRequest',
      errorMessage: 'Unable to cancel request',
      action: () async {
        await _service.cancelJoinRequest(requestId: requestId);
        _outgoingRequests =
            _outgoingRequests.where((r) => r.requestId != requestId).toList();
        return true;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Accept / Reject
  // ---------------------------------------------------------------------------

  Future<bool> acceptRequest(String requestId) async {
    return runWithLoading<bool>(
      debugLabel: 'JoinRequestProvider.acceptRequest',
      errorMessage: 'Unable to accept request',
      action: () async {
        final result = await _service.acceptRequest(requestId: requestId);
        _incomingRequests =
            await _service.loadIncomingRequests(result.creatorUid);
        return true;
      },
    );
  }

  Future<bool> rejectRequest(String requestId) async {
    return runWithLoading<bool>(
      debugLabel: 'JoinRequestProvider.rejectRequest',
      errorMessage: 'Unable to reject request',
      action: () async {
        final request = _incomingRequests.firstWhere(
          (r) => r.requestId == requestId,
          orElse: () => JoinRequestModel.empty(),
        );

        await _service.rejectRequest(requestId: requestId);
        if (request.requestId.isNotEmpty) {
          _incomingRequests = await _service.loadIncomingRequests(request.creatorUid);
        }
        return true;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Leave session — user removes themselves from a joined session
  // ---------------------------------------------------------------------------

  Future<bool> leaveSession({
    required String sessionId,
    required String uid,
    required String userName,
  }) async {
    return runWithLoading<bool>(
      debugLabel: 'JoinRequestProvider.leaveSession',
      errorMessage: 'Unable to leave session',
      action: () async {
        await _service.leaveSession(
          sessionId: sessionId,
          uid: uid,
          userName: userName,
        );

        _outgoingRequests = await _service.loadOutgoingRequests(uid);
        return true;
      },
    );
  }

  @override
  void clearError() {
    setError(null);
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    super.dispose();
  }
}
