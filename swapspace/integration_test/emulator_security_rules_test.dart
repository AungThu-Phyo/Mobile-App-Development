import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:swapspace/firebase_options.dart';

Map<String, dynamic> _userDoc(String uid) {
  final now = Timestamp.now();
  return {
    'uid': uid,
    'name': 'User $uid',
    'email': '$uid@example.com',
    'avatarUrl': '',
    'rating': 0.0,
    'totalSessions': 0,
    'createdAt': now,
    'lastSeen': now,
    'isActive': true,
    'isProfileComplete': false,
    'faculty': '',
    'bio': '',
    'activityPreferences': <String>[],
    'interactionPreference': 'chatty',
  };
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rules deny cross-user read and write on users collection', (tester) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
    FirebaseAuth.instance.useAuthEmulator(authParts[0], int.parse(authParts[1]));

    final suffix = DateTime.now().millisecondsSinceEpoch;
    final emailA = 'a_$suffix@example.com';
    final emailB = 'b_$suffix@example.com';

    final userA = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailA,
      password: 'pass1234',
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userA.user!.uid)
        .set(_userDoc(userA.user!.uid));

    await FirebaseAuth.instance.signOut();

    final userB = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailB,
      password: 'pass1234',
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userB.user!.uid)
        .set(_userDoc(userB.user!.uid));

    expect(
      () => FirebaseFirestore.instance
          .collection('users')
          .doc(userA.user!.uid)
          .get(),
      throwsA(
        isA<FirebaseException>().having(
          (e) => e.code,
          'code',
          'permission-denied',
        ),
      ),
    );

    expect(
      () => FirebaseFirestore.instance
          .collection('users')
          .doc(userA.user!.uid)
          .update({'name': 'hacked'}),
      throwsA(
        isA<FirebaseException>().having(
          (e) => e.code,
          'code',
          'permission-denied',
        ),
      ),
    );
  });
}
