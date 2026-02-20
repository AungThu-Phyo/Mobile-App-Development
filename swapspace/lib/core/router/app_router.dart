import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_names.dart';
import '../../models/activity_session.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/sessions/screens/home_screen.dart';
import '../../features/sessions/screens/session_detail_screen.dart';
import '../../features/sessions/screens/create_session_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

abstract class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: RouteNames.login,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isOnLogin = state.matchedLocation == RouteNames.login;

        if (!isLoggedIn && !isOnLogin) return RouteNames.login;
        if (isLoggedIn && isOnLogin) return RouteNames.home;
        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return _ScaffoldWithNav(child: child);
          },
          routes: [
            GoRoute(
              path: RouteNames.home,
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: RouteNames.createSession,
              builder: (context, state) => const CreateSessionScreen(),
            ),
            GoRoute(
              path: RouteNames.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: RouteNames.sessionDetail,
          builder: (context, state) {
            final session = state.extra as ActivitySession;
            return SessionDetailScreen(session: session);
          },
        ),
      ],
    );
  }
}

class _ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = switch (location) {
      RouteNames.home => 0,
      RouteNames.createSession => 1,
      RouteNames.profile => 2,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go(RouteNames.home);
            case 1:
              context.go(RouteNames.createSession);
            case 2:
              context.go(RouteNames.profile);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
