import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  // Create a notifier that will trigger router refresh on auth changes
  final notifier = RouterNotifier();

  ref.listen<AsyncValue<User?>>(
    authStateProvider,
    (_, __) => notifier.notify(),
  );

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // If still loading, stay where we are
      if (authState.isLoading) {
        return null;
      }

      final isAuthenticated = authState.value != null;
      final isOnLoginPage = state.matchedLocation == '/login';
      final isOnHomePage = state.matchedLocation == '/home';

      // Redirect to login if not authenticated and not already on login page
      if (!isAuthenticated && !isOnLoginPage) {
        return '/login';
      }

      // Redirect to home if authenticated and not already on home page
      if (isAuthenticated && !isOnHomePage) {
        return '/home';
      }

      // No redirect needed
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
