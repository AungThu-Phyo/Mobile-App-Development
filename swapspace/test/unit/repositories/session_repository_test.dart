import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swapspace/core/constants/session_constants.dart';
import 'package:swapspace/models/session_model.dart';
import 'package:swapspace/repositories/session_repository.dart';

void main() {
  test('create and fetch session', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = SessionRepository(firestore: firestore);
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

    await repo.create(session);

    final fetched = await repo.getById('session-1');

    expect(fetched, isNotNull);
    expect(fetched!.title, 'Study Session');
    expect(fetched.creatorUid, 'creator-1');
  });

  test('getByIds returns matching sessions', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = SessionRepository(firestore: firestore);
    final now = DateTime(2024, 1, 1, 10, 0);

    final sessions = [
      SessionModel(
        sessionId: 'session-1',
        creatorUid: 'creator-1',
        creatorName: 'Creator',
        activityType: SessionConstants.defaultActivityType,
        title: 'Session One',
        location: 'Library',
        date: now.add(const Duration(days: 1)),
        durationMinutes: 60,
        maxParticipants: 2,
        participantUids: ['creator-1'],
        createdAt: now,
        updatedAt: now,
      ),
      SessionModel(
        sessionId: 'session-2',
        creatorUid: 'creator-2',
        creatorName: 'Creator 2',
        activityType: SessionConstants.defaultActivityType,
        title: 'Session Two',
        location: 'Gym',
        date: now.add(const Duration(days: 2)),
        durationMinutes: 90,
        maxParticipants: 3,
        participantUids: ['creator-2'],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final session in sessions) {
      await repo.create(session);
    }

    final result = await repo.getByIds(['session-1', 'session-2']);

    expect(result.length, 2);
    expect(result['session-1']!.title, 'Session One');
    expect(result['session-2']!.location, 'Gym');
  });

  test('update persists session changes', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = SessionRepository(firestore: firestore);
    final now = DateTime(2024, 1, 1, 10, 0);

    final session = SessionModel(
      sessionId: 'session-1',
      creatorUid: 'creator-1',
      creatorName: 'Creator',
      activityType: SessionConstants.defaultActivityType,
      title: 'Old Title',
      location: 'Library',
      date: now.add(const Duration(days: 1)),
      durationMinutes: 60,
      maxParticipants: 2,
      participantUids: ['creator-1'],
      createdAt: now,
      updatedAt: now,
    );

    await repo.create(session);

    final updated = session.copyWith(title: 'New Title');
    await repo.update(updated);

    final fetched = await repo.getById('session-1');
    expect(fetched, isNotNull);
    expect(fetched!.title, 'New Title');
  });
}
