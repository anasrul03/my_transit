import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env_constants.dart';
import 'session_manager.dart';

/// Service for managing Supabase client initialization and access
/// 
/// This service provides a centralized way to initialize and access the
/// Supabase client throughout the application. It ensures Supabase is only
/// initialized if the required environment variables are configured, preventing
/// runtime errors when Supabase is not needed.
/// 
/// The service provides static access to the Supabase client and auth client
/// for use throughout the application.
class SupabaseService {
  /// Initializes the Supabase client with configuration from environment variables
  /// 
  /// This method checks if Supabase is configured (via EnvConstants) before
  /// attempting initialization. If configuration is missing, it throws an
  /// exception with a helpful error message.
  /// 
  /// Throws: Exception if Supabase configuration is missing
  /// 
  /// This should be called during app startup (typically in main.dart)
  /// before any Supabase operations are performed.
  static Future<void> initialize() async {
    // Check if Supabase environment variables are configured
    // If not configured, throw an exception to prevent silent failures
    if (!EnvConstants.isConfigured) {
      throw Exception(
        'Supabase configuration missing. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.',
      );
    }
    
    // Initialize Supabase with the configured URL and anon key
    // This sets up the global Supabase instance for use throughout the app
    await Supabase.initialize(
      url: EnvConstants.supabaseUrl,
      anonKey: EnvConstants.supabaseAnonKey,
    );
  }
  
  /// Gets the Supabase client instance
  /// 
  /// Returns the initialized Supabase client for making database queries,
  /// storage operations, and other Supabase features.
  /// 
  /// Returns: SupabaseClient instance
  /// 
  /// Note: Supabase must be initialized before accessing the client
  static SupabaseClient get client => Supabase.instance.client;
  
  /// Gets the Supabase authentication client
  /// 
  /// Provides convenient access to the GoTrue authentication client
  /// for user authentication operations (sign in, sign up, sign out, etc.).
  /// 
  /// Returns: GoTrueClient instance for authentication operations
  static GoTrueClient get auth => client.auth;
  
  /// Waits for the initial session restoration to complete
  /// 
  /// This method ensures that Supabase has restored the session from secure
  /// storage before proceeding. This is important to prevent checking
  /// authentication status before the session is available, which would
  /// incorrectly show the user as logged out after app restarts.
  /// 
  /// Returns: Future that completes when initial session restoration is done
  /// 
  /// Note: This should be called after Supabase.initialize() and before
  /// checking authentication status. If Supabase is not configured, this
  /// returns immediately.
  static Future<void> waitForSessionRestoration() async {
    // Use the global session manager instance to wait for session restoration
    // The session manager will handle waiting for auth state restoration
    await sessionManager.initialize();
  }
}

