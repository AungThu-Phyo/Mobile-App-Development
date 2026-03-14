import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/session_provider.dart';
import 'providers/join_request_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/theme_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authProvider = AuthProvider();
  final notificationProvider = NotificationProvider();
  final feedbackProvider = FeedbackProvider();
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreference();
  final sessionProvider = SessionProvider()
    ..setNotificationProvider(notificationProvider);
  final joinRequestProvider = JoinRequestProvider()
    ..setNotificationProvider(notificationProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: sessionProvider),
        ChangeNotifierProvider.value(value: joinRequestProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
        ChangeNotifierProvider.value(value: feedbackProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: SwapSpaceApp(authProvider: authProvider),
    ),
  );
}
