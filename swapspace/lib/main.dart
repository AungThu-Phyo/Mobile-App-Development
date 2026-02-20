import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/session_provider.dart';
import 'app.dart';

void main() {
  final authProvider = AuthProvider()..checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => SessionProvider()..loadSessions()),
      ],
      child: SwapSpaceApp(authProvider: authProvider),
    ),
  );
}
