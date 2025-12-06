import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

/// Server failure - when API calls fail
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Network failure - when there's no internet connection
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Cache failure - when local cache operations fail
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Authentication failure - when auth operations fail
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Validation failure - when input validation fails
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Location failure - when location services fail
class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

/// GTFS parsing failure - when GTFS data parsing fails
class GtfsParsingFailure extends Failure {
  const GtfsParsingFailure(super.message);
}

