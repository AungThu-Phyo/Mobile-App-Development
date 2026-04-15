import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:swapspace/features/sessions/screens/create_session_screen.dart';
import 'package:swapspace/models/session_model.dart';
import 'package:swapspace/models/user_model.dart';
import 'package:swapspace/providers/auth_provider.dart';
import 'package:swapspace/providers/session_provider.dart';
import 'package:swapspace/services/auth_service.dart';
import 'package:swapspace/services/session_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockSessionService extends Mock implements SessionService {}

void main() {
  setUpAll(() {
    registerFallbackValue(SessionModel.empty());
  });

  testWidgets('create session validates required fields', (tester) async {
    final authService = MockAuthService();
    final sessionService = MockSessionService();

    final user = UserModel(
      uid: 'uid-1',
      name: 'User',
      email: 'user@example.com',
      createdAt: DateTime(2024, 1, 1),
      lastSeen: DateTime(2024, 1, 1),
    );

    when(() => authService.authStateStream()).thenAnswer((_) => Stream.value('uid-1'));
    when(() => authService.bootstrapUser('uid-1')).thenAnswer((_) async => user);

    final authProvider = AuthProvider(authService: authService);
    final mockBackedProvider = SessionProvider(service: sessionService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SessionProvider>.value(value: mockBackedProvider),
        ],
        child: const MaterialApp(home: CreateSessionScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final postButton = find.text('Post Session');
    await tester.ensureVisible(postButton);
    await tester.tap(find.text('Post Session'));
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Location is required'), findsOneWidget);
    expect(find.text('Required'), findsNWidgets(2));
    expect(find.text('At least 2'), findsOneWidget);
    verifyNever(() => sessionService.createSession(any()));
  });

  testWidgets('create session blocks malicious title input', (tester) async {
    final authService = MockAuthService();
    final sessionService = MockSessionService();

    final user = UserModel(
      uid: 'uid-1',
      name: 'User',
      email: 'user@example.com',
      createdAt: DateTime(2024, 1, 1),
      lastSeen: DateTime(2024, 1, 1),
    );

    when(() => authService.authStateStream()).thenAnswer((_) => Stream.value('uid-1'));
    when(() => authService.bootstrapUser('uid-1')).thenAnswer((_) async => user);

    final authProvider = AuthProvider(authService: authService);
    final sessionProvider = SessionProvider(service: sessionService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),
        ],
        child: const MaterialApp(home: CreateSessionScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '<script>alert(1)</script>');
    await tester.enterText(textFields.at(2), 'Library');
    await tester.enterText(textFields.at(4), '1');
    await tester.enterText(textFields.at(6), '3');

    final postButton = find.text('Post Session');
    await tester.ensureVisible(postButton);
    await tester.tap(find.text('Post Session'));
    await tester.pumpAndSettle();

    expect(find.text('Title contains invalid characters'), findsOneWidget);
    verifyNever(() => sessionService.createSession(any()));
  });
}
