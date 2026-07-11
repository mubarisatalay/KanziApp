import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/models/user_profile_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/rooms/presentation/screens/home_screen.dart';

/// Router refresh notifier
class RouterNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

/// Provider for GoRouter instance
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier();

  // Refresh routing whenever the auth session changes.
  ref.listen<AsyncValue<UserProfileModel?>>(
    authStateProvider,
    (_, __) => notifier.notify(),
  );

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // While the session is still loading, stay put.
      if (authState.isLoading) {
        return null;
      }

      final isAuthenticated = authState.value != null;
      final isOnLoginPage = state.matchedLocation == '/login';
      final isOnHomePage = state.matchedLocation == '/home';

      if (!isAuthenticated && !isOnLoginPage) {
        return '/login';
      }
      if (isAuthenticated && !isOnHomePage) {
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
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
