import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Mapbox with access token from environment
  // Token should be passed via --dart-define ACCESS_TOKEN=your_token
  const String accessToken = String.fromEnvironment('ACCESS_TOKEN');
  if (accessToken.isNotEmpty) {
    MapboxOptions.setAccessToken(accessToken);
  } else {
    debugPrint('Warning: Mapbox ACCESS_TOKEN not provided. Map features will not work.');
  }
  
  // Initialize Supabase (will only initialize if env vars are set)
  try {
    await SupabaseService.initialize();
  } catch (e) {
    // Continue without Supabase if not configured
    debugPrint('Supabase initialization skipped: $e');
  }
  
  runApp(
    const ProviderScope(
      child: MyTransitApp(),
    ),
  );
}

class MyTransitApp extends ConsumerWidget {
  const MyTransitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'MyTransit',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
