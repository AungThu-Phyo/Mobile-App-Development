import 'base_state_provider.dart';
import '../core/constants/session_constants.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';

class SessionProvider extends BaseStateProvider {
  final SessionService _service;

  SessionProvider({required SessionService service}) : _service = service;

  List<SessionModel> _sessions = [];
  List<SessionModel> _mySessions = [];
  SessionModel? _selectedSession;
  String _selectedFilter = SessionConstants.filterAll;
  double _userRating = 0.0;

  String _currentUid = '';

  void setUserRating(double rating) {
    _userRating = rating;
  }

  void setCurrentUid(String uid) {
    _currentUid = uid;
  }

  List<SessionModel> get sessions => _sessions;
  List<SessionModel> get mySessions => _mySessions;
  SessionModel? get selectedSession => _selectedSession;
  String get selectedFilter => _selectedFilter;

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
    _sessions = await runWithLoading<List<SessionModel>>(
      debugLabel: 'SessionProvider.loadOpenSessions',
      errorMessage: 'Unable to load sessions',
      action: () => _service.loadOpenSessions(),
    );
  }

  Future<void> loadMySessions(String uid) async {
    _mySessions = await runWithLoading<List<SessionModel>>(
      debugLabel: 'SessionProvider.loadMySessions',
      errorMessage: 'Unable to load your sessions',
      action: () => _service.loadMySessions(uid),
    );
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

  Future<bool> updateSession(SessionModel session) async {
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
