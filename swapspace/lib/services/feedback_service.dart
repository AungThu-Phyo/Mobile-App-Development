import '../models/feedback_model.dart';
import '../models/user_model.dart';
import '../core/constants/session_constants.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/user_repository.dart';

class FeedbackService {
  final FeedbackRepository _repository;
  final UserRepository _userRepository;
  final SessionRepository _sessionRepository;

  FeedbackService({
    required FeedbackRepository repository,
    required UserRepository userRepository,
    required SessionRepository sessionRepository,
  })  : _repository = repository,
        _userRepository = userRepository,
        _sessionRepository = sessionRepository;

  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _repository.create(feedback);
    await _syncRevieweeStats(feedback.revieweeUid);
  }

  Future<void> updateFeedback(FeedbackModel feedback) async {
    await _repository.update(feedback);
    await _syncRevieweeStats(feedback.revieweeUid);
  }

  Future<void> deleteFeedback(String feedbackId) async {
    final existing = await _repository.getById(feedbackId);
    if (existing == null) {
      throw StateError('feedback-not-found');
    }

    await _repository.delete(feedbackId);
    await _syncRevieweeStats(existing.revieweeUid);
  }

  Future<double> calculateAverageRating(String uid) async {
    final feedbackList = await _repository.getFeedbackForUser(uid);
    return _calculateBlendedRating(feedbackList);
  }

  Future<List<FeedbackModel>> getFeedbackForUser(String uid) async {
    final list = await _repository.getFeedbackForUser(uid);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

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

  Future<void> _syncRevieweeStats(String revieweeUid) async {
    if (revieweeUid.trim().isEmpty) return;

    final feedbackList = await _repository.getFeedbackForUser(revieweeUid);
    final rating = _calculateBlendedRating(feedbackList);
    final totalSessions = await _calculateCompletedSessionCount(revieweeUid);

    final existing = await _userRepository.getUser(revieweeUid);
    if (existing != null) {
      final updated = existing.copyWith(
        rating: rating,
        totalSessions: totalSessions,
      );
      await _userRepository.updateUser(updated);
      await _userRepository.upsertPublicProfile(updated);
      return;
    }

    final publicUser = await _userRepository.getPublicUser(revieweeUid);
    if (publicUser != null) {
      final now = DateTime.now();
      final restored = publicUser.copyWith(
        rating: rating,
        totalSessions: totalSessions,
        lastSeen: now,
      );
      await _userRepository.createUser(restored);
      await _userRepository.upsertPublicProfile(restored);
      return;
    }

    final now = DateTime.now();
    final fallback = UserModel(
      uid: revieweeUid,
      name: '',
      email: '',
      rating: rating,
      totalSessions: totalSessions,
      createdAt: now,
      lastSeen: now,
    );
    await _userRepository.createUser(fallback);
    await _userRepository.upsertPublicProfile(fallback);
  }

  Future<int> _calculateCompletedSessionCount(String uid) async {
    final createdFuture = _sessionRepository.getSessionsByCreator(uid);
    final partneredFuture = _sessionRepository.getSessionsByPartner(uid);
    final joinedFuture = _sessionRepository.getSessionsByParticipant(uid);

    final results = await Future.wait([
      createdFuture,
      partneredFuture,
      joinedFuture,
    ]);

    final completedSessionIds = <String>{};
    for (final sessions in results) {
      for (final session in sessions) {
        if (session.status == SessionStatus.completed &&
            session.sessionId.isNotEmpty) {
          completedSessionIds.add(session.sessionId);
        }
      }
    }

    return completedSessionIds.length;
  }

  double _calculateBlendedRating(List<FeedbackModel> feedbackList) {
    if (feedbackList.isEmpty) return 0.0;

    final groupedBySession = <String, List<FeedbackModel>>{};
    for (final feedback in feedbackList) {
      if (feedback.sessionId.isEmpty || feedback.rating <= 0) {
        continue;
      }
      groupedBySession.putIfAbsent(feedback.sessionId, () => []).add(feedback);
    }

    if (groupedBySession.isEmpty) return 0.0;

    final netSessionFeedback = <_SessionNetFeedback>[];
    for (final entry in groupedBySession.entries) {
      final ratings = entry.value.map((f) => f.rating).toList();
      if (ratings.isEmpty) continue;

      final totalRating = ratings.fold<int>(0, (sum, value) => sum + value);
      final sessionNetAverage = totalRating / ratings.length;
      final latestFeedbackAt = entry.value
          .map((f) => f.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      netSessionFeedback.add(
        _SessionNetFeedback(
          averageRating: sessionNetAverage,
          referenceTime: latestFeedbackAt,
        ),
      );
    }

    if (netSessionFeedback.isEmpty) return 0.0;

    netSessionFeedback.sort((a, b) => a.referenceTime.compareTo(b.referenceTime));

    var finalRating = 0.0;
    for (final sessionFeedback in netSessionFeedback) {
      if (finalRating == 0.0) {
        finalRating = sessionFeedback.averageRating;
      } else {
        finalRating = (finalRating + sessionFeedback.averageRating) / 2;
      }
    }

    return double.parse(finalRating.toStringAsFixed(2));
  }

}

class _SessionNetFeedback {
  final double averageRating;
  final DateTime referenceTime;

  const _SessionNetFeedback({
    required this.averageRating,
    required this.referenceTime,
  });
}
