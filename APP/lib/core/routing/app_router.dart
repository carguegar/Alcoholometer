import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/auth/domain/auth_status.dart';
import 'package:app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:app/features/auth/presentation/screens/login_screen.dart';
import 'package:app/features/auth/presentation/screens/register_screen.dart';
import 'package:app/features/home/presentation/screens/home_screen.dart';
import 'package:app/features/groups/presentation/screens/groups_screen.dart';
import 'package:app/features/groups/presentation/screens/group_details_screen.dart';
import 'package:app/features/measurements/presentation/screens/history_screen.dart';
import 'package:app/features/auth/presentation/screens/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouteNotifier(ref);
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final status = authState.when(
        data: (status) => status,
        loading: () => AuthStatus.initial,
        error: (_, __) => AuthStatus.unauthenticated,
      );

      final currentPath = state.uri.path;
      final isAuthRoute =
          currentPath == '/login' || currentPath == '/register';

      if (status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/login';
      }
      if (status == AuthStatus.authenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                name: 'groups',
                builder: (context, state) => const GroupsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'group_details',
                    builder: (context, state) => GroupDetailsScreen(
                      groupId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                name: 'history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AuthRouteNotifier extends ChangeNotifier {
  _AuthRouteNotifier(this._ref) {
    _ref.listen<AsyncValue<AuthStatus>>(
      authControllerProvider,
      (_, __) => notifyListeners(),
      fireImmediately: true,
    );
  }

  final Ref _ref;
}
