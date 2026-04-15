import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swapspace/models/feedback_model.dart';
import 'package:swapspace/models/user_model.dart';
import 'package:swapspace/repositories/feedback_repository.dart';
import 'package:swapspace/repositories/session_repository.dart';
import 'package:swapspace/repositories/user_repository.dart';
import 'package:swapspace/services/auth_service.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockFeedbackRepository extends Mock implements FeedbackRepository {}
class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserModel.empty());
  });

  test('isAllowedSchoolEmail returns true for @lamduan.mfu.ac.th', () {
    expect(
      AuthService.isAllowedSchoolEmail('6731503046@lamduan.mfu.ac.th'),
      isTrue,
    );
  });

  test('isAllowedSchoolEmail returns false for non-school domains', () {
    expect(AuthService.isAllowedSchoolEmail('student@gmail.com'), isFalse);
    expect(AuthService.isAllowedSchoolEmail('student@lamduan.mfu.ac.thx'), isFalse);
  });

  test('bootstrapUser creates a user when missing', () async {
    final userRepo = MockUserRepository();
    final feedbackRepo = MockFeedbackRepository();
    final sessionRepo = MockSessionRepository();
    final mockUser = MockUser(
      uid: 'uid-1',
      email: 'test@example.com',
      displayName: 'Test User',
      photoURL: 'https://example.com/avatar.png',
    );
    final firebaseAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

    when(() => userRepo.getUser('uid-1')).thenAnswer((_) async => null);
    when(() => feedbackRepo.getFeedbackForUser('uid-1'))
        .thenAnswer((_) async => []);
    when(() => sessionRepo.getSessionsByCreator('uid-1')).thenAnswer((_) async => []);
    when(() => sessionRepo.getSessionsByPartner('uid-1')).thenAnswer((_) async => []);
    when(() => sessionRepo.getSessionsByParticipant('uid-1')).thenAnswer((_) async => []);
    when(() => userRepo.createUser(any())).thenAnswer((_) async {});
    when(() => userRepo.upsertPublicProfile(any())).thenAnswer((_) async {});

    final service = AuthService(
      userRepository: userRepo,
      feedbackRepository: feedbackRepo,
      sessionRepository: sessionRepo,
      firebaseAuth: firebaseAuth,
    );

    final result = await service.bootstrapUser('uid-1');

    expect(result.uid, 'uid-1');
    expect(result.name, 'Test User');
    expect(result.email, 'test@example.com');
    verify(() => userRepo.createUser(any())).called(1);
    verify(() => userRepo.upsertPublicProfile(any())).called(1);
  });

  test('bootstrapUser updates existing user when data changes', () async {
    final userRepo = MockUserRepository();
    final feedbackRepo = MockFeedbackRepository();
    final sessionRepo = MockSessionRepository();
    final mockUser = MockUser(
      uid: 'uid-1',
      email: 'test@example.com',
      displayName: 'Updated User',
      photoURL: 'https://example.com/avatar.png',
    );
    final firebaseAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    final now = DateTime(2024, 1, 1, 12, 0);

    final existing = UserModel(
      uid: 'uid-1',
      name: 'Old Name',
      email: 'old@example.com',
      rating: 1.0,
      totalSessions: 2,
      createdAt: now,
      lastSeen: now.subtract(const Duration(hours: 1)),
    );

    when(() => userRepo.getUser('uid-1')).thenAnswer((_) async => existing);
    when(() => feedbackRepo.getFeedbackForUser('uid-1')).thenAnswer(
      (_) async => [
        FeedbackModel(
          feedbackId: 'fb-1',
          sessionId: 's-1',
          reviewerUid: 'r-1',
          revieweeUid: 'uid-1',
          rating: 5,
          createdAt: now,
        ),
      ],
    );
    when(() => sessionRepo.getSessionsByCreator('uid-1')).thenAnswer((_) async => []);
    when(() => sessionRepo.getSessionsByPartner('uid-1')).thenAnswer((_) async => []);
    when(() => sessionRepo.getSessionsByParticipant('uid-1')).thenAnswer((_) async => []);
    when(() => userRepo.updateUser(any())).thenAnswer((_) async {});
    when(() => userRepo.upsertPublicProfile(any())).thenAnswer((_) async {});

    final service = AuthService(
      userRepository: userRepo,
      feedbackRepository: feedbackRepo,
      sessionRepository: sessionRepo,
      firebaseAuth: firebaseAuth,
    );

    final result = await service.bootstrapUser('uid-1');

    expect(result.name, 'Updated User');
    expect(result.rating, 5.0);
    verify(() => userRepo.updateUser(any())).called(1);
    verify(() => userRepo.upsertPublicProfile(any())).called(1);
  });
}
