import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swapspace/core/constants/session_constants.dart';
import 'package:swapspace/models/join_request_model.dart';
import 'package:swapspace/models/session_model.dart';
import 'package:swapspace/repositories/join_request_repository.dart';
import 'package:swapspace/repositories/notification_repository.dart';
import 'package:swapspace/repositories/session_repository.dart';
import 'package:swapspace/repositories/user_repository.dart';
import 'package:swapspace/services/join_request_service.dart';
import 'package:swapspace/services/notification_service.dart';

void main() {
  test('acceptRequest updates session and rejects extra requests', () async {
    final firestore = FakeFirebaseFirestore();
    final sessionRepo = SessionRepository(firestore: firestore);
    final requestRepo = JoinRequestRepository(firestore: firestore);
    final userRepo = UserRepository(firestore: firestore);
    final notificationRepo = NotificationRepository(firestore: firestore);
    final notificationService = NotificationService(repository: notificationRepo);
    final service = JoinRequestService(
      requestRepository: requestRepo,
      sessionRepository: sessionRepo,
      userRepository: userRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final session = SessionModel(
      sessionId: 'session-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Study Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 2,
      participantUids: ['creator-1'],
      createdAt: now,
      updatedAt: now,
    );
    await sessionRepo.create(session);

    final req1 = JoinRequestModel(
      requestId: 'req-1',
      sessionId: session.sessionId,
      requesterUid: 'user-1',
      creatorUid: session.creatorUid,
      requestType: JoinRequestType.join,
      status: JoinRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    final req2 = JoinRequestModel(
      requestId: 'req-2',
      sessionId: session.sessionId,
      requesterUid: 'user-2',
      creatorUid: session.creatorUid,
      requestType: JoinRequestType.join,
      status: JoinRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await requestRepo.create(req1);
    await requestRepo.create(req2);

    final result = await service.acceptRequest(requestId: 'req-1');

    expect(result.sessionId, session.sessionId);
    expect(result.acceptedRequesterUid, 'user-1');
    expect(result.sessionIsFull, true);

    final updatedSession = await sessionRepo.getById('session-1');
    expect(updatedSession, isNotNull);
    expect(updatedSession!.status, SessionStatus.matched);
    expect(updatedSession.participantUids, contains('user-1'));
    expect(updatedSession.participantUids.length, 2);

    final updatedReq1 = await requestRepo.getById('req-1');
    final updatedReq2 = await requestRepo.getById('req-2');
    expect(updatedReq1!.status, JoinRequestStatus.accepted);
    expect(updatedReq2!.status, JoinRequestStatus.rejected);

    final notifications =
        await firestore.collection('notifications').get();
    expect(notifications.docs.length, 2);
  });

  test('rejectRequest updates status and sends notification', () async {
    final firestore = FakeFirebaseFirestore();
    final sessionRepo = SessionRepository(firestore: firestore);
    final requestRepo = JoinRequestRepository(firestore: firestore);
    final userRepo = UserRepository(firestore: firestore);
    final notificationRepo = NotificationRepository(firestore: firestore);
    final notificationService = NotificationService(repository: notificationRepo);
    final service = JoinRequestService(
      requestRepository: requestRepo,
      sessionRepository: sessionRepo,
      userRepository: userRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final session = SessionModel(
      sessionId: 'session-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Study Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 3,
      participantUids: ['creator-1'],
      createdAt: now,
      updatedAt: now,
    );
    await sessionRepo.create(session);

    final req = JoinRequestModel(
      requestId: 'req-1',
      sessionId: session.sessionId,
      requesterUid: 'user-1',
      creatorUid: session.creatorUid,
      requestType: JoinRequestType.join,
      status: JoinRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await requestRepo.create(req);

    await service.rejectRequest(requestId: 'req-1');

    final updatedReq = await requestRepo.getById('req-1');
    expect(updatedReq!.status, JoinRequestStatus.rejected);

    final notifications =
        await firestore.collection('notifications').get();
    expect(notifications.docs.length, 1);
  });

  test('cancelJoinRequest sets status to cancelled', () async {
    final firestore = FakeFirebaseFirestore();
    final requestRepo = JoinRequestRepository(firestore: firestore);
    final sessionRepo = SessionRepository(firestore: firestore);
    final userRepo = UserRepository(firestore: firestore);
    final notificationRepo = NotificationRepository(firestore: firestore);
    final notificationService = NotificationService(repository: notificationRepo);
    final service = JoinRequestService(
      requestRepository: requestRepo,
      sessionRepository: sessionRepo,
      userRepository: userRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final req = JoinRequestModel(
      requestId: 'req-1',
      sessionId: 'session-1',
      requesterUid: 'user-1',
      creatorUid: 'creator-1',
      requestType: JoinRequestType.join,
      status: JoinRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await requestRepo.create(req);

    await service.cancelJoinRequest(requestId: 'req-1');

    final updatedReq = await requestRepo.getById('req-1');
    expect(updatedReq!.status, JoinRequestStatus.cancelled);
  });

  test('leaveSession creates a pending leave request', () async {
    final firestore = FakeFirebaseFirestore();
    final sessionRepo = SessionRepository(firestore: firestore);
    final requestRepo = JoinRequestRepository(firestore: firestore);
    final userRepo = UserRepository(firestore: firestore);
    final notificationRepo = NotificationRepository(firestore: firestore);
    final notificationService = NotificationService(repository: notificationRepo);
    final service = JoinRequestService(
      requestRepository: requestRepo,
      sessionRepository: sessionRepo,
      userRepository: userRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final session = SessionModel(
      sessionId: 'session-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Study Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 3,
      participantUids: ['creator-1', 'user-1'],
      createdAt: now,
      updatedAt: now,
    );
    await sessionRepo.create(session);

    await service.leaveSession(
      sessionId: session.sessionId,
      uid: 'user-1',
      userName: 'Requester',
    );

    final pending = await requestRepo.getPendingForSession(session.sessionId);
    expect(pending.length, 1);
    expect(pending.first.requestType, JoinRequestType.leave);

    final notifications =
        await firestore.collection('notifications').get();
    expect(notifications.docs.length, 1);
  });

  test('acceptRequest is idempotent when request is already processed', () async {
    final firestore = FakeFirebaseFirestore();
    final sessionRepo = SessionRepository(firestore: firestore);
    final requestRepo = JoinRequestRepository(firestore: firestore);
    final userRepo = UserRepository(firestore: firestore);
    final notificationRepo = NotificationRepository(firestore: firestore);
    final notificationService = NotificationService(repository: notificationRepo);
    final service = JoinRequestService(
      requestRepository: requestRepo,
      sessionRepository: sessionRepo,
      userRepository: userRepo,
      notificationService: notificationService,
    );

    final now = DateTime(2024, 1, 1, 10, 0);
    final session = SessionModel(
      sessionId: 'session-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Study Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 3,
      participantUids: ['creator-1'],
      createdAt: now,
      updatedAt: now,
    );
    await sessionRepo.create(session);

    await requestRepo.create(
      JoinRequestModel(
        requestId: 'req-processed',
        sessionId: 'session-1',
        requesterUid: 'user-1',
        creatorUid: 'creator-1',
        requestType: JoinRequestType.join,
        status: JoinRequestStatus.accepted,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await service.acceptRequest(requestId: 'req-processed');

    final notifications = await firestore.collection('notifications').get();
    expect(notifications.docs, isEmpty);
  });
}
