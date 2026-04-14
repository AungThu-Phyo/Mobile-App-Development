import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/repository_exception.dart';
import '../models/session_model.dart';
import 'paginated_query_result.dart';

class SessionRepository {
  static const int defaultPageSize = 20;
  static const int _whereInBatchSize = 10;

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

  /// Fetches multiple sessions by IDs in batched whereIn queries.
  Future<Map<String, SessionModel>> getByIds(List<String> sessionIds) async {
    try {
      final normalizedIds =
          sessionIds.where((id) => id.trim().isNotEmpty).toSet().toList();
      if (normalizedIds.isEmpty) return {};

      final result = <String, SessionModel>{};
      for (final batch in _chunks(normalizedIds, _whereInBatchSize)) {
        final snapshot = await _sessionsRef
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final session = SessionModel.fromMap(data);
          final key = session.sessionId.isNotEmpty ? session.sessionId : doc.id;
          result[key] =
              session.sessionId.isNotEmpty ? session : session.copyWith(sessionId: doc.id);
        }
      }

      return result;
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load sessions by IDs',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load sessions by IDs',
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
          .orderBy('date')
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
          .orderBy('date', descending: true)
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
          .orderBy('date', descending: true)
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
          .orderBy('date', descending: true)
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

  /// Paginates visible sessions by status using server-side ordering and cursor.
  Future<PaginatedQueryResult<SessionModel>> getSessionsByStatusPage({
    required String status,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    try {
      var query = _visibleSessionsQuery()
          .where('status', isEqualTo: status)
          .orderBy('date')
          .limit(pageSize + 1);

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > pageSize;
      final pageDocs = hasMore ? docs.take(pageSize).toList() : docs;

      return PaginatedQueryResult<SessionModel>(
        items: pageDocs.map((doc) => SessionModel.fromMap(doc.data())).toList(),
        lastDocument: pageDocs.isNotEmpty ? pageDocs.last : null,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load paginated sessions',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load paginated sessions',
        cause: e,
      );
    }
  }

  /// Paginates creator sessions by newest first.
  Future<PaginatedQueryResult<SessionModel>> getSessionsByCreatorPage({
    required String uid,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    return _getUserSessionPage(
      filterField: 'creatorUid',
      uid: uid,
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      errorMessage: 'Unable to load paginated created sessions',
    );
  }

  /// Paginates partner sessions by newest first.
  Future<PaginatedQueryResult<SessionModel>> getSessionsByPartnerPage({
    required String uid,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    return _getUserSessionPage(
      filterField: 'partnerUid',
      uid: uid,
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      errorMessage: 'Unable to load paginated partner sessions',
    );
  }

  /// Paginates participant sessions by newest first.
  Future<PaginatedQueryResult<SessionModel>> getSessionsByParticipantPage({
    required String uid,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    try {
      var query = _sessionsRef
          .where('participantUids', arrayContains: uid)
          .orderBy('date', descending: true)
          .limit(pageSize + 1);

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > pageSize;
      final pageDocs = hasMore ? docs.take(pageSize).toList() : docs;

      return PaginatedQueryResult<SessionModel>(
        items: pageDocs.map((doc) => SessionModel.fromMap(doc.data())).toList(),
        lastDocument: pageDocs.isNotEmpty ? pageDocs.last : null,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load paginated joined sessions',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load paginated joined sessions',
        cause: e,
      );
    }
  }

  Future<PaginatedQueryResult<SessionModel>> _getUserSessionPage({
    required String filterField,
    required String uid,
    required int pageSize,
    required QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    required String errorMessage,
  }) async {
    try {
      var query = _sessionsRef
          .where(filterField, isEqualTo: uid)
          .orderBy('date', descending: true)
          .limit(pageSize + 1);

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > pageSize;
      final pageDocs = hasMore ? docs.take(pageSize).toList() : docs;

      return PaginatedQueryResult<SessionModel>(
        items: pageDocs.map((doc) => SessionModel.fromMap(doc.data())).toList(),
        lastDocument: pageDocs.isNotEmpty ? pageDocs.last : null,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: errorMessage,
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: errorMessage,
        cause: e,
      );
    }
  }

  List<List<String>> _chunks(List<String> values, int size) {
    final chunks = <List<String>>[];
    for (var i = 0; i < values.length; i += size) {
      final end = (i + size < values.length) ? i + size : values.length;
      chunks.add(values.sublist(i, end));
    }
    return chunks;
  }
}
