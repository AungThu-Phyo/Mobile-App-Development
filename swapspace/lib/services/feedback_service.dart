import '../models/feedback_model.dart';
import '../repositories/feedback_repository.dart';

class FeedbackService {
  final FeedbackRepository _repository;

  FeedbackService({required FeedbackRepository repository})
      : _repository = repository;

  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _repository.create(feedback);
  }

  Future<void> updateFeedback(FeedbackModel feedback) async {
    await _repository.update(feedback);
  }

  Future<void> deleteFeedback(String feedbackId) async {
    final existing = await _repository.getById(feedbackId);
    if (existing == null) {
      throw StateError('feedback-not-found');
    }

    await _repository.delete(feedbackId);
  }

  /// ✅ NOW calculated in service (NOT repository)
  Future<double> calculateAverageRating(String uid) async {
    final feedbackList = await _repository.getFeedbackForUser(uid);

    if (feedbackList.isEmpty) return 0.0;

    final total = feedbackList.fold<int>(0, (sum, fb) => sum + fb.rating);
    return total / feedbackList.length;
  }

  /// ✅ Sorting moved to service
  Future<List<FeedbackModel>> getFeedbackForUser(String uid) async {
    final list = await _repository.getFeedbackForUser(uid);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// ✅ Sorting moved to service
  Future<List<FeedbackModel>> getFeedbackForSession(String sessionId) async {
    final list = await _repository.getFeedbackForSession(sessionId);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<bool> hasFeedbackSubmitted(String sessionId, String reviewerUid) async {
    final results = await _repository.queryBySessionAndReviewer(
      sessionId,
      reviewerUid,
    );
    return results.isNotEmpty;
  }

  Future<bool> hasAllFeedbackSubmitted(
    String sessionId,
    String reviewerUid,
    int expectedCount,
  ) async {
    final results = await _repository.queryBySessionAndReviewer(
      sessionId,
      reviewerUid,
    );
    return results.length >= expectedCount;
  }

  Future<Map<String, dynamic>> buildUserFeedbackSummary(String uid) async {
    final feedback = await getFeedbackForUser(uid); // already sorted
    final average = await calculateAverageRating(uid);

    return {
      'averageRating': average,
      'totalFeedback': feedback.length,
      'items': feedback,
    };
  }

}