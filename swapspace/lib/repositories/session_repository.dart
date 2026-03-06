import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_model.dart';

class SessionRepository {
  final CollectionReference<Map<String, dynamic>> _sessionsRef =
      FirebaseFirestore.instance.collection('sessions');

  /// Creates a new session document.
  Future<void> create(SessionModel session) async {
    try {
      await _sessionsRef.doc(session.sessionId).set(session.toMap());
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  /// Fetches a session by ID. Returns null if not found.
  Future<SessionModel?> getById(String sessionId) async {
    try {
      final doc = await _sessionsRef.doc(sessionId).get();
      if (doc.exists && doc.data() != null) {
        return SessionModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  /// Updates an existing session document.
  Future<void> update(SessionModel session) async {
    try {
      await _sessionsRef.doc(session.sessionId).update(session.toMap());
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  /// Deletes a session document.
  Future<void> delete(String sessionId) async {
    try {
      await _sessionsRef.doc(sessionId).delete();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  /// Real-time stream of a single session.
  Stream<SessionModel?> stream(String sessionId) {
    return _sessionsRef.doc(sessionId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return SessionModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Returns all open & active sessions, ordered by date ascending.
  Future<List<SessionModel>> getOpenSessions() async {
    try {
      final snapshot = await _sessionsRef
          .where('status', isEqualTo: 'open')
          .get();
      final sessions = snapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data()))
          .where((s) => s.isActive)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return sessions;
    } catch (e) {
      throw Exception('Failed to get open sessions: $e');
    }
  }

  /// Returns all active sessions (open + matched), for home feed.
  Future<List<SessionModel>> getActiveSessions() async {
    try {
      final openSnap = await _sessionsRef
          .where('status', isEqualTo: 'open')
          .get();
      final matchedSnap = await _sessionsRef
          .where('status', isEqualTo: 'matched')
          .get();
      final Map<String, SessionModel> merged = {};
      for (final doc in openSnap.docs) {
        final s = SessionModel.fromMap(doc.data());
        if (s.isActive) merged[s.sessionId] = s;
      }
      for (final doc in matchedSnap.docs) {
        final s = SessionModel.fromMap(doc.data());
        if (s.isActive) merged[s.sessionId] = s;
      }
      final sessions = merged.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return sessions;
    } catch (e) {
      throw Exception('Failed to get active sessions: $e');
    }
  }

  /// Returns open sessions filtered by activity type.
  Future<List<SessionModel>> getSessionsByActivity(String activityType) async {
    try {
      final snapshot = await _sessionsRef
          .where('status', isEqualTo: 'open')
          .get();
      final sessions = snapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data()))
          .where((s) => s.isActive && s.activityType == activityType)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return sessions;
    } catch (e) {
      throw Exception('Failed to get sessions by activity: $e');
    }
  }

  /// Returns all sessions where the user is creator or partner.
  Future<List<SessionModel>> getSessionsByUser(String uid) async {
    try {
      // Firestore doesn't support OR queries across fields in a single query,
      // so we run three queries and merge results.
      final creatorSnapshot = await _sessionsRef
          .where('creatorUid', isEqualTo: uid)
          .get();
      final partnerSnapshot = await _sessionsRef
          .where('partnerUid', isEqualTo: uid)
          .get();
      final participantSnapshot = await _sessionsRef
          .where('participantUids', arrayContains: uid)
          .get();

      final Map<String, SessionModel> merged = {};
      for (final doc in creatorSnapshot.docs) {
        final session = SessionModel.fromMap(doc.data());
        merged[session.sessionId] = session;
      }
      for (final doc in partnerSnapshot.docs) {
        final session = SessionModel.fromMap(doc.data());
        merged[session.sessionId] = session;
      }
      for (final doc in participantSnapshot.docs) {
        final session = SessionModel.fromMap(doc.data());
        merged[session.sessionId] = session;
      }

      final sessions = merged.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return sessions;
    } catch (e) {
      throw Exception('Failed to get sessions by user: $e');
    }
  }
}
