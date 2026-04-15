import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_state_provider.dart';
import '../core/constants/session_constants.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';

class SessionProvider extends BaseStateProvider {
  final SessionService _service;

  SessionProvider({required SessionService service}) : _service = service;

  List<SessionModel> _sessions = [];
  List<SessionModel> _mySessions = [];
  List<SessionModel> _createdSessions = [];
  List<SessionModel> _joinedSessions = [];
  SessionModel? _selectedSession;
  String _selectedFilter = SessionConstants.filterAll;
  double _userRating = 0.0;
  QueryDocumentSnapshot<Map<String, dynamic>>? _openSessionsCursor;
  QueryDocumentSnapshot<Map<String, dynamic>>? _createdSessionsCursor;
  JoinedSessionsCursorState _joinedSessionsCursorState =
      const JoinedSessionsCursorState(
        partnerCursor: null,
        participantCursor: null,
        hasMorePartner: true,
        hasMoreParticipant: true,
      );
  bool _hasMoreOpenSessions = true;
  bool _hasMoreCreatedSessions = true;
  bool _hasMoreJoinedSessions = true;
  bool _isLoadingMoreOpenSessions = false;
  bool _isLoadingCreatedSessions = false;
  bool _isLoadingMoreCreatedSessions = false;
  bool _isLoadingJoinedSessions = false;
  bool _isLoadingMoreJoinedSessions = false;

  String _createdSessionsUid = '';
  String _joinedSessionsUid = '';

  String _currentUid = '';

  void setUserRating(double rating) {
    _userRating = rating;
  }

  void setCurrentUid(String uid) {
    _currentUid = uid;
  }

  List<SessionModel> get sessions => _sessions;
  List<SessionModel> get mySessions => _mySessions;
  List<SessionModel> get createdSessions => _createdSessions;
  List<SessionModel> get joinedSessions => _joinedSessions;
  SessionModel? get selectedSession => _selectedSession;
  String get selectedFilter => _selectedFilter;
  bool get hasMoreOpenSessions => _hasMoreOpenSessions;
  bool get isLoadingMoreOpenSessions => _isLoadingMoreOpenSessions;
  bool get hasMoreCreatedSessions => _hasMoreCreatedSessions;
  bool get hasMoreJoinedSessions => _hasMoreJoinedSessions;
  bool get isLoadingCreatedSessions => _isLoadingCreatedSessions;
  bool get isLoadingMoreCreatedSessions => _isLoadingMoreCreatedSessions;
  bool get isLoadingJoinedSessions => _isLoadingJoinedSessions;
  bool get isLoadingMoreJoinedSessions => _isLoadingMoreJoinedSessions;

  List<SessionModel> get filteredSessions {
    return _service.filterSessions(
      sessions: _sessions,
      currentUid: _currentUid,
      userRating: _userRating,
      selectedFilter: _selectedFilter,
    );
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> loadOpenSessions() async {
    final firstPage = await runWithLoading<SessionPageResult>(
      debugLabel: 'SessionProvider.loadOpenSessions',
      errorMessage: 'Unable to load sessions',
      action: () => _service.loadOpenSessionsPage(),
    );

    _sessions = firstPage.items;
    _openSessionsCursor = firstPage.lastDocument;
    _hasMoreOpenSessions = firstPage.hasMore;
  }

  Future<void> loadMoreOpenSessions() async {
    if (_isLoadingMoreOpenSessions || !_hasMoreOpenSessions) {
      return;
    }

    _isLoadingMoreOpenSessions = true;
    notifyListeners();

    try {
      final nextPage = await _service.loadOpenSessionsPage(
        startAfterDocument: _openSessionsCursor,
      );

      _sessions = [..._sessions, ...nextPage.items];
      _openSessionsCursor = nextPage.lastDocument;
      _hasMoreOpenSessions = nextPage.hasMore;
      setError(null);
    } catch (e) {
      setError('Unable to load more sessions');
    } finally {
      _isLoadingMoreOpenSessions = false;
      notifyListeners();
    }
  }

  Future<void> loadMySessions(String uid) async {
    _mySessions = await runWithLoading<List<SessionModel>>(
      debugLabel: 'SessionProvider.loadMySessions',
      errorMessage: 'Unable to load your sessions',
      action: () => _service.loadMySessions(uid),
    );
  }

  Future<void> loadCreatedSessions(String uid, {bool refresh = true}) async {
    if (uid.trim().isEmpty) return;
    if (!refresh && _createdSessionsUid == uid && _createdSessions.isNotEmpty) {
      return;
    }

    _isLoadingCreatedSessions = true;
    notifyListeners();

    try {
      final firstPage = await _service.loadCreatedSessionsPage(uid: uid);
      _createdSessions = firstPage.items;
      _createdSessionsCursor = firstPage.lastDocument;
      _hasMoreCreatedSessions = firstPage.hasMore;
      _createdSessionsUid = uid;
      setError(null);
    } catch (e) {
      setError('Unable to load your created sessions');
      rethrow;
    } finally {
      _isLoadingCreatedSessions = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreCreatedSessions(String uid) async {
    if (_isLoadingMoreCreatedSessions || !_hasMoreCreatedSessions) {
      return;
    }
    if (uid.trim().isEmpty || _createdSessionsUid != uid) {
      await loadCreatedSessions(uid);
      return;
    }

    _isLoadingMoreCreatedSessions = true;
    notifyListeners();

    try {
      final nextPage = await _service.loadCreatedSessionsPage(
        uid: uid,
        startAfterDocument: _createdSessionsCursor,
      );
      _createdSessions = [..._createdSessions, ...nextPage.items];
      _createdSessionsCursor = nextPage.lastDocument;
      _hasMoreCreatedSessions = nextPage.hasMore;
      setError(null);
    } catch (e) {
      setError('Unable to load more created sessions');
    } finally {
      _isLoadingMoreCreatedSessions = false;
      notifyListeners();
    }
  }

  Future<void> loadJoinedSessions(String uid, {bool refresh = true}) async {
    if (uid.trim().isEmpty) return;
    if (!refresh && _joinedSessionsUid == uid && _joinedSessions.isNotEmpty) {
      return;
    }

    _isLoadingJoinedSessions = true;
    notifyListeners();

    try {
      final firstPage = await _service.loadJoinedSessionsPage(uid: uid);
      _joinedSessions = firstPage.items;
      _joinedSessionsCursorState = firstPage.cursorState;
      _hasMoreJoinedSessions =
          firstPage.cursorState.hasMorePartner ||
          firstPage.cursorState.hasMoreParticipant;
      _joinedSessionsUid = uid;
      setError(null);
    } catch (e) {
      setError('Unable to load your joined sessions');
      rethrow;
    } finally {
      _isLoadingJoinedSessions = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreJoinedSessions(String uid) async {
    if (_isLoadingMoreJoinedSessions || !_hasMoreJoinedSessions) {
      return;
    }
    if (uid.trim().isEmpty || _joinedSessionsUid != uid) {
      await loadJoinedSessions(uid);
      return;
    }

    _isLoadingMoreJoinedSessions = true;
    notifyListeners();

    try {
      final nextPage = await _service.loadJoinedSessionsPage(
        uid: uid,
        cursorState: _joinedSessionsCursorState,
      );

      final merged = <String, SessionModel>{
        for (final session in _joinedSessions) session.sessionId: session,
      };
      for (final session in nextPage.items) {
        merged[session.sessionId] = session;
      }

      _joinedSessions = merged.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      _joinedSessionsCursorState = nextPage.cursorState;
      _hasMoreJoinedSessions =
          nextPage.cursorState.hasMorePartner ||
          nextPage.cursorState.hasMoreParticipant;
      setError(null);
    } catch (e) {
      setError('Unable to load more joined sessions');
    } finally {
      _isLoadingMoreJoinedSessions = false;
      notifyListeners();
    }
  }

  Future<bool> createSession(SessionModel session) async {
    return runWithLoading<bool>(
      debugLabel: 'SessionProvider.createSession',
      errorMessage: 'Unable to create session',
      action: () async {
        final created = await _service.createSession(session);
        _sessions.insert(0, created);
        return true;
      },
    );
  }

  Future<bool> cancelSession(String sessionId) async {
    return runWithLoading<bool>(
      debugLabel: 'SessionProvider.cancelSession',
      errorMessage: 'Unable to cancel session',
      action: () async {
        final result = await _service.cancelSession(
          sessionId: sessionId,
          sessions: _sessions,
          mySessions: _mySessions,
          selectedSession: _selectedSession,
        );
        _sessions = result.sessions;
        _mySessions = result.mySessions;
        _selectedSession = result.selectedSession;
        return true;
      },
    );
  }

  Future<SessionModel?> getSessionById(String sessionId) {
    return _service.getSessionById(sessionId);
  }

  Stream<SessionModel?> streamSession(String sessionId) {
    return _service.streamSession(sessionId);
  }

  Future<bool> updateSession(SessionModel session) async {
    if (session.maxParticipants < session.participantUids.length) {
      setError('Max participants cannot be less than current joined count');
      return false;
    }

    return runWithLoading<bool>(
      debugLabel: 'SessionProvider.updateSession',
      errorMessage: 'Unable to update session',
      action: () async {
        final result = await _service.updateSession(
          session: session,
          sessions: _sessions,
          mySessions: _mySessions,
          selectedSession: _selectedSession,
        );
        _sessions = result.sessions;
        _mySessions = result.mySessions;
        _selectedSession = result.selectedSession;
        return true;
      },
    );
  }

  void selectSession(SessionModel session) {
    _selectedSession = session;
    notifyListeners();
  }

  @override
  void clearError() {
    setError(null);
  }
}
