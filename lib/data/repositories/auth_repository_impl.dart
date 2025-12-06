import '../../core/errors/failures.dart';
import '../../core/services/supabase_service.dart';
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
      return Result.failure(
        AuthFailure('Sign in failed: ${e.toString()}'),
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

      final user = UserModel(
        id: response.user!.id,
        email: response.user!.email,
        name: name ?? response.user!.userMetadata?['name'] as String?,
        isGuest: false,
      );

      return Result.success(user.toEntity());
    } catch (e) {
      return Result.failure(
        AuthFailure('Sign up failed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await SupabaseService.auth.signOut();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        AuthFailure('Sign out failed: ${e.toString()}'),
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
      return Result.failure(
        AuthFailure('Get current user failed: ${e.toString()}'),
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

