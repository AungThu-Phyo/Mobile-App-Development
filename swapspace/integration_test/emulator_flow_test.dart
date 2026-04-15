import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:swapspace/core/constants/session_constants.dart';
import 'package:swapspace/firebase_options.dart';
import 'package:swapspace/models/session_model.dart';
import 'package:swapspace/repositories/join_request_repository.dart';
import 'package:swapspace/repositories/notification_repository.dart';
import 'package:swapspace/repositories/session_repository.dart';
import 'package:swapspace/repositories/user_repository.dart';
import 'package:swapspace/services/join_request_service.dart';
import 'package:swapspace/services/notification_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('emulator flow: create session and accept join request', (tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    const firestoreHost = String.fromEnvironment(
      'FIRESTORE_EMULATOR_HOST',
      defaultValue: '10.0.2.2:8080',
    );
    const authHost = String.fromEnvironment(
      'FIREBASE_AUTH_EMULATOR_HOST',
      defaultValue: '10.0.2.2:9099',
    );

    final firestoreParts = firestoreHost.split(':');
    final authParts = authHost.split(':');
    FirebaseFirestore.instance.useFirestoreEmulator(
      firestoreParts[0],
      int.parse(firestoreParts[1]),
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    FirebaseAuth.instance.useAuthEmulator(
      authParts[0],
      int.parse(authParts[1]),
    );

    final email = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final authUser = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: 'pass1234');

    final firestore = FirebaseFirestore.instance;
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
      creatorUid: authUser.user!.uid,
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Emulator Session',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 2,
      participantUids: [authUser.user!.uid],
      createdAt: now,
      updatedAt: now,
    );
    await sessionRepo.create(session);

    await service.sendJoinRequest(
      sessionId: session.sessionId,
      creatorUid: session.creatorUid,
      requesterUid: 'requester-1',
      requesterName: 'Requester',
      sessionTitle: session.title,
    );

    final requests = await requestRepo.getPendingForSession(session.sessionId);
    expect(requests.length, 1);

    await service.acceptRequest(requestId: requests.first.requestId);

    final updatedSession = await sessionRepo.getById(session.sessionId);
    expect(updatedSession, isNotNull);
    expect(updatedSession!.status, SessionStatus.matched);

    final notifications =
        await firestore.collection('notifications').get();
    expect(notifications.docs, isNotEmpty);
  });

  testWidgets('emulator flow: reject and cancel request lifecycle', (tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    const firestoreHost = String.fromEnvironment(
      'FIRESTORE_EMULATOR_HOST',
      defaultValue: '10.0.2.2:8080',
    );
    const authHost = String.fromEnvironment(
      'FIREBASE_AUTH_EMULATOR_HOST',
      defaultValue: '10.0.2.2:9099',
    );

    final firestoreParts = firestoreHost.split(':');
    final authParts = authHost.split(':');
    FirebaseFirestore.instance.useFirestoreEmulator(
      firestoreParts[0],
      int.parse(firestoreParts[1]),
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    FirebaseAuth.instance.useAuthEmulator(
      authParts[0],
      int.parse(authParts[1]),
    );

    final email = 'test_${DateTime.now().millisecondsSinceEpoch}_2@example.com';
    final authUser = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: 'pass1234');

    final firestore = FirebaseFirestore.instance;
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

    final now = DateTime(2024, 1, 2, 10, 0);
    final session = SessionModel(
      sessionId: 'session-2',
      creatorUid: authUser.user!.uid,
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Emulator Session 2',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 3,
      participantUids: [authUser.user!.uid],
      createdAt: now,
      updatedAt: now,
    );
    await sessionRepo.create(session);

    await service.sendJoinRequest(
      sessionId: session.sessionId,
      creatorUid: session.creatorUid,
      requesterUid: 'requester-2',
      requesterName: 'Requester 2',
      sessionTitle: session.title,
    );

    final pending = await requestRepo.getPendingForSession(session.sessionId);
    expect(pending.length, 1);

    await service.rejectRequest(requestId: pending.first.requestId);
    final rejected = await requestRepo.getById(pending.first.requestId);
    expect(rejected, isNotNull);
    expect(rejected!.status, JoinRequestStatus.rejected);

    await service.sendJoinRequest(
      sessionId: session.sessionId,
      creatorUid: session.creatorUid,
      requesterUid: 'requester-3',
      requesterName: 'Requester 3',
      sessionTitle: session.title,
    );
    final nextPending = await requestRepo.getPendingForSession(session.sessionId);
    expect(nextPending.length, 1);

    await service.cancelJoinRequest(requestId: nextPending.first.requestId);
    final cancelled = await requestRepo.getById(nextPending.first.requestId);
    expect(cancelled, isNotNull);
    expect(cancelled!.status, JoinRequestStatus.cancelled);
  });
}
