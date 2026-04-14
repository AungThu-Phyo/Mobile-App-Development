import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/session_constants.dart';
import '../core/errors/repository_exception.dart';
import '../models/join_request_model.dart';
import 'paginated_query_result.dart';

class JoinRequestRepository {
  static const int defaultPageSize = 20;

  final FirebaseFirestore _db;
  final CollectionReference<Map<String, dynamic>> _requestsRef;

  JoinRequestRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        _requestsRef = (firestore ?? FirebaseFirestore.instance)
            .collection('joinRequests');

  Future<T> runTransaction<T>(
    Future<T> Function(Transaction tx) handler,
  ) {
    return _db.runTransaction((tx) => handler(tx));
  }

  String createRequestId() {
    return _requestsRef.doc().id;
  }

  /// Creates a new join request document.
  Future<void> create(JoinRequestModel request) async {
    try {
      await _requestsRef.doc(request.requestId).set(request.toMap());
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to create join request',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to create join request',
        cause: e,
      );
    }
  }

  /// Fetches a join request by ID. Returns null if not found.
  Future<JoinRequestModel?> getById(String requestId) async {
    try {
      final doc = await _requestsRef.doc(requestId).get();
      if (doc.exists && doc.data() != null) {
        return JoinRequestModel.fromMap(doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load join request',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load join request',
        cause: e,
      );
    }
  }

  /// Updates an existing join request document.
  Future<void> update(JoinRequestModel request) async {
    try {
      await _requestsRef.doc(request.requestId).update(request.toMap());
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to update join request',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to update join request',
        cause: e,
      );
    }
  }

  /// Deletes a join request document.
  Future<void> delete(String requestId) async {
    try {
      await _requestsRef.doc(requestId).delete();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to delete join request',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to delete join request',
        cause: e,
      );
    }
  }

  /// Real-time stream of a single join request.
  Stream<JoinRequestModel?> stream(String requestId) {
    return _requestsRef.doc(requestId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return JoinRequestModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Raw stream of requests for a creator (NO filtering).
  Stream<List<JoinRequestModel>> streamForCreator(String uid) {
    return _requestsRef
        .where('creatorUid', isEqualTo: uid)
        .where('status', isEqualTo: JoinRequestStatus.pending)
        .orderBy('createdAt', descending: true)
        .limit(defaultPageSize)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JoinRequestModel.fromMap(doc.data()))
              .toList();
        });
  }

  Future<JoinRequestModel?> getByIdTx(Transaction tx, String requestId) async {
    final doc = await tx.get(_requestsRef.doc(requestId));
    if (doc.exists && doc.data() != null) {
      return JoinRequestModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateStatusTx({
    required Transaction tx,
    required String requestId,
    required String status,
    required DateTime updatedAt,
  }) async {
    tx.update(_requestsRef.doc(requestId), {
      'status': status,
      'updatedAt': Timestamp.fromDate(updatedAt),
    });
  }

  Future<List<JoinRequestModel>> getPendingForSession(String sessionId) async {
    final snapshot = await _requestsRef
        .where('sessionId', isEqualTo: sessionId)
        .where('status', isEqualTo: JoinRequestStatus.pending)
      .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => JoinRequestModel.fromMap(doc.data()))
        .toList();
  }

  /// Raw requests for a session (NO filtering).
  Future<List<JoinRequestModel>> getForSession(String sessionId) async {
    try {
      final snapshot = await _requestsRef
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => JoinRequestModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load session requests',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load session requests',
        cause: e,
      );
    }
  }

  /// Raw requests from a user (NO sorting).
  Future<List<JoinRequestModel>> getFromUser(String uid) async {
    try {
      final snapshot = await _requestsRef
          .where('requesterUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => JoinRequestModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load outgoing requests',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load outgoing requests',
        cause: e,
      );
    }
  }

  /// Raw requests to a creator (NO filtering).
  Future<List<JoinRequestModel>> getForCreator(String uid) async {
    try {
      final snapshot = await _requestsRef
          .where('creatorUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => JoinRequestModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load incoming requests',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load incoming requests',
        cause: e,
      );
    }
  }

  Future<PaginatedQueryResult<JoinRequestModel>> getForCreatorPage({
    required String uid,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    return _getOrderedPage(
      baseQuery: _requestsRef.where('creatorUid', isEqualTo: uid),
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      errorMessage: 'Unable to load paginated incoming requests',
    );
  }

  Future<PaginatedQueryResult<JoinRequestModel>> getFromUserPage({
    required String uid,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    return _getOrderedPage(
      baseQuery: _requestsRef.where('requesterUid', isEqualTo: uid),
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      errorMessage: 'Unable to load paginated outgoing requests',
    );
  }

  Future<PaginatedQueryResult<JoinRequestModel>> getForSessionPage({
    required String sessionId,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    return _getOrderedPage(
      baseQuery: _requestsRef.where('sessionId', isEqualTo: sessionId),
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      errorMessage: 'Unable to load paginated session requests',
    );
  }

  Future<PaginatedQueryResult<JoinRequestModel>> getPendingForSessionPage({
    required String sessionId,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    return _getOrderedPage(
      baseQuery: _requestsRef
          .where('sessionId', isEqualTo: sessionId)
          .where('status', isEqualTo: JoinRequestStatus.pending),
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      errorMessage: 'Unable to load paginated pending session requests',
    );
  }

  Future<PaginatedQueryResult<JoinRequestModel>> getPendingForCreatorPage({
    required String uid,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    return _getOrderedPage(
      baseQuery: _requestsRef
          .where('creatorUid', isEqualTo: uid)
          .where('status', isEqualTo: JoinRequestStatus.pending),
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      errorMessage: 'Unable to load paginated pending incoming requests',
    );
  }

  Future<PaginatedQueryResult<JoinRequestModel>> _getOrderedPage({
    required Query<Map<String, dynamic>> baseQuery,
    required int pageSize,
    required QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
    required String errorMessage,
  }) async {
    try {
      var query = baseQuery
          .orderBy('createdAt', descending: true)
          .limit(pageSize + 1);

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > pageSize;
      final pageDocs = hasMore ? docs.take(pageSize).toList() : docs;

      return PaginatedQueryResult<JoinRequestModel>(
        items: pageDocs
            .map((doc) => JoinRequestModel.fromMap(doc.data()))
            .toList(),
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
}
