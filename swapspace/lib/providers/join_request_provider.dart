import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_state_provider.dart';
import '../core/utils/app_logger.dart';
import '../models/join_request_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../services/join_request_service.dart';

class JoinRequestProvider extends BaseStateProvider {
  final JoinRequestService _service;

  JoinRequestProvider({required JoinRequestService service})
      : _service = service;

  List<JoinRequestModel> _incomingRequests = [];
  List<JoinRequestModel> _outgoingRequests = [];
  List<JoinRequestModel> _liveIncomingRequests = [];
  final Map<String, SessionModel> _sessionById = {};
  final Map<String, UserModel> _userById = {};
  StreamSubscription<List<JoinRequestModel>>? _incomingSub;
  QueryDocumentSnapshot<Map<String, dynamic>>? _incomingCursor;
  QueryDocumentSnapshot<Map<String, dynamic>>? _outgoingCursor;
  bool _hasMoreIncomingRequests = true;
  bool _hasMoreOutgoingRequests = true;
  bool _isLoadingMoreIncomingRequests = false;
  bool _isLoadingMoreOutgoingRequests = false;
  bool _hasLiveIncomingData = false;

  List<JoinRequestModel> get incomingRequests => _incomingRequests;
  List<JoinRequestModel> get outgoingRequests => _outgoingRequests;
  SessionModel? getCachedSession(String sessionId) => _sessionById[sessionId];
  UserModel? getCachedUser(String uid) => _userById[uid];
  bool get hasMoreIncomingRequests => _hasMoreIncomingRequests;
  bool get hasMoreOutgoingRequests => _hasMoreOutgoingRequests;
  bool get isLoadingMoreIncomingRequests => _isLoadingMoreIncomingRequests;
  bool get isLoadingMoreOutgoingRequests => _isLoadingMoreOutgoingRequests;

  int get pendingIncomingCount =>
      _hasLiveIncomingData
          ? _liveIncomingRequests.length
          : _incomingRequests.length;

  // ---------------------------------------------------------------------------
  // Real-time stream for incoming requests (used for badge)
  // ---------------------------------------------------------------------------

  void listenIncomingRequests(String uid) {
    _incomingSub?.cancel();
    _incomingSub = _service.listenIncomingRequests(uid).listen((requests) {
      _liveIncomingRequests = requests;
      _hasLiveIncomingData = true;

      if (_incomingRequests.isEmpty) {
        _incomingRequests = requests;
        unawaited(_hydrateRequestRelations());
      }

      notifyListeners();
    }, onError: (e, stackTrace) {
      AppLogger.error('JoinRequestProvider.listenIncomingRequests error', e, stackTrace);
    });
  }

  // ---------------------------------------------------------------------------
  // Load methods
  // ---------------------------------------------------------------------------

  Future<void> loadIncomingRequests(String uid) async {
    final firstPage = await runWithLoading<JoinRequestPageResult>(
      debugLabel: 'JoinRequestProvider.loadIncomingRequests',
      errorMessage: 'Unable to load incoming requests',
      action: () => _service.loadIncomingRequestsPage(uid: uid),
    );

    _incomingRequests = firstPage.items;
    _incomingCursor = firstPage.lastDocument;
    _hasMoreIncomingRequests = firstPage.hasMore;
    await _hydrateRequestRelations();
  }

  Future<void> loadMoreIncomingRequests(String uid) async {
    if (_isLoadingMoreIncomingRequests || !_hasMoreIncomingRequests) {
      return;
    }

    _isLoadingMoreIncomingRequests = true;
    notifyListeners();

    try {
      final nextPage = await _service.loadIncomingRequestsPage(
        uid: uid,
        startAfterDocument: _incomingCursor,
      );

      _incomingRequests = [..._incomingRequests, ...nextPage.items];
      _incomingCursor = nextPage.lastDocument;
      _hasMoreIncomingRequests = nextPage.hasMore;
      await _hydrateRequestRelations();
      setError(null);
    } catch (e, stackTrace) {
      AppLogger.error('JoinRequestProvider.loadMoreIncomingRequests error', e, stackTrace);
      setError('Unable to load more incoming requests');
    } finally {
      _isLoadingMoreIncomingRequests = false;
      notifyListeners();
    }
  }

  Future<void> loadOutgoingRequests(String uid) async {
    final firstPage = await runWithLoading<JoinRequestPageResult>(
      debugLabel: 'JoinRequestProvider.loadOutgoingRequests',
      errorMessage: 'Unable to load outgoing requests',
      action: () => _service.loadOutgoingRequestsPage(uid: uid),
    );

    _outgoingRequests = firstPage.items;
    _outgoingCursor = firstPage.lastDocument;
    _hasMoreOutgoingRequests = firstPage.hasMore;
    await _hydrateRequestRelations();
  }

  Future<void> loadMoreOutgoingRequests(String uid) async {
    if (_isLoadingMoreOutgoingRequests || !_hasMoreOutgoingRequests) {
      return;
    }

    _isLoadingMoreOutgoingRequests = true;
    notifyListeners();

    try {
      final nextPage = await _service.loadOutgoingRequestsPage(
        uid: uid,
        startAfterDocument: _outgoingCursor,
      );

      _outgoingRequests = [..._outgoingRequests, ...nextPage.items];
      _outgoingCursor = nextPage.lastDocument;
      _hasMoreOutgoingRequests = nextPage.hasMore;
      await _hydrateRequestRelations();
      setError(null);
    } catch (e, stackTrace) {
      AppLogger.error('JoinRequestProvider.loadMoreOutgoingRequests error', e, stackTrace);
      setError('Unable to load more outgoing requests');
    } finally {
      _isLoadingMoreOutgoingRequests = false;
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
        await _hydrateRequestRelations();
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
        await _hydrateRequestRelations();
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
          await _hydrateRequestRelations();
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
        await _hydrateRequestRelations();
        return true;
      },
    );
  }

  Future<void> _hydrateRequestRelations() async {
    final combinedRequests = [..._incomingRequests, ..._outgoingRequests];
    if (combinedRequests.isEmpty) return;

    final requestedSessionIds = combinedRequests
        .map((request) => request.sessionId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final missingSessionIds = requestedSessionIds
        .where((id) => !_sessionById.containsKey(id))
        .toList();

    if (missingSessionIds.isNotEmpty) {
      final loadedSessions = await _service.loadSessionsByIds(missingSessionIds);
      _sessionById.addAll(loadedSessions);
    }

    final requesterUids = _incomingRequests
        .map((request) => request.requesterUid)
        .where((uid) => uid.isNotEmpty)
        .toSet();

    final creatorUids = _outgoingRequests
        .map((request) => _sessionById[request.sessionId]?.creatorUid ?? '')
        .where((uid) => uid.isNotEmpty)
        .toSet();

    final allNeededUserIds = {...requesterUids, ...creatorUids};
    final missingUserIds = allNeededUserIds
        .where((uid) => !_userById.containsKey(uid))
        .toList();

    if (missingUserIds.isNotEmpty) {
      final loadedUsers = await _service.loadUsersByIds(missingUserIds);
      _userById.addAll(loadedUsers);
    }
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
