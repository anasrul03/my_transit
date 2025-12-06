import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'router/app_router.dart';

/// Main entry point for the MyTransit application
/// 
/// This function initializes the app by:
/// 1. Ensuring Flutter bindings are initialized
/// 2. Setting up Mapbox with access token from environment
/// 3. Initializing Supabase (if configured)
/// 4. Running the app with Riverpod ProviderScope
void main() async {
  // Initialize Flutter bindings (required before any Flutter operations)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Mapbox with access token from environment
  // Token should be passed via --dart-define ACCESS_TOKEN=your_token
  // If not provided, map features will not work but the app will still run
  const String accessToken = String.fromEnvironment('ACCESS_TOKEN');
  if (accessToken.isNotEmpty) {
    MapboxOptions.setAccessToken(accessToken);
    debugPrint('✅ Mapbox access token configured');
  } else {
    debugPrint('⚠️ WARNING: Mapbox ACCESS_TOKEN not provided. Map features will not work.');
    debugPrint('⚠️ To fix: Run with --dart-define ACCESS_TOKEN=pk.your_token_here');
    debugPrint('⚠️ Get token from: https://account.mapbox.com/access-tokens/');
  }
  
  // Initialize Supabase (will only initialize if env vars are set)
  // If Supabase is not configured, the app continues without it
  // This allows the app to work with or without Supabase authentication
  try {
    await SupabaseService.initialize();
  } catch (e) {
    // Continue without Supabase if not configured
    debugPrint('Supabase initialization skipped: $e');
  }
  
  // Run the app with Riverpod ProviderScope for state management
  runApp(
    const ProviderScope(
      child: MyTransitApp(),
    ),
  );
}

/// Root widget of the MyTransit application
/// 
/// This widget sets up the MaterialApp with routing, theme, and Riverpod
/// integration. It watches the router provider to get the current router
/// configuration for navigation.
class MyTransitApp extends ConsumerWidget {
  const MyTransitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider to get the current router configuration
    final GoRouter router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'MyTransit',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
