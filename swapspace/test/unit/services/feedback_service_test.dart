import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swapspace/models/feedback_model.dart';
import 'package:swapspace/repositories/feedback_repository.dart';
import 'package:swapspace/repositories/session_repository.dart';
import 'package:swapspace/repositories/user_repository.dart';
import 'package:swapspace/services/feedback_service.dart';

class MockFeedbackRepository extends Mock implements FeedbackRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockSessionRepository extends Mock implements SessionRepository {}

FeedbackService _buildService({required MockFeedbackRepository feedbackRepo}) {
  return FeedbackService(
    repository: feedbackRepo,
    userRepository: MockUserRepository(),
    sessionRepository: MockSessionRepository(),
  );
}

void main() {
  test('calculateAverageRating returns 0 for empty list', () async {
    final repo = MockFeedbackRepository();
    when(() => repo.getFeedbackForUser('u1')).thenAnswer((_) async => []);

    final service = _buildService(feedbackRepo: repo);
    final average = await service.calculateAverageRating('u1');

    expect(average, 0.0);
  });

  test('calculateAverageRating computes mean', () async {
    final repo = MockFeedbackRepository();
    when(() => repo.getFeedbackForUser('u1')).thenAnswer(
      (_) async => [
        FeedbackModel(
          feedbackId: 'f1',
          sessionId: 's1',
          reviewerUid: 'r1',
          revieweeUid: 'u1',
          rating: 4,
          createdAt: DateTime(2024, 1, 1),
        ),
        FeedbackModel(
          feedbackId: 'f2',
          sessionId: 's1',
          reviewerUid: 'r2',
          revieweeUid: 'u1',
          rating: 2,
          createdAt: DateTime(2024, 1, 2),
        ),
      ],
    );

    final service = _buildService(feedbackRepo: repo);
    final average = await service.calculateAverageRating('u1');

    expect(average, 3.0);
  });

  test('getFeedbackForUser sorts by createdAt desc', () async {
    final repo = MockFeedbackRepository();
    final older = FeedbackModel(
      feedbackId: 'f1',
      sessionId: 's1',
      reviewerUid: 'r1',
      revieweeUid: 'u1',
      rating: 4,
      createdAt: DateTime(2024, 1, 1),
    );
    final newer = FeedbackModel(
      feedbackId: 'f2',
      sessionId: 's1',
      reviewerUid: 'r2',
      revieweeUid: 'u1',
      rating: 5,
      createdAt: DateTime(2024, 1, 2),
    );

    when(() => repo.getFeedbackForUser('u1')).thenAnswer(
      (_) async => [older, newer],
    );

    final service = _buildService(feedbackRepo: repo);
    final sorted = await service.getFeedbackForUser('u1');

    expect(sorted.first.feedbackId, 'f2');
  });

  test('deleteFeedback throws when missing', () async {
    final repo = MockFeedbackRepository();
    when(() => repo.getById('missing')).thenAnswer((_) async => null);

    final service = _buildService(feedbackRepo: repo);

    expect(
      () => service.deleteFeedback('missing'),
      throwsA(isA<StateError>()),
    );
  });

  test('hasFeedbackSubmitted returns true when repository has a result', () async {
    final repo = MockFeedbackRepository();
    when(
      () => repo.queryBySessionAndReviewer('s1', 'u1'),
    ).thenAnswer(
      (_) async => [
        FeedbackModel(
          feedbackId: 'f1',
          sessionId: 's1',
          reviewerUid: 'u1',
          revieweeUid: 'u2',
          rating: 5,
          createdAt: DateTime(2024, 1, 1),
        ),
      ],
    );

    final service = _buildService(feedbackRepo: repo);
    final result = await service.hasFeedbackSubmitted('s1', 'u1');

    expect(result, isTrue);
  });

  test('hasAllFeedbackSubmitted checks expected count threshold', () async {
    final repo = MockFeedbackRepository();
    when(
      () => repo.queryBySessionAndReviewer('s1', 'u1'),
    ).thenAnswer(
      (_) async => [
        FeedbackModel(
          feedbackId: 'f1',
          sessionId: 's1',
          reviewerUid: 'u1',
          revieweeUid: 'u2',
          rating: 5,
          createdAt: DateTime(2024, 1, 1),
        ),
      ],
    );

    final service = _buildService(feedbackRepo: repo);

    expect(await service.hasAllFeedbackSubmitted('s1', 'u1', 1), isTrue);
    expect(await service.hasAllFeedbackSubmitted('s1', 'u1', 2), isFalse);
  });

  test('getFeedbackForSession sorts by createdAt desc', () async {
    final repo = MockFeedbackRepository();
    final older = FeedbackModel(
      feedbackId: 'f1',
      sessionId: 's1',
      reviewerUid: 'r1',
      revieweeUid: 'u1',
      rating: 4,
      createdAt: DateTime(2024, 1, 1),
    );
    final newer = FeedbackModel(
      feedbackId: 'f2',
      sessionId: 's1',
      reviewerUid: 'r2',
      revieweeUid: 'u1',
      rating: 5,
      createdAt: DateTime(2024, 1, 2),
    );

    when(() => repo.getFeedbackForSession('s1')).thenAnswer(
      (_) async => [older, newer],
    );

    final service = _buildService(feedbackRepo: repo);
    final sorted = await service.getFeedbackForSession('s1');

    expect(sorted.first.feedbackId, 'f2');
  });
}
