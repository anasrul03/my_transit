import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../presentation/views/auth/login_screen.dart';
import '../presentation/views/home_screen.dart';
import '../presentation/views/settings/settings_screen.dart';
import '../presentation/views/schedules/schedule_detail_screen.dart';
import '../domain/entities/schedule_entry_entity.dart';

/// Creates and returns the GoRouter instance for the application
/// 
/// This function creates a router with authentication-based redirects.
/// The router uses a refreshListenable to react to auth state changes.
/// 
/// [authStateNotifier] - A ValueNotifier that should be updated whenever
/// auth state changes. This allows the router to refresh and apply redirects.
/// The notifier value should be true when user is authenticated or guest,
/// false when unauthenticated.
/// 
/// Returns: Configured GoRouter instance
GoRouter createRouter(ValueNotifier<bool> authStateNotifier) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      // Get current auth state from the notifier
      // Value is true when authenticated/guest, false when unauthenticated
      final isAuthenticated = authStateNotifier.value;
      final isLoggingIn = state.matchedLocation == '/login';

      // If not authenticated and not on login page, redirect to login
      // This handles logout - when user signs out, auth state becomes unauthenticated
      // and router will automatically redirect to login screen
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // If authenticated (or guest) and on login page, redirect to home
      // This prevents authenticated users from accessing the login screen
      if (isAuthenticated && isLoggingIn) {
        return '/';
      }

      // Allow access to all other routes (home, settings, etc.)
      // Settings screen handles its own UI based on auth state
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/schedule/detail',
        builder: (context, state) {
          // Get schedule entry from route extra parameter
          final ScheduleEntryEntity? entry = state.extra as ScheduleEntryEntity?;
          if (entry == null) {
            // If entry is missing, navigate back to home
            // This shouldn't happen in normal flow, but handle gracefully
            return const HomeScreen();
          }
          return ScheduleDetailScreen(entry: entry);
        },
      ),
    ],
  );
}

