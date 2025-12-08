import '../../core/errors/failures.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/auth_error_mapper.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl();

  @override
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return Result.failure(
          const AuthFailure('Sign in failed: No user returned'),
        );
      }

      final user = UserModel(
        id: response.user!.id,
        email: response.user!.email,
        name: response.user!.userMetadata?['name'] as String?,
        isGuest: false,
      );

      return Result.success(user.toEntity());
    } catch (e) {
      // Map technical Supabase errors to user-friendly messages
      final userFriendlyMessage = AuthErrorMapper.mapError(e);
      return Result.failure(
        AuthFailure(userFriendlyMessage),
      );
    }
  }

  @override
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      // Sign up the user with Supabase
      // If email confirmation is disabled in Supabase settings, a session will be returned
      // and the user will be automatically signed in
      // If email confirmation is enabled, only a user will be returned (no session)
      // and the user needs to confirm their email before signing in
      final response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      if (response.user == null) {
        return Result.failure(
          const AuthFailure('Sign up failed: No user returned'),
        );
      }

      // Note: If email confirmation is disabled in Supabase dashboard settings,
      // response.session will contain a session and the user is automatically signed in.
      // If email confirmation is enabled, response.session will be null and the user
      // needs to confirm their email before they can sign in.
      // The session is automatically stored by Supabase if it exists, so we don't
      // need to manually handle it here - the auth state will be updated automatically
      // through the session manager's auth state change listener.

      final user = UserModel(
        id: response.user!.id,
        email: response.user!.email,
        name: name ?? response.user!.userMetadata?['name'] as String?,
        isGuest: false,
      );

      return Result.success(user.toEntity());
    } catch (e) {
      // Map technical Supabase errors to user-friendly messages
      final userFriendlyMessage = AuthErrorMapper.mapError(e);
      return Result.failure(
        AuthFailure(userFriendlyMessage),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await SupabaseService.auth.signOut();
      return const Result.success(null);
    } catch (e) {
      // Map technical Supabase errors to user-friendly messages
      final userFriendlyMessage = AuthErrorMapper.mapError(e);
      return Result.failure(
        AuthFailure(userFriendlyMessage),
      );
    }
  }

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    try {
      final user = SupabaseService.auth.currentUser;
      
      if (user == null) {
        return const Result.success(null);
      }

      final userEntity = UserModel(
        id: user.id,
        email: user.email,
        name: user.userMetadata?['name'] as String?,
        isGuest: false,
      );

      return Result.success(userEntity.toEntity());
    } catch (e) {
      // Map technical Supabase errors to user-friendly messages
      final userFriendlyMessage = AuthErrorMapper.mapError(e);
      return Result.failure(
        AuthFailure(userFriendlyMessage),
      );
    }
  }

  @override
  Future<Result<UserEntity>> createGuestUser() async {
    try {
      // Generate a unique guest ID
      final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      
      final user = UserModel(
        id: guestId,
        email: null,
        name: 'Guest User',
        isGuest: true,
      );

      return Result.success(user.toEntity());
    } catch (e) {
      return Result.failure(
        AuthFailure('Create guest user failed: ${e.toString()}'),
      );
    }
  }

  @override
  bool isAuthenticated() {
    try {
      return SupabaseService.auth.currentUser != null;
    } catch (e) {
      return false;
    }
  }
}

