import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/repository_exception.dart';
import '../models/feedback_model.dart';
import 'paginated_query_result.dart';

class FeedbackRepository {
  static const int defaultPageSize = 20;

  final CollectionReference<Map<String, dynamic>> _feedbackRef =
      FirebaseFirestore.instance.collection('feedback');

  /// Creates a new feedback document.
  Future<void> create(FeedbackModel feedback) async {
    try {
      await _feedbackRef.doc(feedback.feedbackId).set(feedback.toMap());
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to create feedback',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to create feedback',
        cause: e,
      );
    }
  }

  /// Fetches a feedback by ID. Returns null if not found.
  Future<FeedbackModel?> getById(String feedbackId) async {
    try {
      final doc = await _feedbackRef.doc(feedbackId).get();
      if (doc.exists && doc.data() != null) {
        return FeedbackModel.fromMap(doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load feedback',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load feedback',
        cause: e,
      );
    }
  }

  /// Updates an existing feedback document.
  Future<void> update(FeedbackModel feedback) async {
    try {
      await _feedbackRef.doc(feedback.feedbackId).update(feedback.toMap());
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to update feedback',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to update feedback',
        cause: e,
      );
    }
  }

  /// Deletes a feedback document.
  Future<void> delete(String feedbackId) async {
    try {
      await _feedbackRef.doc(feedbackId).delete();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to delete feedback',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to delete feedback',
        cause: e,
      );
    }
  }

  /// Real-time stream of a single feedback document.
  Stream<FeedbackModel?> stream(String feedbackId) {
    return _feedbackRef.doc(feedbackId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return FeedbackModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Returns raw feedback where the user is the reviewee.
  Future<List<FeedbackModel>> getFeedbackForUser(String uid) async {
    try {
      final snapshot = await _feedbackRef
          .where('revieweeUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FeedbackModel.fromMap(doc.data()))
          .toList(); // ❌ no sorting here
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load user feedback',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load user feedback',
        cause: e,
      );
    }
  }

  /// Returns raw feedback entries for a session.
  Future<List<FeedbackModel>> getFeedbackForSession(String sessionId) async {
    try {
      final snapshot = await _feedbackRef
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FeedbackModel.fromMap(doc.data()))
          .toList(); // ❌ no sorting here
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load session feedback',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load session feedback',
        cause: e,
      );
    }
  }

  /// Query feedback for a session by a specific reviewer.
  Future<List<FeedbackModel>> queryBySessionAndReviewer(
      String sessionId, String reviewerUid) async {
    try {
      final snapshot = await _feedbackRef
          .where('sessionId', isEqualTo: sessionId)
          .where('reviewerUid', isEqualTo: reviewerUid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FeedbackModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to query feedback',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to query feedback',
        cause: e,
      );
    }
  }

  Future<PaginatedQueryResult<FeedbackModel>> getFeedbackForUserPage({
    required String uid,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    return _getOrderedPage(
      baseQuery: _feedbackRef.where('revieweeUid', isEqualTo: uid),
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      errorMessage: 'Unable to load paginated user feedback',
    );
  }

  Future<PaginatedQueryResult<FeedbackModel>> getFeedbackForSessionPage({
    required String sessionId,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    return _getOrderedPage(
      baseQuery: _feedbackRef.where('sessionId', isEqualTo: sessionId),
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      errorMessage: 'Unable to load paginated session feedback',
    );
  }

  Future<PaginatedQueryResult<FeedbackModel>> queryBySessionAndReviewerPage({
    required String sessionId,
    required String reviewerUid,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    return _getOrderedPage(
      baseQuery: _feedbackRef
          .where('sessionId', isEqualTo: sessionId)
          .where('reviewerUid', isEqualTo: reviewerUid),
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      errorMessage: 'Unable to load paginated reviewer feedback',
    );
  }

  Future<PaginatedQueryResult<FeedbackModel>> _getOrderedPage({
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

      return PaginatedQueryResult<FeedbackModel>(
        items: pageDocs
            .map((doc) => FeedbackModel.fromMap(doc.data()))
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