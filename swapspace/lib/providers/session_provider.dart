import 'package:flutter/material.dart';
import '../models/activity_session.dart';
import '../core/mock_data/mock_sessions.dart';

class SessionProvider extends ChangeNotifier {
  List<ActivitySession> _allSessions = [];
  String _selectedFilter = 'All Activities';

  String get selectedFilter => _selectedFilter;

  List<ActivitySession> get filteredSessions {
    if (_selectedFilter == 'All Activities') return _allSessions;
    return _allSessions.where((s) => s.activityType == _selectedFilter).toList();
  }

  void loadSessions() {
    _allSessions = mockSessions;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void addSession(ActivitySession session) {
    _allSessions.add(session);
    notifyListeners();
  }
}
