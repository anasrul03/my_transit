import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../core/services/session_manager.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// Use case providers
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.read(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.read(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.read(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

final createGuestUserUseCaseProvider = Provider<CreateGuestUserUseCase>((ref) {
  return CreateGuestUserUseCase(ref.read(authRepositoryProvider));
});

// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) {
    return AuthNotifier(
      signInUseCase: ref.read(signInUseCaseProvider),
      signUpUseCase: ref.read(signUpUseCaseProvider),
      signOutUseCase: ref.read(signOutUseCaseProvider),
      getCurrentUserUseCase: ref.read(getCurrentUserUseCaseProvider),
      createGuestUserUseCase: ref.read(createGuestUserUseCaseProvider),
    );
  },
);

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  bool get isAuthenticated => user != null && !user!.isGuest;
  bool get isGuest => user != null && user!.isGuest;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final CreateGuestUserUseCase createGuestUserUseCase;
  
  /// Stream subscription for Supabase auth state changes
  /// This keeps the app in sync with authentication state changes
  /// that occur outside the app (e.g., token refresh, session expiration)
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  AuthNotifier({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.createGuestUserUseCase,
  }) : super(const AuthState()) {
    _initialize();
  }

  /// Initializes the auth notifier by waiting for session restoration
  /// and setting up auth state change listeners
  /// 
  /// This ensures that we wait for Supabase to restore the session from
  /// secure storage before checking authentication status, preventing
  /// users from being logged out after app restarts.
  Future<void> _initialize() async {
    // Wait for session restoration to complete before checking auth status
    // This ensures Supabase has loaded the session from secure storage
    await sessionManager.initialize();
    
    // Set up listener for auth state changes from Supabase
    // This keeps the app in sync with authentication state changes
    _authStateSubscription = sessionManager.authStateChanges.listen(
      (authState) {
        // When auth state changes, update our local state
        // This handles cases like token refresh, session expiration, etc.
        _checkAuthStatus();
      },
    );
    
    // Now check the current auth status after session restoration
    await _checkAuthStatus();
  }

  /// Checks the current authentication status
  /// 
  /// This method queries the auth repository to get the current user.
  /// It should only be called after session restoration is complete
  /// to ensure accurate authentication status.
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final result = await getCurrentUserUseCase();
    state = state.copyWith(
      user: result.data,
      isLoading: false,
    );
  }
  
  @override
  void dispose() {
    // Cancel the auth state subscription when the notifier is disposed
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    super.dispose();
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await signInUseCase(email: email, password: password);
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        user: result.data,
        isLoading: false,
        error: null,
        successMessage: 'Welcome back!',
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Sign in failed',
        successMessage: null,
      );
      return false;
    }
  }

  Future<bool> signUp(String email, String password, {String? name}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await signUpUseCase(
      email: email,
      password: password,
      name: name,
    );
    
    if (result.isSuccess && result.data != null) {
      // After successful signup, check if user is already signed in
      // This happens when email confirmation is disabled in Supabase
      // If a session was returned during signup, the user is automatically signed in
      // We need to refresh the auth status to get the current session state
      await _checkAuthStatus();
      
      // Check if the user is now authenticated (session was created)
      final bool isNowAuthenticated = state.user != null && !state.user!.isGuest;
      
      if (isNowAuthenticated) {
        // User is automatically signed in (email confirmation disabled)
        state = state.copyWith(
          isLoading: false,
          error: null,
          successMessage: 'Account created successfully! You are now signed in.',
        );
      } else {
        // User needs to confirm email before signing in (email confirmation enabled)
        state = state.copyWith(
          user: result.data,
          isLoading: false,
          error: null,
          successMessage: 'Account created! Please check your email to confirm your account before signing in.',
        );
      }
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Sign up failed',
        successMessage: null,
      );
      return false;
    }
  }

  /// Signs out the current user
  /// 
  /// Attempts to sign out the user from Supabase. If successful, clears the
  /// auth state. If it fails, updates the state with an error message.
  /// 
  /// The router will automatically redirect to the login screen when the
  /// auth state changes to unauthenticated.
  /// 
  /// Note: Success message for sign out is handled in the UI layer since
  /// the state is cleared on successful logout.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await signOutUseCase();
    
    if (result.isSuccess) {
      // Clear auth state on successful logout
      // Router will automatically redirect to login screen
      // Success message is shown in UI before state is cleared
      state = const AuthState();
    } else {
      // Update state with error message if logout fails
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Sign out failed',
        successMessage: null,
      );
    }
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    final result = await createGuestUserUseCase();
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        user: result.data,
        isLoading: false,
        error: null,
        successMessage: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Failed to create guest user',
        successMessage: null,
      );
    }
  }
}

