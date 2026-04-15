import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/route_names.dart';
import '../../models/session_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/privacy_policy_screen.dart';
import '../../features/sessions/screens/home_screen.dart';
import '../../features/sessions/screens/session_detail_screen.dart';
import '../../features/sessions/screens/create_session_screen.dart';
import '../../features/sessions/screens/edit_session_screen.dart';
import '../../features/sessions/screens/feedback_screen.dart';
import '../../features/sessions/screens/requests_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
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
        final isOnPrivacyPolicy = state.matchedLocation == RouteNames.privacyPolicy;

        if (!isLoggedIn && !isOnLogin && !isOnPrivacyPolicy) return RouteNames.login;
        if (isLoggedIn && isOnLogin) return RouteNames.home;
        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RouteNames.privacyPolicy,
          builder: (context, state) => const PrivacyPolicyScreen(),
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
            final session = _resolveSession(context, state.extra);
            if (session == null) return const _MissingSessionScreen();
            return SessionDetailScreen(session: session);
          },
        ),
        GoRoute(
          path: RouteNames.editSession,
          builder: (context, state) {
            final session = _resolveSession(context, state.extra);
            if (session == null) return const _MissingSessionScreen();
            return EditSessionScreen(session: session);
          },
        ),
        GoRoute(
          path: RouteNames.feedback,
          builder: (context, state) {
            final session = _resolveSession(context, state.extra);
            if (session == null) return const _MissingSessionScreen();
            return FeedbackScreen(session: session);
          },
        ),
        GoRoute(
          path: '${RouteNames.userProfile}/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            return UserProfileScreen(userId: userId);
          },
        ),
      ],
    );
  }

  static SessionModel? _resolveSession(BuildContext context, Object? extra) {
    if (extra is SessionModel) return extra;
    return context.read<SessionProvider>().selectedSession;
  }
}

class _MissingSessionScreen extends StatelessWidget {
  const _MissingSessionScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session not available')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy_rounded, size: 56),
              const SizedBox(height: 12),
              const Text(
                'Session data was not available for this route.\nPlease go back and open the session again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
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
  String _activeUid = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<AuthProvider>().userId ?? '';
    if (uid.isNotEmpty && (!_streamStarted || _activeUid != uid)) {
      _streamStarted = true;
      _activeUid = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<JoinRequestProvider>().listenIncomingRequests(uid);
        context.read<NotificationProvider>().listenNotifications(uid);
      });
    }
    if (uid.isEmpty) {
      context.read<JoinRequestProvider>().stopListeningIncomingRequests();
      context.read<NotificationProvider>().stopListeningNotifications();
      _streamStarted = false;
      _activeUid = '';
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
                      final uid = context.read<AuthProvider>().userId ?? '';
                      if (uid.isNotEmpty) {
                        final sessionProvider = context.read<SessionProvider>();
                        sessionProvider.loadCreatedSessions(uid, refresh: false);
                        sessionProvider.loadJoinedSessions(uid, refresh: false);
                      }
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
