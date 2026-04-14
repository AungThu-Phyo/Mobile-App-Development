import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:swapspace/features/sessions/screens/requests_screen.dart';
import 'package:swapspace/models/join_request_model.dart';
import 'package:swapspace/models/session_model.dart';
import 'package:swapspace/models/user_model.dart';
import 'package:swapspace/providers/auth_provider.dart';
import 'package:swapspace/providers/join_request_provider.dart';
import 'package:swapspace/services/auth_service.dart';
import 'package:swapspace/services/join_request_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockJoinRequestService extends Mock implements JoinRequestService {}

void main() {
  setUpAll(() {
    registerFallbackValue(JoinRequestModel.empty());
  });

  testWidgets('shows empty incoming requests state', (tester) async {
    final authService = MockAuthService();
    final joinRequestService = MockJoinRequestService();

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
      () => joinRequestService.loadIncomingRequestsPage(
        uid: any(named: 'uid'),
        pageSize: any(named: 'pageSize'),
        startAfterDocument: any(named: 'startAfterDocument'),
      ),
    ).thenAnswer(
      (_) async => const JoinRequestPageResult(
        items: [],
        lastDocument: null,
        hasMore: false,
      ),
    );
    when(
      () => joinRequestService.loadOutgoingRequestsPage(
        uid: any(named: 'uid'),
        pageSize: any(named: 'pageSize'),
        startAfterDocument: any(named: 'startAfterDocument'),
      ),
    ).thenAnswer(
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

    final authProvider = AuthProvider(authService: authService);
    final joinRequestProvider = JoinRequestProvider(service: joinRequestService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: joinRequestProvider),
        ],
        child: const MaterialApp(home: RequestsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No incoming requests'), findsOneWidget);
    expect(find.text('Outgoing'), findsOneWidget);
  });
}
