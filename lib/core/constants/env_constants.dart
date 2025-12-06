/// Environment configuration for API keys and sensitive configuration
/// 
/// This class provides access to environment variables that contain sensitive
/// configuration data such as API keys and service URLs. These values should be
/// loaded from environment variables at compile time using --dart-define flags.
/// 
/// In production, these should be loaded from environment variables or a secure
/// configuration file that is not committed to version control. Never commit
/// actual API keys to the repository.
class EnvConstants {
  /// Supabase project URL
  /// 
  /// This is the URL of your Supabase project, used for initializing the
  /// Supabase client. Should be provided via --dart-define SUPABASE_URL=your_url
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  /// Supabase anonymous key
  /// 
  /// This is the anonymous/public key for your Supabase project, used for
  /// client-side operations. Should be provided via --dart-define SUPABASE_ANON_KEY=your_key
  /// 
  /// Note: This is a public key, but it should still be kept secure and not
  /// committed to version control.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  
  /// Mapbox access token
  /// 
  /// This is the access token for Mapbox services, used for map rendering
  /// and geocoding. Should be provided via --dart-define MAPBOX_ACCESS_TOKEN=your_token
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );
  
  /// Google Maps API key
  /// 
  /// This is the API key for Google Maps services, used for route planning
  /// and directions. Should be provided via --dart-define GOOGLE_MAPS_API_KEY=your_key
  /// 
  /// Note: This key is optional and only needed if using Google Maps features.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  
  /// Checks if all required environment variables are configured
  /// 
  /// This method verifies that the essential environment variables (Supabase URL,
  /// Supabase anon key, and Mapbox access token) are set. If any are missing,
  /// the app may not function correctly.
  /// 
  /// Returns: true if all required variables are set, false otherwise
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
           supabaseAnonKey.isNotEmpty &&
           mapboxAccessToken.isNotEmpty;
  }
}

