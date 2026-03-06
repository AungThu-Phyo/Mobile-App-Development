import 'package:flutter/foundation.dart';
import '../models/feedback_model.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/user_repository.dart';

class FeedbackProvider extends ChangeNotifier {
  final FeedbackRepository _feedbackRepo = FeedbackRepository();
  final UserRepository _userRepo = UserRepository();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Submit feedback, save to Firestore, and update the reviewee's rating.
  Future<bool> submitFeedback(FeedbackModel feedback) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Save feedback document
      await _feedbackRepo.create(feedback);

      // Recalculate average rating from ALL feedback for this reviewee
      final avgRating =
          await _feedbackRepo.calculateAverageRating(feedback.revieweeUid);

      // Count total feedback docs to get totalSessions
      final allFeedback =
          await _feedbackRepo.getFeedbackForUser(feedback.revieweeUid);

      // Update the reviewee's user document
      final user = await _userRepo.getUser(feedback.revieweeUid);
      if (user != null) {
        final updatedUser = user.copyWith(
          rating: avgRating,
          totalSessions: allFeedback.length,
        );
        await _userRepo.updateUser(updatedUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to submit feedback: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if the user already submitted feedback for this session.
  Future<bool> hasFeedbackSubmitted(String sessionId, String reviewerUid) async {
    try {
      final results = await _feedbackRepo.queryBySessionAndReviewer(
        sessionId,
        reviewerUid,
      );
      return results.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check if feedback has been submitted for ALL other participants.
  Future<bool> hasAllFeedbackSubmitted(
      String sessionId, String reviewerUid, int expectedCount) async {
    try {
      final results = await _feedbackRepo.queryBySessionAndReviewer(
        sessionId,
        reviewerUid,
      );
      return results.length >= expectedCount;
    } catch (_) {
      return false;
    }
  }

  /// Get all feedback received by a user.
  Future<List<FeedbackModel>> getFeedbackForUser(String uid) async {
    try {
      return await _feedbackRepo.getFeedbackForUser(uid);
    } catch (e) {
      _error = 'Failed to load feedback';
      return [];
    }
  }
}
