/// Service for managing Mapbox configuration and style URLs
/// 
/// This service provides access to the Mapbox access token (configured via
/// --dart-define) and provides convenient access to various Mapbox map style URLs.
/// It centralizes Mapbox-related configuration to ensure consistency across
/// the application.
class MapboxService {
  /// Gets the Mapbox access token from environment variables
  /// 
  /// The access token should be provided via --dart-define ACCESS_TOKEN=your_token
  /// when running the app. This token is required for Mapbox map functionality.
  /// 
  /// Returns: String containing the access token, or empty string if not configured
  static String get accessToken {
    const String token = String.fromEnvironment('ACCESS_TOKEN');
    return token;
  }
  
  /// Checks if Mapbox is properly configured
  /// 
  /// Returns true if an access token has been provided, false otherwise.
  /// This can be used to conditionally enable/disable map features.
  /// 
  /// Returns: bool indicating if Mapbox is configured
  static bool get isConfigured => accessToken.isNotEmpty;
  
  /// Mapbox style URLs for different map styles
  /// 
  /// These properties provide convenient access to various Mapbox map styles.
  /// Each style has different characteristics suitable for different use cases.
  
  /// Standard Mapbox style URL
  static String get standardStyleUrl => 'mapbox://styles/mapbox/standard';
  
  /// Streets style URL - detailed street map with labels
  static String get streetsStyleUrl => 'mapbox://styles/mapbox/streets-v12';
  
  /// Outdoors style URL - terrain-focused map for outdoor activities
  static String get outdoorsStyleUrl => 'mapbox://styles/mapbox/outdoors-v12';
  
  /// Light style URL - light-colored map suitable for daytime use
  static String get lightStyleUrl => 'mapbox://styles/mapbox/light-v11';
  
  /// Dark style URL - dark-colored map suitable for nighttime use
  static String get darkStyleUrl => 'mapbox://styles/mapbox/dark-v11';
  
  /// Satellite style URL - satellite imagery without labels
  static String get satelliteStyleUrl => 'mapbox://styles/mapbox/satellite-v9';
  
  /// Satellite streets style URL - satellite imagery with street labels
  static String get satelliteStreetsStyleUrl => 'mapbox://styles/mapbox/satellite-streets-v12';
  
  /// Navigation day style URL - optimized for navigation during daytime
  static String get navigationDayStyleUrl => 'mapbox://styles/mapbox/navigation-day-v1';
  
  /// Navigation night style URL - optimized for navigation during nighttime
  static String get navigationNightStyleUrl => 'mapbox://styles/mapbox/navigation-night-v1';
}

