import 'package:flutter/material.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';

class SwapSpaceApp extends StatefulWidget {
  final AuthProvider authProvider;
  const SwapSpaceApp({super.key, required this.authProvider});

  @override
  State<SwapSpaceApp> createState() => _SwapSpaceAppState();
}

class _SwapSpaceAppState extends State<SwapSpaceApp> {
  late final _router = AppRouter.createRouter(widget.authProvider);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SwapSpace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
