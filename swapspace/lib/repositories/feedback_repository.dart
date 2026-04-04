import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/repository_exception.dart';
import '../models/feedback_model.dart';

class FeedbackRepository {
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

}