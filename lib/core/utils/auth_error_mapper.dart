import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class for mapping Supabase authentication errors to user-friendly messages
/// 
/// This class provides a centralized way to translate technical Supabase error
/// messages into clear, actionable messages that users can understand. It handles
/// common authentication errors such as invalid credentials, email already registered,
/// weak passwords, network issues, and server errors.
/// 
/// The mapper extracts error information from Supabase exceptions and returns
/// appropriate user-friendly messages while hiding technical implementation details.
class AuthErrorMapper {
  /// Maps a Supabase authentication error to a user-friendly message
  /// 
  /// This method analyzes the error object and extracts relevant information
  /// (error code, message, status code) to determine the most appropriate
  /// user-friendly message. It handles various error types including:
  /// - Invalid credentials
  /// - Email already registered
  /// - Weak passwords
  /// - Network connectivity issues
  /// - Server errors
  /// - Email verification requirements
  /// - Rate limiting
  /// 
  /// [error] - The exception thrown by Supabase authentication operations
  /// 
  /// Returns: A user-friendly error message string
  static String mapError(dynamic error) {
    // Handle AuthException (common Supabase auth error type)
    if (error is AuthException) {
      return _mapAuthException(error);
    }
    
    // Handle generic Exception with string message
    if (error is Exception) {
      final errorMessage = error.toString().toLowerCase();
      return _mapGenericError(errorMessage);
    }
    
    // Handle string errors
    if (error is String) {
      return _mapGenericError(error.toLowerCase());
    }
    
    // Fallback for unknown error types
    final errorString = error.toString().toLowerCase();
    return _mapGenericError(errorString);
  }
  
  /// Maps AuthException to user-friendly message
  /// 
  /// Analyzes the AuthException's message and status code to determine
  /// the appropriate user-friendly message.
  /// 
  /// [exception] - The AuthException from Supabase
  /// 
  /// Returns: User-friendly error message
  static String _mapAuthException(AuthException exception) {
    final message = exception.message.toLowerCase();
    final statusCode = exception.statusCode;
    
    // Check for specific error messages
    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials') ||
        message.contains('email or password')) {
      return 'Invalid email or password. Please try again.';
    }
    
    // Check status code for 400 (Bad Request) which often indicates invalid credentials
    if (statusCode != null) {
      final statusCodeInt = int.tryParse(statusCode.toString());
      if (statusCodeInt == 400) {
        return 'Invalid email or password. Please try again.';
      }
      if (statusCodeInt != null && statusCodeInt >= 500) {
        return 'Something went wrong. Please try again later.';
      }
      if (statusCodeInt == 429) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
    }
    
    if (message.contains('email already registered') ||
        message.contains('user already registered') ||
        message.contains('already exists')) {
      return 'This email is already registered. Please sign in instead.';
    }
    
    if (message.contains('password') && message.contains('weak')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    
    if (message.contains('email not confirmed') ||
        message.contains('email not verified')) {
      return 'Please verify your email address before signing in.';
    }
    
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('unreachable')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    
    // Fallback to generic message
    return 'An error occurred. Please try again.';
  }
  
  /// Maps generic error strings to user-friendly messages
  /// 
  /// Analyzes error message strings for common patterns and returns
  /// appropriate user-friendly messages.
  /// 
  /// [errorMessage] - The error message in lowercase
  /// 
  /// Returns: User-friendly error message
  static String _mapGenericError(String errorMessage) {
    // Check for specific error patterns in the message
    if (errorMessage.contains('invalid login credentials') ||
        errorMessage.contains('invalid credentials') ||
        errorMessage.contains('email or password')) {
      return 'Invalid email or password. Please try again.';
    }
    
    if (errorMessage.contains('email already registered') ||
        errorMessage.contains('user already registered') ||
        errorMessage.contains('already exists')) {
      return 'This email is already registered. Please sign in instead.';
    }
    
    if (errorMessage.contains('password') && errorMessage.contains('weak')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    
    if (errorMessage.contains('email not confirmed') ||
        errorMessage.contains('email not verified')) {
      return 'Please verify your email address before signing in.';
    }
    
    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('unreachable') ||
        errorMessage.contains('socket')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    
    if (errorMessage.contains('server error') ||
        errorMessage.contains('internal server') ||
        errorMessage.contains('500')) {
      return 'Something went wrong. Please try again later.';
    }
    
    if (errorMessage.contains('rate limit') ||
        errorMessage.contains('too many') ||
        errorMessage.contains('429')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    
    // Fallback for unknown errors - remove technical details
    // Extract only the meaningful part if it contains technical prefixes
    if (errorMessage.contains('authapierror:') ||
        errorMessage.contains('authexception:')) {
      // Try to extract the meaningful part after the error type
      final parts = errorMessage.split(':');
      if (parts.length > 1) {
        final meaningfulPart = parts.sublist(1).join(':').trim();
        if (meaningfulPart.isNotEmpty) {
          return _mapGenericError(meaningfulPart);
        }
      }
    }
    
    // Final fallback - generic user-friendly message
    return 'An error occurred. Please try again.';
  }
}

