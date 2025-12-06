import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Result type for operations that can fail
class Result<T> {
  final T? data;
  final Failure? failure;
  final bool isSuccess;

  const Result.success(this.data)
      : failure = null,
        isSuccess = true;

  const Result.failure(this.failure)
      : data = null,
        isSuccess = false;
  
  T? get value => data;
  Failure? get error => failure;
}

abstract class AuthRepository {
  /// Sign in with email and password
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  });
  
  /// Sign up with email and password
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    String? name,
  });
  
  /// Sign out current user
  Future<Result<void>> signOut();
  
  /// Get current user
  Future<Result<UserEntity?>> getCurrentUser();
  
  /// Create guest user
  Future<Result<UserEntity>> createGuestUser();
  
  /// Check if user is authenticated
  bool isAuthenticated();
}

