import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'router/app_router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';

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
    // Wait for session restoration to complete before starting the app
    // This ensures that authentication status is checked only after
    // Supabase has restored the session from secure storage
    await SupabaseService.waitForSessionRestoration();
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
/// integration. It creates a router that reacts to auth state changes
/// using a ValueNotifier that is updated when auth state changes.
class MyTransitApp extends ConsumerStatefulWidget {
  const MyTransitApp({super.key});

  @override
  ConsumerState<MyTransitApp> createState() => _MyTransitAppState();
}

class _MyTransitAppState extends ConsumerState<MyTransitApp> {
  // ValueNotifier to track auth state for router refresh
  // This is updated whenever auth state changes
  late final ValueNotifier<bool> _authStateNotifier;
  
  // Router instance that reacts to auth state changes
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Initialize auth state notifier with false (unauthenticated)
    _authStateNotifier = ValueNotifier<bool>(false);
    // Create router with the auth state notifier
    _router = createRouter(_authStateNotifier);
  }

  @override
  void dispose() {
    // Dispose the notifier when widget is disposed
    _authStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state provider to update the notifier when auth changes
    final authState = ref.watch(authStateProvider);
    
    // Update the notifier value based on current auth state
    // This triggers router refresh and redirects when auth state changes
    final isAuthenticated = authState.isAuthenticated || authState.isGuest;
    if (_authStateNotifier.value != isAuthenticated) {
      // Update notifier value, which triggers router refresh
      _authStateNotifier.value = isAuthenticated;
    }
    
    // Watch theme mode provider to rebuild when theme changes
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'MyTransit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
