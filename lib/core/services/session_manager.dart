import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for managing user session persistence and restoration
/// 
/// This service handles waiting for Supabase to restore sessions from secure
/// storage on app startup. It ensures that authentication status is only checked
/// after the session has been fully restored, preventing users from being
/// logged out unnecessarily after app restarts.
/// 
/// The service also listens to Supabase auth state changes to keep the app
/// in sync with authentication state changes that occur outside the app
/// (e.g., token refresh, session expiration).
class SessionManager {
  /// Completer to signal when initial session restoration is complete
  /// This ensures we wait for Supabase to restore the session from storage
  /// before checking authentication status
  final Completer<void> _initialRestorationCompleter = Completer<void>();
  
  /// Stream subscription for auth state changes
  /// This keeps the app in sync with authentication state changes
  StreamSubscription<AuthState>? _authStateSubscription;
  
  /// Flag to track if initial restoration has been completed
  bool _isInitialRestorationComplete = false;
  
  /// Flag to track if the session manager has been initialized
  bool _isInitialized = false;

  /// Initializes the session manager and waits for session restoration
  /// 
  /// This method should be called after Supabase is initialized. It sets up
  /// a listener for auth state changes and waits for the initial session
  /// to be restored from secure storage.
  /// 
  /// Returns: Future that completes when initial session restoration is done
  /// 
  /// Note: This method is idempotent - calling it multiple times will
  /// return the same future if already initialized
  Future<void> initialize() async {
    // If already initialized, return the existing completer future
    if (_isInitialized) {
      return _initialRestorationCompleter.future;
    }
    
    _isInitialized = true;
    
    try {
      // Check if Supabase is configured before setting up listeners
      // If not configured, complete immediately without waiting
      if (!_isSupabaseConfigured()) {
        _initialRestorationCompleter.complete();
        _isInitialRestorationComplete = true;
        return;
      }
      
      // Set up listener for auth state changes
      // The first event will be the initial session restoration
      _authStateSubscription = SupabaseService.auth.onAuthStateChange.listen(
        (AuthState authState) {
          // Mark initial restoration as complete on first auth state event
          // This happens when Supabase restores the session from storage
          if (!_isInitialRestorationComplete) {
            _isInitialRestorationComplete = true;
            if (!_initialRestorationCompleter.isCompleted) {
              _initialRestorationCompleter.complete();
            }
          }
        },
        onError: (Object error) {
          // If there's an error during restoration, complete anyway
          // to prevent the app from hanging
          if (!_isInitialRestorationComplete) {
            _isInitialRestorationComplete = true;
            if (!_initialRestorationCompleter.isCompleted) {
              _initialRestorationCompleter.complete();
            }
          }
        },
      );
      
      // Wait for initial session restoration with a timeout
      // This ensures the app doesn't hang if something goes wrong
      await _initialRestorationCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // If timeout occurs, mark as complete anyway
          // This allows the app to continue even if restoration is slow
          if (!_initialRestorationCompleter.isCompleted) {
            _initialRestorationCompleter.complete();
          }
          _isInitialRestorationComplete = true;
        },
      );
    } catch (e) {
      // If any error occurs, complete the completer to prevent hanging
      if (!_initialRestorationCompleter.isCompleted) {
        _initialRestorationCompleter.complete();
      }
      _isInitialRestorationComplete = true;
    }
  }

  /// Checks if Supabase is configured and available
  /// 
  /// Returns: true if Supabase is configured, false otherwise
  bool _isSupabaseConfigured() {
    try {
      // Try to access the Supabase client
      // If it's not initialized, this will throw an exception
      SupabaseService.client;
      return true;
    } catch (e) {
      // Supabase is not configured or not initialized
      return false;
    }
  }

  /// Disposes the session manager and cleans up resources
  /// 
  /// This should be called when the app is shutting down or when
  /// the session manager is no longer needed.
  void dispose() {
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _isInitialized = false;
    _isInitialRestorationComplete = false;
  }

  /// Gets a stream of auth state changes
  /// 
  /// This stream emits events whenever the authentication state changes,
  /// such as when a user signs in, signs out, or when a session is restored.
  /// 
  /// Returns: Stream of AuthState events from Supabase
  /// 
  /// Note: Returns an empty stream if Supabase is not configured
  Stream<AuthState> get authStateChanges {
    if (!_isSupabaseConfigured()) {
      return const Stream<AuthState>.empty();
    }
    return SupabaseService.auth.onAuthStateChange;
  }
}

/// Global instance of SessionManager
/// 
/// This singleton instance is used throughout the app to manage sessions.
/// It should be initialized in main.dart after Supabase is initialized.
final SessionManager sessionManager = SessionManager();

