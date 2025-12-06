import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && !user!.isGuest;
  bool get isGuest => user != null && user!.isGuest;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final CreateGuestUserUseCase createGuestUserUseCase;

  AuthNotifier({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.createGuestUserUseCase,
  }) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final result = await getCurrentUserUseCase();
    state = state.copyWith(
      user: result.data,
      isLoading: false,
    );
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await signInUseCase(email: email, password: password);
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        user: result.data,
        isLoading: false,
        error: null,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Sign in failed',
      );
      return false;
    }
  }

  Future<bool> signUp(String email, String password, {String? name}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await signUpUseCase(
      email: email,
      password: password,
      name: name,
    );
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        user: result.data,
        isLoading: false,
        error: null,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Sign up failed',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await signOutUseCase();
    state = const AuthState();
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await createGuestUserUseCase();
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        user: result.data,
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Failed to create guest user',
      );
    }
  }
}

