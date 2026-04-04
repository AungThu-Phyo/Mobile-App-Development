import 'base_state_provider.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';

class FeedbackProvider extends BaseStateProvider {
  final FeedbackService _service;

  FeedbackProvider({required FeedbackService service}) : _service = service;

  Future<bool> submitFeedback(FeedbackModel feedback) async {
    return runWithLoading<bool>(
      debugLabel: 'FeedbackProvider.submitFeedback',
      errorMessage: 'Unable to submit feedback',
      action: () async {
        await _service.submitFeedback(feedback);
        return true;
      },
    );
  }

  Future<bool> hasFeedbackSubmitted(String sessionId, String reviewerUid) async {
    return runWithLoading<bool>(
      debugLabel: 'FeedbackProvider.hasFeedbackSubmitted',
      errorMessage: 'Unable to check feedback status',
      action: () => _service.hasFeedbackSubmitted(sessionId, reviewerUid),
    );
  }

  Future<bool> hasAllFeedbackSubmitted(
    String sessionId,
    String reviewerUid,
    int expectedCount,
  ) async {
    return runWithLoading<bool>(
      debugLabel: 'FeedbackProvider.hasAllFeedbackSubmitted',
      errorMessage: 'Unable to check feedback status',
      action: () => _service.hasAllFeedbackSubmitted(
        sessionId,
        reviewerUid,
        expectedCount,
      ),
    );
  }

  Future<List<FeedbackModel>> getFeedbackForUser(String uid) async {
    return runWithLoading<List<FeedbackModel>>(
      debugLabel: 'FeedbackProvider.getFeedbackForUser',
      errorMessage: 'Unable to load feedback',
      action: () => _service.getFeedbackForUser(uid),
    );
  }

  Future<List<FeedbackModel>> getFeedbackForSession(String sessionId) async {
    return runWithLoading<List<FeedbackModel>>(
      debugLabel: 'FeedbackProvider.getFeedbackForSession',
      errorMessage: 'Unable to load feedback',
      action: () => _service.getFeedbackForSession(sessionId),
    );
  }

  Future<double> calculateAverageRating(String uid) async {
    return runWithLoading<double>(
      debugLabel: 'FeedbackProvider.calculateAverageRating',
      errorMessage: 'Unable to calculate rating',
      action: () => _service.calculateAverageRating(uid),
    );
  }

  Future<bool> updateFeedback(FeedbackModel feedback) async {
    return runWithLoading<bool>(
      debugLabel: 'FeedbackProvider.updateFeedback',
      errorMessage: 'Unable to update feedback',
      action: () async {
        await _service.updateFeedback(feedback);
        return true;
      },
    );
  }

  Future<bool> deleteFeedback(String feedbackId) async {
    return runWithLoading<bool>(
      debugLabel: 'FeedbackProvider.deleteFeedback',
      errorMessage: 'Unable to delete feedback',
      action: () async {
        await _service.deleteFeedback(feedbackId);
        return true;
      },
    );
  }
}