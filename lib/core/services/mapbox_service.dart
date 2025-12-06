class MapboxService {
  /// Get access token from environment (set via --dart-define)
  static String get accessToken {
    const token = String.fromEnvironment('ACCESS_TOKEN');
    return token;
  }
  
  static bool get isConfigured => accessToken.isNotEmpty;
  
  /// Mapbox style URLs
  static String get standardStyleUrl => 'mapbox://styles/mapbox/standard';
  static String get streetsStyleUrl => 'mapbox://styles/mapbox/streets-v12';
  static String get outdoorsStyleUrl => 'mapbox://styles/mapbox/outdoors-v12';
  static String get lightStyleUrl => 'mapbox://styles/mapbox/light-v11';
  static String get darkStyleUrl => 'mapbox://styles/mapbox/dark-v11';
  static String get satelliteStyleUrl => 'mapbox://styles/mapbox/satellite-v9';
  static String get satelliteStreetsStyleUrl => 'mapbox://styles/mapbox/satellite-streets-v12';
  static String get navigationDayStyleUrl => 'mapbox://styles/mapbox/navigation-day-v1';
  static String get navigationNightStyleUrl => 'mapbox://styles/mapbox/navigation-night-v1';
}

