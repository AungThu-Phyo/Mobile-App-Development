import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:swapspace/features/profile/screens/profile_screen.dart';
import 'package:swapspace/models/user_model.dart';
import 'package:swapspace/providers/auth_provider.dart';
import 'package:swapspace/providers/session_provider.dart';
import 'package:swapspace/providers/theme_provider.dart';
import 'package:swapspace/services/auth_service.dart';
import 'package:swapspace/services/session_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockSessionService extends Mock implements SessionService {}

class TestSessionProvider extends SessionProvider {
  TestSessionProvider({required super.service});

  @override
  Future<void> loadCreatedSessions(String uid, {bool refresh = true}) async {
    // Skip notifications for widget test stability.
  }

  @override
  Future<void> loadJoinedSessions(String uid, {bool refresh = true}) async {
    // Skip notifications for widget test stability.
  }
}

void main() {
  testWidgets('shows profile screen when user is loaded', (tester) async {
    final authService = MockAuthService();
    final sessionService = MockSessionService();

    final user = UserModel(
      uid: 'uid-1',
      name: 'Test User',
      email: 'test@example.com',
      createdAt: DateTime(2024, 1, 1),
      lastSeen: DateTime(2024, 1, 1),
    );

    when(() => authService.authStateStream())
        .thenAnswer((_) => Stream.value('uid-1'));
    when(() => authService.bootstrapUser('uid-1'))
        .thenAnswer((_) async => user);

    when(
      () => sessionService.loadCreatedSessionsPage(
        uid: any(named: 'uid'),
        pageSize: any(named: 'pageSize'),
        startAfterDocument: any(named: 'startAfterDocument'),
      ),
    ).thenAnswer(
      (_) async => const SessionPageResult(
        items: [],
        lastDocument: null,
        hasMore: false,
      ),
    );
    when(
      () => sessionService.loadJoinedSessionsPage(
        uid: any(named: 'uid'),
        pageSize: any(named: 'pageSize'),
        cursorState: any(named: 'cursorState'),
      ),
    ).thenAnswer(
      (_) async => const JoinedSessionsPageResult(
        items: [],
        cursorState: JoinedSessionsCursorState(
          partnerCursor: null,
          participantCursor: null,
          hasMorePartner: false,
          hasMoreParticipant: false,
        ),
      ),
    );

    final authProvider = AuthProvider(authService: authService);
    final SessionProvider sessionProvider =
      TestSessionProvider(service: sessionService);
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider<SessionProvider>.value(
            value: sessionProvider,
          ),
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Sign Out'), findsWidgets);
  });
}
