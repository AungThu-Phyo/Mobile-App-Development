import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
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

  await _configureFirestorePersistence();

  await _initializeFirebaseMonitoring();

  await _activateAppCheck();

  final userRepository = UserRepository();
  final feedbackRepository = FeedbackRepository();
  final sessionRepository = SessionRepository();
  final joinRequestRepository = JoinRequestRepository();
  final authService = AuthService(
    userRepository: userRepository,
    feedbackRepository: feedbackRepository,
    sessionRepository: sessionRepository,
  );
  final authProvider = AuthProvider(authService: authService);
  final consentProvider = ConsentProvider();
  await consentProvider.loadConsent();

  final notificationRepository = NotificationRepository();
  final notificationService = NotificationService(repository: notificationRepository);
  final notificationProvider = NotificationProvider(service: notificationService);

  final feedbackService = FeedbackService(
    repository: feedbackRepository,
    userRepository: userRepository,
    sessionRepository: sessionRepository,
  );
  final feedbackProvider = FeedbackProvider(service: feedbackService);

  final privacyRepository = PrivacyRepository();
  final privacyService = PrivacyService(
    privacyRepository: privacyRepository,
    authService: authService,
  );
  final privacyProvider = PrivacyProvider(service: privacyService);

  final themeProvider = ThemeProvider();

  final joinRequestService = JoinRequestService(
    requestRepository: joinRequestRepository,
    sessionRepository: sessionRepository,
    userRepository: userRepository,
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
  final cacheBuster = DateTime.now().millisecondsSinceEpoch;
  final envPaths = kIsWeb
      ? [
          '/.env?v=$cacheBuster',
          '/assets/.env?v=$cacheBuster',
          '/assets/.env',
          '/.env',
          'assets/.env',
          '.env',
        ]
      : ['.env'];

  Object? lastError;
  StackTrace? lastStack;

  for (final envFileName in envPaths) {
    try {
      await dotenv.load(fileName: envFileName);

      final apiKey = (dotenv.env['FIREBASE_WEB_API_KEY'] ?? '').trim();
      final hasHtmlLikeKeys = dotenv.env.keys.any(
        (key) => key.trimLeft().startsWith('<'),
      );

      if (!kIsWeb || (apiKey.isNotEmpty && !hasHtmlLikeKeys)) {
        debugPrint('✅ dotenv loaded from $envFileName. Keys: ${dotenv.env.keys.toList()}');
        debugPrint('API_KEY empty? ${apiKey.isEmpty}');
        return;
      }

      if (!kIsWeb) {
        debugPrint(
          '⚠️ dotenv from $envFileName looked invalid (html-like or missing API key), trying next path.',
        );
      }
    } catch (e, stack) {
      lastError = e;
      lastStack = stack;
      if (!kIsWeb) {
        debugPrint('⚠️ dotenv load failed from $envFileName: $e');
      }
    }
  }

  debugPrint('❌ dotenv FAILED after trying all paths: $lastError');
  if (lastStack != null) {
    debugPrint(lastStack.toString());
  }

  if (kIsWeb && _hasRequiredWebDartDefines()) {
    debugPrint(
      '⚠️ Proceeding without runtime .env because required Firebase web values were found in Dart defines.',
    );
    return;
  }

  throw StateError(
    'Unable to load a valid .env file. Ensure /assets/.env exists in deployed web assets and contains FIREBASE_WEB_API_KEY, or provide Firebase values via --dart-define/--dart-define-from-file.',
  );
}

bool _hasRequiredWebDartDefines() {
  const apiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');

  return apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      senderId.isNotEmpty &&
      projectId.isNotEmpty;
}

Future<void> _activateAppCheck() async {
  try {
    if (kIsWeb) {
      const siteKeyFromDefine =
          String.fromEnvironment('APP_CHECK_WEB_RECAPTCHA_SITE_KEY');
      final siteKey = siteKeyFromDefine.isNotEmpty
          ? siteKeyFromDefine
          : (dotenv.env['APP_CHECK_WEB_RECAPTCHA_SITE_KEY'] ?? '').trim();

      if (siteKey.isEmpty) {
        debugPrint(
          '⚠️ App Check (Web) skipped: APP_CHECK_WEB_RECAPTCHA_SITE_KEY is missing.',
        );
        return;
      }

      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(siteKey),
      );
      debugPrint('✅ Firebase App Check enabled for Web (reCAPTCHA v3).');
      return;
    }

    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestProvider(),
    );
    debugPrint('✅ Firebase App Check enabled for mobile platform.');
  } catch (e) {
    debugPrint('Firebase App Check activation skipped: $e');
  }
}

Future<void> _initializeFirebaseMonitoring() async {
  try {
    await FirebaseAnalytics.instance.logAppOpen();
    debugPrint('✅ Firebase Analytics initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase Analytics initialization skipped: $e');
  }

  if (kIsWeb) {
    FlutterError.onError = FlutterError.presentError;
    return;
  }

  try {
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    debugPrint('✅ Firebase Performance Monitoring enabled');
  } catch (e) {
    debugPrint('⚠️ Firebase Performance Monitoring initialization skipped: $e');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> _configureFirestorePersistence() async {
  final firestore = FirebaseFirestore.instance;

  if (kIsWeb) {
    try {
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('✅ Firestore web persistence enabled');
      return;
    } on FirebaseException catch (e) {
      // unimplemented can occur in older/unsupported browser environments.
      if (e.code == 'unimplemented') {
        debugPrint(
          '⚠️ Firestore web persistence unsupported in this browser/runtime: ${e.code}',
        );
        return;
      }

      debugPrint('⚠️ Firestore web persistence skipped: ${e.code} ${e.message}');
      return;
    } catch (e) {
      debugPrint('⚠️ Firestore web persistence skipped: $e');
      return;
    }
  }

  final isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  if (!isMobile) {
    debugPrint('ℹ️ Firestore offline persistence not configured for this platform');
    return;
  }

  try {
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('✅ Firestore mobile persistence enabled (unlimited cache)');
  } on FirebaseException catch (e) {
    debugPrint('⚠️ Firestore mobile persistence skipped: ${e.code} ${e.message}');
  } catch (e) {
    debugPrint('⚠️ Firestore mobile persistence skipped: $e');
  }
}