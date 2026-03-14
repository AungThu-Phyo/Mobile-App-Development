import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/route_names.dart';
import '../../models/session_model.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/sessions/screens/home_screen.dart';
import '../../features/sessions/screens/session_detail_screen.dart';
import '../../features/sessions/screens/create_session_screen.dart';
import '../../features/sessions/screens/edit_session_screen.dart';
import '../../features/sessions/screens/feedback_screen.dart';
import '../../features/sessions/screens/requests_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../providers/join_request_provider.dart';
import '../../providers/notification_provider.dart';

abstract class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: RouteNames.login,
      refreshListenable: authProvider,
      redirect: (context, state) {
        // While auth state is loading, stay on current route
        if (authProvider.isLoading) return null;

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
              path: RouteNames.requests,
              builder: (context, state) => const RequestsScreen(),
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
            final session = state.extra as SessionModel;
            return SessionDetailScreen(session: session);
          },
        ),
        GoRoute(
          path: RouteNames.editSession,
          builder: (context, state) {
            final session = state.extra as SessionModel;
            return EditSessionScreen(session: session);
          },
        ),
        GoRoute(
          path: RouteNames.feedback,
          builder: (context, state) {
            final session = state.extra as SessionModel;
            return FeedbackScreen(session: session);
          },
        ),
      ],
    );
  }
}

class _ScaffoldWithNav extends StatefulWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  @override
  State<_ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends State<_ScaffoldWithNav> {
  bool _streamStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_streamStarted) {
      final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
      if (uid.isNotEmpty) {
        context.read<JoinRequestProvider>().listenIncomingRequests(uid);
        context.read<NotificationProvider>().listenNotifications(uid);
        _streamStarted = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = switch (location) {
      RouteNames.home => 0,
      RouteNames.createSession => 1,
      RouteNames.requests => 2,
      RouteNames.profile => 3,
      _ => 0,
    };

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Consumer<JoinRequestProvider>(
        builder: (context, requestProvider, _) {
          final badgeCount = requestProvider.pendingIncomingCount;
          return Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x17000000),
                  blurRadius: 18,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BottomNavigationBar(
                currentIndex: index,
                onTap: (i) {
                  switch (i) {
                    case 0:
                      context.go(RouteNames.home);
                    case 1:
                      context.go(RouteNames.createSession);
                    case 2:
                      context.go(RouteNames.requests);
                    case 3:
                      context.go(RouteNames.profile);
                  }
                },
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle_rounded),
                    label: 'Create',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: badgeCount > 0,
                      label: Text('$badgeCount'),
                      child: const Icon(Icons.mail_outline_rounded),
                    ),
                    label: 'Requests',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
