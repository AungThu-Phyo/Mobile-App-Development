import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

class FeedbackRepository {
  final CollectionReference<Map<String, dynamic>> _feedbackRef =
      FirebaseFirestore.instance.collection('feedback');

  /// Creates a new feedback document.
  Future<void> create(FeedbackModel feedback) async {
    try {
      await _feedbackRef.doc(feedback.feedbackId).set(feedback.toMap());
    } catch (e) {
      throw Exception('Failed to create feedback: $e');
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
    } catch (e) {
      throw Exception('Failed to get feedback: $e');
    }
  }

  /// Updates an existing feedback document.
  Future<void> update(FeedbackModel feedback) async {
    try {
      await _feedbackRef.doc(feedback.feedbackId).update(feedback.toMap());
    } catch (e) {
      throw Exception('Failed to update feedback: $e');
    }
  }

  /// Deletes a feedback document.
  Future<void> delete(String feedbackId) async {
    try {
      await _feedbackRef.doc(feedbackId).delete();
    } catch (e) {
      throw Exception('Failed to delete feedback: $e');
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

  /// Returns all feedback where the user is the reviewee.
  Future<List<FeedbackModel>> getFeedbackForUser(String uid) async {
    try {
      final snapshot = await _feedbackRef
          .where('revieweeUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => FeedbackModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get feedback for user: $e');
    }
  }

  /// Calculates average rating for a user from all received feedback.
  /// Returns 0.0 if no feedback exists.
  Future<double> calculateAverageRating(String uid) async {
    try {
      final feedbackList = await getFeedbackForUser(uid);
      if (feedbackList.isEmpty) return 0.0;
      final total =
          feedbackList.fold<int>(0, (sum, fb) => sum + fb.rating);
      return total / feedbackList.length;
    } catch (e) {
      throw Exception('Failed to calculate average rating: $e');
    }
  }
}
