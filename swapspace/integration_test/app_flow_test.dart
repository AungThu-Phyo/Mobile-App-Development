import 'dart:async';

import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swapspace/app.dart';
import 'package:swapspace/models/join_request_model.dart';
import 'package:swapspace/models/session_model.dart';
import 'package:swapspace/models/user_model.dart';
import 'package:swapspace/providers/auth_provider.dart';
import 'package:swapspace/providers/consent_provider.dart';
import 'package:swapspace/providers/join_request_provider.dart';
import 'package:swapspace/providers/notification_provider.dart';
import 'package:swapspace/providers/session_provider.dart';
import 'package:swapspace/providers/theme_provider.dart';
import 'package:swapspace/services/auth_service.dart';
import 'package:swapspace/services/join_request_service.dart';
import 'package:swapspace/services/notification_service.dart';
import 'package:swapspace/services/session_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockSessionService extends Mock implements SessionService {}
class MockJoinRequestService extends Mock implements JoinRequestService {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(SessionModel.empty());
  });

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
    throw StateError('Widget not found within timeout.');
  }

  testWidgets('sign in, create session, view requests', (tester) async {
    SharedPreferences.setMockInitialValues({
      'privacy_consent_accepted': true,
      'theme_mode_dark': false,
    });

    final authService = MockAuthService();
    final sessionService = MockSessionService();
    final joinRequestService = MockJoinRequestService();
    final notificationService = MockNotificationService();
    final authState = StreamController<String?>.broadcast();

    final user = UserModel(
      uid: 'uid-1',
      name: 'Test User',
      email: 'test@example.com',
      createdAt: DateTime(2024, 1, 1),
      lastSeen: DateTime(2024, 1, 1),
    );

    when(() => authService.authStateStream())
        .thenAnswer((_) => authState.stream);
    when(() => authService.signInWithGoogle()).thenAnswer((_) async {
      authState.add('uid-1');
      return true;
    });
    when(() => authService.bootstrapUser('uid-1'))
        .thenAnswer((_) async => user);

    when(() => sessionService.loadOpenSessionsPage()).thenAnswer(
      (_) async => const SessionPageResult(
        items: [],
        lastDocument: null,
        hasMore: false,
      ),
    );
    when(
      () => sessionService.filterSessions(
        sessions: any(named: 'sessions'),
        currentUid: any(named: 'currentUid'),
        userRating: any(named: 'userRating'),
        selectedFilter: any(named: 'selectedFilter'),
      ),
    ).thenAnswer(
      (invocation) =>
          invocation.namedArguments[#sessions] as List<SessionModel>,
    );
    when(() => sessionService.createSession(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as SessionModel,
    );

    when(() => joinRequestService.listenIncomingRequests(any()))
        .thenAnswer((_) => Stream.value(<JoinRequestModel>[]));
    when(() => joinRequestService.loadIncomingRequestsPage(
          uid: any(named: 'uid'),
          pageSize: any(named: 'pageSize'),
          startAfterDocument: any(named: 'startAfterDocument'),
        )).thenAnswer(
      (_) async => const JoinRequestPageResult(
        items: [],
        lastDocument: null,
        hasMore: false,
      ),
    );
    when(() => joinRequestService.loadOutgoingRequestsPage(
          uid: any(named: 'uid'),
          pageSize: any(named: 'pageSize'),
          startAfterDocument: any(named: 'startAfterDocument'),
        )).thenAnswer(
      (_) async => const JoinRequestPageResult(
        items: [],
        lastDocument: null,
        hasMore: false,
      ),
    );
    when(() => joinRequestService.loadSessionsByIds(any()))
        .thenAnswer((_) async => <String, SessionModel>{});
    when(() => joinRequestService.loadUsersByIds(any()))
        .thenAnswer((_) async => <String, UserModel>{});

    when(() => notificationService.streamNotifications(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => notificationService.calculateUnreadCount(any()))
        .thenReturn(0);

    final authProvider = AuthProvider(authService: authService);
    final consentProvider = ConsentProvider();
    await consentProvider.loadConsent();
    final themeProvider = ThemeProvider();
    await themeProvider.loadThemePreference();

    final sessionProvider = SessionProvider(service: sessionService);
    final joinRequestProvider = JoinRequestProvider(service: joinRequestService);
    final notificationProvider =
        NotificationProvider(service: notificationService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: consentProvider),
          ChangeNotifierProvider.value(value: sessionProvider),
          ChangeNotifierProvider.value(value: joinRequestProvider),
          ChangeNotifierProvider.value(value: notificationProvider),
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: SwapSpaceApp(authProvider: authProvider),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sign in with School Email'), findsOneWidget);

    await tester.tap(find.text('Sign in with School Email'));
    await tester.pumpAndSettle();

    expect(find.text('SwapSpace'), findsWidgets);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Create Session'), findsOneWidget);

    final textFields = find.byType(TextFormField);
    await pumpUntilFound(tester, textFields);

    await tester.enterText(textFields.at(0), 'Study Session');
    await tester.enterText(textFields.at(2), 'Library');
    await tester.enterText(textFields.at(5), '30');
    await tester.enterText(textFields.at(6), '2');

    await tester.tap(find.text('Post Session'));
    await tester.pumpAndSettle();

    expect(find.text('Study Session'), findsOneWidget);

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    expect(find.text('No incoming requests'), findsOneWidget);

    await authState.close();
  });
}
