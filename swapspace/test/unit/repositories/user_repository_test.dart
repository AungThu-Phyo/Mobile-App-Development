import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swapspace/models/user_model.dart';
import 'package:swapspace/repositories/user_repository.dart';

void main() {
  test('create and fetch user', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = UserRepository(firestore: firestore);
    final now = DateTime(2024, 1, 1, 10, 0);

    final user = UserModel(
      uid: 'uid-1',
      name: 'Test User',
      email: 'test@example.com',
      createdAt: now,
      lastSeen: now,
    );

    await repo.createUser(user);

    final fetched = await repo.getUser('uid-1');

    expect(fetched, isNotNull);
    expect(fetched!.email, 'test@example.com');
  });

  test('update user profile and public profile', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = UserRepository(firestore: firestore);
    final now = DateTime(2024, 1, 1, 10, 0);

    final user = UserModel(
      uid: 'uid-1',
      name: 'Original',
      email: 'test@example.com',
      createdAt: now,
      lastSeen: now,
    );

    await repo.createUser(user);

    final updated = user.copyWith(name: 'Updated');
    await repo.updateUser(updated);
    await repo.upsertPublicProfile(updated);

    final fetched = await repo.getUser('uid-1');
    final publicProfile = await repo.getPublicUser('uid-1');

    expect(fetched, isNotNull);
    expect(fetched!.name, 'Updated');
    expect(publicProfile, isNotNull);
    expect(publicProfile!.name, 'Updated');
  });
}
