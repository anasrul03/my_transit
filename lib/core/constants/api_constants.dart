/// Constants for API endpoints, URLs, and configuration values
/// 
/// This class centralizes all API-related constants used throughout the application,
/// including base URLs, endpoints, polling intervals, cache durations, and default
/// configuration values. This makes it easy to update API endpoints or timing
/// configurations in one place.
class ApiConstants {
  /// Base URL for the GTFS Realtime API
  /// 
  /// This is the base URL for accessing real-time transit data from the
  /// Malaysian government's open data API.
  /// 
  /// API endpoint format: `/<feed>/<agency>` (e.g., `/vehicle-positions/rapidkl`)
  static const String gtfsRealtimeBaseUrl = 
      'https://api.data.gov.my/gtfs-realtime/';
  
  /// Base URL for the GTFS Static API
  /// 
  /// This is the base URL for accessing static transit data (routes, stops, schedules)
  /// from the Malaysian government's open data API.
  /// 
  /// API endpoint format: `/<agency>` (e.g., `/rapidkl`)
  static const String gtfsStaticBaseUrl = 
      'https://api.data.gov.my/gtfs-static';
  
  /// API endpoint for vehicle positions in the realtime API
  /// 
  /// This endpoint provides real-time vehicle position data for transit vehicles.
  /// Format: `/<feed>/<agency>` (e.g., `/vehicle-positions/rapidkl`)
  /// This is appended to the base URL to construct the full API endpoint.
  static const String gtfsRealtimeEndpoint = '';
  
  /// API endpoint for static GTFS data
  /// 
  /// This endpoint provides static transit data including routes, stops, and schedules.
  /// Format: `/<agency>` (e.g., `/rapidkl`)
  /// This is appended to the base URL to construct the full API endpoint.
  /// Note: Agency-specific endpoint should be provided when calling the API.
  static const String gtfsStaticEndpoint = '';
  
  /// Polling interval for real-time vehicle position updates
  /// 
  /// This determines how frequently the app fetches new vehicle position data
  /// from the realtime API. A 30-second interval balances data freshness with
  /// API load and battery consumption.
  static const Duration realtimePollInterval = Duration(seconds: 30);
  
  /// Interval for vehicle position interpolation updates
  /// 
  /// This determines how frequently vehicle positions are interpolated between
  /// real-time updates to provide smoother movement on the map. A 100ms interval
  /// provides smooth animation without excessive computation.
  static const Duration interpolationInterval = Duration(milliseconds: 100);
  
  /// Cache duration for static GTFS data
  /// 
  /// Static GTFS data (routes, stops, schedules) doesn't change frequently,
  /// so it can be cached for 1 day to reduce API calls and improve performance.
  static const Duration staticGtfsCacheDuration = Duration(days: 1);
  
  /// Default transit agency to filter by
  /// 
  /// This is the default agency shown when the app first loads. Users can
  /// change this filter to view vehicles from different agencies.
  /// Uses a valid Malaysian agency code (e.g., 'ktmb' or 'rapid-rail-kl').
  static const String defaultAgency = 'ktmb';
  
  // Malaysian Transit Agency Codes
  
  /// KTMB (Keretapi Tanah Melayu) agency code
  static const String agencyKtmb = 'ktmb';
  
  /// Prasarana Rapid Rail KL agency code
  static const String agencyRapidRailKl = 'rapid-rail-kl';
  
  /// Prasarana Rapid Bus KL agency code
  static const String agencyRapidBusKl = 'rapid-bus-kl';
  
  /// Prasarana Rapid Bus Penang agency code
  static const String agencyRapidBusPenang = 'rapid-bus-penang';
  
  /// Prasarana Rapid Bus Kuching agency code
  static const String agencyRapidBusKuching = 'rapid-bus-kuching';
  
  /// Prasarana Rapid Bus Kuantan agency code
  static const String agencyRapidBusKuantan = 'rapid-bus-kuantan';
  
  /// BAS Melaka agency code
  static const String agencyBasMelaka = 'bas-melaka';
  
  /// BAS Negeri Sembilan agency code
  static const String agencyBasNegeriSembilan = 'bas-negeri-sembilan';
  
  /// BAS Pahang agency code
  static const String agencyBasPahang = 'bas-pahang';
  
  /// BAS Perak agency code
  static const String agencyBasPerak = 'bas-perak';
  
  /// BAS Perlis agency code
  static const String agencyBasPerlis = 'bas-perlis';
  
  /// BAS Sabah agency code
  static const String agencyBasSabah = 'bas-sabah';
  
  /// BAS Sarawak agency code
  static const String agencyBasSarawak = 'bas-sarawak';
  
  /// BAS Terengganu agency code
  static const String agencyBasTerengganu = 'bas-terengganu';
  
  /// List of all available Malaysian transit agencies
  static const List<String> availableAgencies = [
    agencyKtmb,
    agencyRapidRailKl,
    agencyRapidBusKl,
    agencyRapidBusPenang,
    agencyRapidBusKuching,
    agencyRapidBusKuantan,
    agencyBasMelaka,
    agencyBasNegeriSembilan,
    agencyBasPahang,
    agencyBasPerak,
    agencyBasPerlis,
    agencyBasSabah,
    agencyBasSarawak,
    agencyBasTerengganu,
  ];
  
  /// List of Prasarana agencies (require category parameter)
  static const List<String> prasaranaAgencies = [
    agencyRapidRailKl,
    agencyRapidBusKl,
    agencyRapidBusPenang,
    agencyRapidBusKuching,
    agencyRapidBusKuantan,
  ];
  
  // GTFS Realtime Feed Types
  
  /// Vehicle positions feed type
  static const String feedVehiclePositions = 'vehicle-positions';
  
  /// Trip updates feed type
  static const String feedTripUpdates = 'trip-updates';
  
  /// Service alerts feed type
  static const String feedServiceAlerts = 'service-alerts';
  
  /// List of available feed types
  static const List<String> availableFeedTypes = [
    feedVehiclePositions,
    feedTripUpdates,
    feedServiceAlerts,
  ];
  
  /// Checks if an agency is a Prasarana agency (requires category parameter)
  /// 
  /// [agency] - The agency code to check
  /// 
  /// Returns: true if the agency requires a category parameter, false otherwise
  static bool isPrasaranaAgency(String agency) {
    return prasaranaAgencies.contains(agency);
  }
}

