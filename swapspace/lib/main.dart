import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/consent_provider.dart';
import 'providers/session_provider.dart';
import 'providers/join_request_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/privacy_provider.dart';
import 'repositories/feedback_repository.dart';
import 'repositories/join_request_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/privacy_repository.dart';
import 'repositories/session_repository.dart';
import 'repositories/user_repository.dart';
import 'services/auth_service.dart';
import 'services/feedback_service.dart';
import 'services/join_request_service.dart';
import 'services/notification_service.dart';
import 'services/privacy_service.dart';
import 'services/session_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnvironmentVariables();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialized successfully');
  } catch (e, stack) {
    debugPrint('❌ Firebase.initializeApp FAILED: $e');
    debugPrint(stack.toString());
    rethrow;
  }

  await _activateAppCheck();

  final userRepository = UserRepository();
  final feedbackRepository = FeedbackRepository();
  final authService = AuthService(
    userRepository: userRepository,
    feedbackRepository: feedbackRepository,
  );
  final authProvider = AuthProvider(authService: authService);
  final consentProvider = ConsentProvider();
  await consentProvider.loadConsent();

  final notificationRepository = NotificationRepository();
  final notificationService = NotificationService(repository: notificationRepository);
  final notificationProvider = NotificationProvider(service: notificationService);

  final feedbackService = FeedbackService(repository: feedbackRepository);
  final feedbackProvider = FeedbackProvider(service: feedbackService);

  final privacyRepository = PrivacyRepository();
  final privacyService = PrivacyService(
    privacyRepository: privacyRepository,
    authService: authService,
  );
  final privacyProvider = PrivacyProvider(service: privacyService);

  final themeProvider = ThemeProvider();

  final sessionRepository = SessionRepository();
  final joinRequestRepository = JoinRequestRepository();

  final joinRequestService = JoinRequestService(
    requestRepository: joinRequestRepository,
    sessionRepository: sessionRepository,
    notificationService: notificationService,
  );

  final sessionService = SessionService(
    repository: sessionRepository,
    joinRequestRepository: joinRequestRepository,
    notificationService: notificationService,
  );

  await themeProvider.loadThemePreference();

  final sessionProvider = SessionProvider(service: sessionService);
  final joinRequestProvider = JoinRequestProvider(service: joinRequestService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: consentProvider),
        ChangeNotifierProvider.value(value: sessionProvider),
        ChangeNotifierProvider.value(value: joinRequestProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
        ChangeNotifierProvider.value(value: feedbackProvider),
        ChangeNotifierProvider.value(value: privacyProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: SwapSpaceApp(authProvider: authProvider),
    ),
  );
}

Future<void> _loadEnvironmentVariables() async {
  try {
    final envFileName = kIsWeb ? 'assets/.env' : '.env';
    await dotenv.load(fileName: envFileName);
    debugPrint('✅ dotenv loaded. Keys: ${dotenv.env.keys.toList()}');
    debugPrint('API_KEY empty? ${(dotenv.env['FIREBASE_WEB_API_KEY'] ?? '').isEmpty}');
  } catch (e, stack) {
    debugPrint('❌ dotenv FAILED: $e');
    debugPrint(stack.toString());
    rethrow;
  }
}

Future<void> _activateAppCheck() async {
  if (kIsWeb) {
    return;
  }

  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestProvider(),
    );
  } catch (e) {
    debugPrint('Firebase App Check activation skipped: $e');
  }
}