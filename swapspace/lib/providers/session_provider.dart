import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../providers/notification_provider.dart';
import '../repositories/session_repository.dart';

class SessionProvider extends ChangeNotifier {
  final SessionRepository _repo = SessionRepository();
  NotificationProvider? _notificationProvider;

  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  List<SessionModel> _sessions = [];
  List<SessionModel> _mySessions = [];
  SessionModel? _selectedSession;
  String _selectedFilter = 'All';
  double _userRating = 0.0;
  bool _isLoading = false;
  String? _error;

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
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<SessionModel> get filteredSessions {
    var result = _sessions.where((s) =>
        s.creatorUid == _currentUid ||
        s.minRating <= _userRating ||
        s.minRating == 0).toList();
    if (_selectedFilter != 'All') {
      result = result
          .where((s) => s.activityType.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }
    return result;
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> loadOpenSessions() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _sessions = await _repo.getActiveSessions();

      // Auto-finish expired sessions
      final now = DateTime.now();
      for (int i = _sessions.length - 1; i >= 0; i--) {
        final s = _sessions[i];
        final endTime = s.date.add(Duration(minutes: s.durationMinutes));
        if (now.isAfter(endTime)) {
          final completed = s.copyWith(
            status: 'completed',
            isActive: false,
            updatedAt: now,
          );
          _repo.update(completed);
          _sessions.removeAt(i);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load sessions';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMySessions(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _mySessions = await _repo.getSessionsByUser(uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load your sessions';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSession(SessionModel session) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repo.create(session);
      _sessions.insert(0, session);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create session';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelSession(String sessionId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final session = _sessions.firstWhere(
        (s) => s.sessionId == sessionId,
        orElse: () => SessionModel.empty(),
      );
      if (session.sessionId.isEmpty) {
        _error = 'Session not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updated = session.copyWith(
        status: 'cancelled',
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await _repo.update(updated);

      _sessions.removeWhere((s) => s.sessionId == sessionId);
      if (_selectedSession?.sessionId == sessionId) {
        _selectedSession = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to cancel session';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSession(SessionModel session) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updated = session.copyWith(updatedAt: DateTime.now());
      await _repo.update(updated);

      final idx = _sessions.indexWhere((s) => s.sessionId == updated.sessionId);
      if (idx != -1) _sessions[idx] = updated;

      final myIdx = _mySessions.indexWhere((s) => s.sessionId == updated.sessionId);
      if (myIdx != -1) _mySessions[myIdx] = updated;

      if (_selectedSession?.sessionId == updated.sessionId) {
        _selectedSession = updated;
      }

      // Notify all joined participants (except the creator) about the update
      for (final uid in updated.participantUids) {
        if (uid != updated.creatorUid) {
          _notificationProvider?.sendNotification(
            recipientUid: uid,
            senderUid: updated.creatorUid,
            senderName: updated.creatorName,
            sessionId: updated.sessionId,
            sessionTitle: updated.title,
            type: 'session_updated',
            message: '${updated.creatorName} updated the session ${updated.title}',
          );
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update session';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void selectSession(SessionModel session) {
    _selectedSession = session;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
