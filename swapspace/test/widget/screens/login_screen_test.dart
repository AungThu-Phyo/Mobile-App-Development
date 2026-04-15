import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swapspace/features/auth/screens/login_screen.dart';
import 'package:swapspace/providers/auth_provider.dart';
import 'package:swapspace/providers/consent_provider.dart';
import 'package:swapspace/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  testWidgets('shows login CTA and app title', (tester) async {
    SharedPreferences.setMockInitialValues({
      'privacy_consent_accepted': true,
    });

    final authService = MockAuthService();
    when(() => authService.authStateStream())
        .thenAnswer((_) => Stream.value(null));
    when(() => authService.signInWithGoogle())
        .thenAnswer((_) async => true);

    final authProvider = AuthProvider(authService: authService);
    final consentProvider = ConsentProvider();
    await consentProvider.loadConsent();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: consentProvider),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SwapSpace'), findsOneWidget);
    expect(find.text('Sign in with School Email'), findsOneWidget);
  });

  testWidgets('declining consent keeps sign-in blocked', (tester) async {
    SharedPreferences.setMockInitialValues({
      'privacy_consent_accepted': false,
    });

    final authService = MockAuthService();
    when(() => authService.authStateStream())
        .thenAnswer((_) => Stream.value(null));
    when(() => authService.signInWithGoogle())
        .thenAnswer((_) async => true);

    final authProvider = AuthProvider(authService: authService);
    final consentProvider = ConsentProvider();
    await consentProvider.loadConsent();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: consentProvider),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Privacy Consent'), findsOneWidget);
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in with School Email'));
    await tester.pumpAndSettle();

    expect(find.text('Privacy Consent'), findsOneWidget);
    verifyNever(() => authService.signInWithGoogle());
  });

  testWidgets('accepting consent allows Google sign-in attempt', (tester) async {
    SharedPreferences.setMockInitialValues({
      'privacy_consent_accepted': false,
    });

    final authService = MockAuthService();
    when(() => authService.authStateStream())
        .thenAnswer((_) => Stream.value(null));
    when(() => authService.signInWithGoogle())
        .thenAnswer((_) async => true);

    final authProvider = AuthProvider(authService: authService);
    final consentProvider = ConsentProvider();
    await consentProvider.loadConsent();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: consentProvider),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Privacy Consent'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    await tester.tap(find.text('I have read and agree'));
    await tester.pumpAndSettle();
    expect(find.text('Next'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in with School Email'));
    await tester.pumpAndSettle();

    verify(() => authService.signInWithGoogle()).called(1);
  });
}
