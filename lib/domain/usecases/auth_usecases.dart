import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in
class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) {
    return repository.signIn(email: email, password: password);
  }
}

/// Use case for signing up
class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
    String? name,
  }) {
    return repository.signUp(
      email: email,
      password: password,
      name: name,
    );
  }
}

/// Use case for signing out
class SignOutUseCase {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  Future<Result<void>> call() {
    return repository.signOut();
  }
}

/// Use case for getting current user
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Result<UserEntity?>> call() {
    return repository.getCurrentUser();
  }
}

/// Use case for creating guest user
class CreateGuestUserUseCase {
  final AuthRepository repository;

  CreateGuestUserUseCase(this.repository);

  Future<Result<UserEntity>> call() {
    return repository.createGuestUser();
  }
}

