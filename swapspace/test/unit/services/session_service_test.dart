import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swapspace/core/constants/session_constants.dart';
import 'package:swapspace/models/join_request_model.dart';
import 'package:swapspace/models/session_model.dart';
import 'package:swapspace/repositories/join_request_repository.dart';
import 'package:swapspace/repositories/paginated_query_result.dart';
import 'package:swapspace/repositories/session_repository.dart';
import 'package:swapspace/services/notification_service.dart';
import 'package:swapspace/services/session_service.dart';

class MockSessionRepository extends Mock implements SessionRepository {}
class MockJoinRequestRepository extends Mock implements JoinRequestRepository {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(SessionModel.empty());
  });

  test('createSession delegates to repository and returns created session', () async {
    final repo = MockSessionRepository();
    final joinRepo = MockJoinRequestRepository();
    final notificationService = MockNotificationService();
    final service = SessionService(
      repository: repo,
      joinRequestRepository: joinRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final session = SessionModel(
      sessionId: 'session-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 3,
      participantUids: ['creator-1'],
      createdAt: now,
      updatedAt: now,
    );

    when(() => repo.create(any())).thenAnswer((_) async {});

    final created = await service.createSession(session);

    expect(created.sessionId, 'session-1');
    verify(() => repo.create(session)).called(1);
  });

  test('cancelSession marks session as cancelled and inactive', () async {
    final repo = MockSessionRepository();
    final joinRepo = MockJoinRequestRepository();
    final notificationService = MockNotificationService();
    final service = SessionService(
      repository: repo,
      joinRequestRepository: joinRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final session = SessionModel(
      sessionId: 'session-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 2,
      participantUids: ['creator-1'],
      createdAt: now,
      updatedAt: now,
    );

    when(() => repo.getById('session-1')).thenAnswer((_) async => session);
    when(() => repo.update(any())).thenAnswer((_) async {});

    final result = await service.cancelSession(
      sessionId: 'session-1',
      sessions: [session],
      mySessions: [session],
      selectedSession: session,
    );

    expect(result.sessions, isEmpty);
    expect(result.mySessions.first.status, SessionStatus.cancelled);
    expect(result.mySessions.first.isActive, false);
  });

  test('cancelSession throws when session is missing', () async {
    final repo = MockSessionRepository();
    final joinRepo = MockJoinRequestRepository();
    final notificationService = MockNotificationService();
    final service = SessionService(
      repository: repo,
      joinRequestRepository: joinRepo,
      notificationService: notificationService,
    );

    when(() => repo.getById('missing')).thenAnswer((_) async => null);

    expect(
      () => service.cancelSession(
        sessionId: 'missing',
        sessions: const [],
        mySessions: const [],
        selectedSession: null,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('updateSession reopens matched session with available slots', () async {
    final repo = MockSessionRepository();
    final joinRepo = MockJoinRequestRepository();
    final notificationService = MockNotificationService();
    final service = SessionService(
      repository: repo,
      joinRequestRepository: joinRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final matched = SessionModel(
      sessionId: 'session-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 3,
      participantUids: ['creator-1'],
      status: SessionStatus.matched,
      createdAt: now,
      updatedAt: now,
    );

    when(() => repo.update(any())).thenAnswer((_) async {});
    when(
      () => notificationService.sendNotification(
        recipientUid: any(named: 'recipientUid'),
        senderUid: any(named: 'senderUid'),
        senderName: any(named: 'senderName'),
        sessionId: any(named: 'sessionId'),
        sessionTitle: any(named: 'sessionTitle'),
        type: any(named: 'type'),
        message: any(named: 'message'),
      ),
    ).thenAnswer((_) async {});

    await service.updateSession(
      session: matched,
      sessions: [matched],
      mySessions: [matched],
      selectedSession: matched,
    );

    final captured = verify(() => repo.update(captureAny())).captured;
    final updated = captured.single as SessionModel;
    expect(updated.status, SessionStatus.open);
    expect(updated.isActive, true);
  });

  test('updateSession notifies joined participants except creator', () async {
    final repo = MockSessionRepository();
    final joinRepo = MockJoinRequestRepository();
    final notificationService = MockNotificationService();
    final service = SessionService(
      repository: repo,
      joinRequestRepository: joinRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final session = SessionModel(
      sessionId: 'session-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 3,
      participantUids: ['creator-1', 'user-1', 'user-2'],
      createdAt: now,
      updatedAt: now,
    );

    when(() => repo.update(any())).thenAnswer((_) async {});
    when(
      () => notificationService.sendNotification(
        recipientUid: any(named: 'recipientUid'),
        senderUid: any(named: 'senderUid'),
        senderName: any(named: 'senderName'),
        sessionId: any(named: 'sessionId'),
        sessionTitle: any(named: 'sessionTitle'),
        type: any(named: 'type'),
        message: any(named: 'message'),
      ),
    ).thenAnswer((_) async {});

    await service.updateSession(
      session: session,
      sessions: [session],
      mySessions: [session],
      selectedSession: session,
    );

    verify(
      () => notificationService.sendNotification(
        recipientUid: 'user-1',
        senderUid: 'creator-1',
        senderName: 'Creator',
        sessionId: 'session-1',
        sessionTitle: 'Session',
        type: NotificationType.sessionUpdated,
        message: 'Creator updated the session Session',
      ),
    ).called(1);
    verify(
      () => notificationService.sendNotification(
        recipientUid: 'user-2',
        senderUid: 'creator-1',
        senderName: 'Creator',
        sessionId: 'session-1',
        sessionTitle: 'Session',
        type: NotificationType.sessionUpdated,
        message: 'Creator updated the session Session',
      ),
    ).called(1);
  });

  test('createSession surfaces repository errors', () async {
    final repo = MockSessionRepository();
    final joinRepo = MockJoinRequestRepository();
    final notificationService = MockNotificationService();
    final service = SessionService(
      repository: repo,
      joinRequestRepository: joinRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final session = SessionModel(
      sessionId: 'session-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 3,
      participantUids: ['creator-1'],
      createdAt: now,
      updatedAt: now,
    );

    when(() => repo.create(any())).thenThrow(StateError('permission-denied'));

    expect(() => service.createSession(session), throwsA(isA<StateError>()));
  });

  test('filterSessions keeps mine/joined and excludes full or high-rating sessions', () {
    final repo = MockSessionRepository();
    final joinRepo = MockJoinRequestRepository();
    final notificationService = MockNotificationService();
    final service = SessionService(
      repository: repo,
      joinRequestRepository: joinRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    SessionModel session({
      required String id,
      required String creatorUid,
      required String activity,
      required int maxParticipants,
      required List<String> participants,
      double minRating = 0,
    }) {
      return SessionModel(
        sessionId: id,
        creatorUid: creatorUid,
        creatorName: 'Creator',
        activityType: activity,
        title: id,
        location: 'Library',
        date: now.add(const Duration(days: 1)),
        durationMinutes: 60,
        maxParticipants: maxParticipants,
        participantUids: participants,
        minRating: minRating,
        createdAt: now,
        updatedAt: now,
      );
    }

    final sessions = [
      session(
        id: 'mine',
        creatorUid: 'me',
        activity: 'study',
        maxParticipants: 2,
        participants: const ['me', 'x'],
      ),
      session(
        id: 'joined',
        creatorUid: 'other',
        activity: 'study',
        maxParticipants: 3,
        participants: const ['other', 'me'],
      ),
      session(
        id: 'full-not-mine',
        creatorUid: 'other',
        activity: 'study',
        maxParticipants: 2,
        participants: const ['a', 'b'],
      ),
      session(
        id: 'rating-too-high',
        creatorUid: 'other',
        activity: 'study',
        maxParticipants: 4,
        participants: const ['other'],
        minRating: 4.9,
      ),
      session(
        id: 'valid-open',
        creatorUid: 'other',
        activity: 'study',
        maxParticipants: 4,
        participants: const ['other'],
        minRating: 3.5,
      ),
      session(
        id: 'valid-open-different-activity',
        creatorUid: 'other',
        activity: 'gym',
        maxParticipants: 4,
        participants: const ['other'],
      ),
    ];

    final all = service.filterSessions(
      sessions: sessions,
      currentUid: 'me',
      userRating: 4.0,
      selectedFilter: SessionConstants.filterAll,
    );

    expect(all.map((s) => s.sessionId), containsAll(['mine', 'joined', 'valid-open', 'valid-open-different-activity']));
    expect(all.map((s) => s.sessionId), isNot(contains('full-not-mine')));
    expect(all.map((s) => s.sessionId), isNot(contains('rating-too-high')));

    final filtered = service.filterSessions(
      sessions: sessions,
      currentUid: 'me',
      userRating: 4.0,
      selectedFilter: 'study',
    );
    expect(filtered.every((s) => s.activityType.toLowerCase() == 'study'), isTrue);
  });

  test('loadOpenSessionsPage maps paginated repository result', () async {
    final repo = MockSessionRepository();
    final joinRepo = MockJoinRequestRepository();
    final notificationService = MockNotificationService();
    final service = SessionService(
      repository: repo,
      joinRequestRepository: joinRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final session = SessionModel(
      sessionId: 'session-open-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Open Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 3,
      participantUids: const ['creator-1'],
      createdAt: now,
      updatedAt: now,
    );

    when(
      () => repo.getSessionsByStatusPage(
        status: SessionStatus.open,
        pageSize: SessionRepository.defaultPageSize,
        startAfterDocument: null,
      ),
    ).thenAnswer(
      (_) async => PaginatedQueryResult<SessionModel>(
        items: [session],
        lastDocument: null,
        hasMore: false,
      ),
    );

    final page = await service.loadOpenSessionsPage();
    expect(page.items.length, 1);
    expect(page.items.first.sessionId, 'session-open-1');
    expect(page.hasMore, false);
  });

  test('loadMySessions includes fallback accepted requests and excludes accepted leaves', () async {
    final repo = MockSessionRepository();
    final joinRepo = MockJoinRequestRepository();
    final notificationService = MockNotificationService();
    final service = SessionService(
      repository: repo,
      joinRequestRepository: joinRepo,
      notificationService: notificationService,
    );

    when(() => repo.getSessionsByCreator('u1')).thenAnswer((_) async => []);
    when(() => repo.getSessionsByPartner('u1')).thenAnswer((_) async => []);
    when(() => repo.getSessionsByParticipant('u1')).thenAnswer((_) async => []);

    final now = DateTime(2024, 1, 1, 10, 0);
    when(() => joinRepo.getFromUser('u1')).thenAnswer(
      (_) async => [
        JoinRequestModel(
          requestId: 'r1',
          sessionId: 's-accepted',
          requesterUid: 'u1',
          creatorUid: 'creator',
          requestType: JoinRequestType.join,
          status: JoinRequestStatus.accepted,
          createdAt: now,
          updatedAt: now,
        ),
        JoinRequestModel(
          requestId: 'r2',
          sessionId: 's-left',
          requesterUid: 'u1',
          creatorUid: 'creator',
          requestType: JoinRequestType.leave,
          status: JoinRequestStatus.accepted,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    when(() => repo.getById('s-accepted')).thenAnswer(
      (_) async => SessionModel(
        sessionId: 's-accepted',
        creatorUid: 'creator',
        creatorName: 'Creator',
        activityType: SessionConstants.defaultActivityType,
        title: 'Accepted Session',
        location: 'Library',
        date: now.add(const Duration(days: 1)),
        durationMinutes: 60,
        maxParticipants: 3,
        participantUids: const ['creator', 'u1'],
        createdAt: now,
        updatedAt: now,
      ),
    );

    final sessions = await service.loadMySessions('u1');

    expect(sessions.map((s) => s.sessionId), contains('s-accepted'));
    expect(sessions.map((s) => s.sessionId), isNot(contains('s-left')));
    verify(() => repo.getById('s-accepted')).called(1);
    verifyNever(() => repo.getById('s-left'));
  });
}
