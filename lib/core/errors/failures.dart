import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// 
/// This abstract class provides a common interface for all error types
/// in the application. It extends Equatable to enable value-based equality
/// comparisons, which is useful for testing and state management.
/// 
/// All failures contain a message describing what went wrong, which can
/// be displayed to users or logged for debugging purposes.
abstract class Failure extends Equatable {
  /// Human-readable error message describing the failure
  final String message;
  
  /// Creates a Failure with the given error message
  /// 
  /// [message] - Description of what went wrong
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

/// Server failure - occurs when API calls to the server fail
/// 
/// This failure type is used when the server returns an error response,
/// such as 4xx or 5xx HTTP status codes, or when the server is unreachable.
/// 
/// Example: Server returns 500 Internal Server Error
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Network failure - occurs when there's no internet connection
/// 
/// This failure type is used when network requests fail due to connectivity
/// issues, such as no internet connection, timeout, or DNS resolution failures.
/// 
/// Example: No internet connection available
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Cache failure - occurs when local cache operations fail
/// 
/// This failure type is used when reading from or writing to the local cache
/// fails, such as when the cache file is corrupted or disk space is unavailable.
/// 
/// Example: Failed to read cached data from disk
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Authentication failure - occurs when auth operations fail
/// 
/// This failure type is used when authentication-related operations fail,
/// such as invalid credentials, expired tokens, or permission denials.
/// 
/// Example: Invalid email or password
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Validation failure - occurs when input validation fails
/// 
/// This failure type is used when user input or data doesn't meet the
/// required validation criteria, such as invalid email format or missing
/// required fields.
/// 
/// Example: Email address is not in valid format
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Location failure - occurs when location services fail
/// 
/// This failure type is used when location-related operations fail,
/// such as when location services are disabled, permissions are denied,
/// or GPS cannot determine the current position.
/// 
/// Example: Location permissions are denied
class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

/// GTFS parsing failure - occurs when GTFS data parsing fails
/// 
/// This failure type is used when parsing GTFS (General Transit Feed Specification)
/// data fails, such as when the data format is invalid or corrupted.
/// 
/// Example: Invalid GTFS feed format
class GtfsParsingFailure extends Failure {
  const GtfsParsingFailure(super.message);
}

/// GTFS data quality failure - occurs when GTFS data has quality issues
/// 
/// This failure type is used when the GTFS API returns data with quality warnings
/// such as E028 (GPS coordinates outside service area), E003/E004 (legacy system issues),
/// or trip ID mismatches. These are warnings that don't prevent data display but
/// indicate potential data quality issues.
/// 
/// [errorCode] - The specific GTFS error code (e.g., 'E028', 'E003', 'E004')
/// [message] - Human-readable description of the data quality issue
/// 
/// Example: GPS coordinates outside service area (E028)
class GtfsDataQualityFailure extends Failure {
  /// The specific GTFS error code associated with this failure
  /// 
  /// Common codes:
  /// - E028: GPS coordinates outside service area
  /// - E003: Legacy system issue (Prasarana)
  /// - E004: Legacy system issue (Prasarana)
  final String errorCode;
  
  /// Creates a GtfsDataQualityFailure with the given error code and message
  /// 
  /// [errorCode] - The GTFS error code (e.g., 'E028')
  /// [message] - Description of the data quality issue
  const GtfsDataQualityFailure({
    required this.errorCode,
    required String message,
  }) : super(message);
  
  @override
  List<Object> get props => [errorCode, message];
}

