import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/repository_exception.dart';
import '../models/session_model.dart';

class SessionRepository {
  final CollectionReference<Map<String, dynamic>> _sessionsRef =
      FirebaseFirestore.instance.collection('sessions');

  Query<Map<String, dynamic>> _visibleSessionsQuery() {
    return _sessionsRef
        .where('isActive', isEqualTo: true)
        .where('date', isGreaterThan: Timestamp.now());
  }

  Future<SessionModel?> getByIdTx(Transaction tx, String sessionId) async {
    final doc = await tx.get(_sessionsRef.doc(sessionId));
    if (doc.exists && doc.data() != null) {
      return SessionModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateTx(Transaction tx, SessionModel session) async {
    tx.update(_sessionsRef.doc(session.sessionId), session.toMap());
  }

  /// Creates a new session document.
  Future<void> create(SessionModel session) async {
    try {
      await _sessionsRef.doc(session.sessionId).set(session.toMap());
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to create session',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to create session',
        cause: e,
      );
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
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load session',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load session',
        cause: e,
      );
    }
  }

  /// Updates an existing session document.
  Future<void> update(SessionModel session) async {
    try {
      await _sessionsRef.doc(session.sessionId).update(session.toMap());
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to update session',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to update session',
        cause: e,
      );
    }
  }

  /// Deletes a session document.
  Future<void> delete(String sessionId) async {
    try {
      await _sessionsRef.doc(sessionId).delete();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to delete session',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to delete session',
        cause: e,
      );
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

  /// Returns raw sessions by status (no filtering, no sorting).
  Future<List<SessionModel>> getSessionsByStatus(String status) async {
    try {
      final snapshot = await _visibleSessionsQuery()
          .where('status', isEqualTo: status)
          .get();
      return snapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load sessions',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load sessions',
        cause: e,
      );
    }
  }

  /// Returns raw sessions where user is creator.
  Future<List<SessionModel>> getSessionsByCreator(String uid) async {
    try {
      final snapshot = await _sessionsRef
          .where('creatorUid', isEqualTo: uid)
          .get();
      return snapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load created sessions',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load created sessions',
        cause: e,
      );
    }
  }

  /// Returns raw sessions where user is partner.
  Future<List<SessionModel>> getSessionsByPartner(String uid) async {
    try {
      final snapshot = await _sessionsRef
          .where('partnerUid', isEqualTo: uid)
          .get();
      return snapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load partner sessions',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load partner sessions',
        cause: e,
      );
    }
  }

  /// Returns raw sessions where user is participant.
  Future<List<SessionModel>> getSessionsByParticipant(String uid) async {
    try {
      final snapshot = await _sessionsRef
          .where('participantUids', arrayContains: uid)
          .get();
      return snapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load joined sessions',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load joined sessions',
        cause: e,
      );
    }
  }
}
