import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:swapspace/features/sessions/screens/home_screen.dart';
import 'package:swapspace/models/session_model.dart';
import 'package:swapspace/models/user_model.dart';
import 'package:swapspace/providers/auth_provider.dart';
import 'package:swapspace/providers/join_request_provider.dart';
import 'package:swapspace/providers/notification_provider.dart';
import 'package:swapspace/providers/session_provider.dart';
import 'package:swapspace/services/auth_service.dart';
import 'package:swapspace/services/join_request_service.dart';
import 'package:swapspace/services/notification_service.dart';
import 'package:swapspace/services/session_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockSessionService extends Mock implements SessionService {}
class MockJoinRequestService extends Mock implements JoinRequestService {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(SessionModel.empty());
  });

  testWidgets('shows empty state when no sessions', (tester) async {
    final authService = MockAuthService();
    final sessionService = MockSessionService();
    final joinRequestService = MockJoinRequestService();
    final notificationService = MockNotificationService();

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
    when(() => notificationService.calculateUnreadCount(any()))
        .thenReturn(0);

    final authProvider = AuthProvider(authService: authService);
    final sessionProvider = SessionProvider(service: sessionService);
    final joinRequestProvider = JoinRequestProvider(service: joinRequestService);
    final notificationProvider =
        NotificationProvider(service: notificationService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: sessionProvider),
          ChangeNotifierProvider.value(value: joinRequestProvider),
          ChangeNotifierProvider.value(value: notificationProvider),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No sessions available'), findsOneWidget);
    expect(find.text('Create Session'), findsOneWidget);
  });
}
