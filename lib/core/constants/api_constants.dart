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
  /// Uses MRT Feeder as the default agency as per requirements.
  static const String defaultAgency = 'rapid-bus-mrtfeeder';
  
  // Malaysian Transit Agency Codes
  
  /// Prasarana Rapid Rail KL agency code
  static const String agencyRapidRailKl = 'rapid-rail-kl';
  
  /// Prasarana Rapid Bus KL agency code
  static const String agencyRapidBusKl = 'rapid-bus-kl';
  
  /// Prasarana Rapid Bus Penang agency code
  static const String agencyRapidBusPenang = 'rapid-bus-penang';
  
  /// Prasarana Rapid Bus Kuantan agency code
  static const String agencyRapidBusKuantan = 'rapid-bus-kuantan';
  
  /// Prasarana Rapid Bus MRT Feeder agency code
  static const String agencyRapidBusMrtfeeder = 'rapid-bus-mrtfeeder';
  
  /// KTMB (Keretapi Tanah Melayu Berhad) national railway operator
  static const String agencyKtmb = 'ktmb';
  
  /// BAS.MY Kangar agency code
  static const String agencyBasKangar = 'mybas-kangar';
  
  /// BAS.MY Alor Setar agency code
  static const String agencyBasAlorSetar = 'mybas-alor-setar';
  
  /// BAS.MY Kota Bharu agency code
  static const String agencyBasKotaBharu = 'mybas-kota-bharu';
  
  /// BAS.MY Kuala Terengganu agency code
  static const String agencyBasKualaTerengganu = 'mybas-kuala-terengganu';
  
  /// BAS.MY Ipoh agency code
  static const String agencyBasIpoh = 'mybas-ipoh';
  
  /// BAS.MY Seremban A agency code
  static const String agencyBasSerembanA = 'mybas-seremban-a';
  
  /// BAS.MY Seremban B agency code
  static const String agencyBasSerembanB = 'mybas-seremban-b';
  
  /// BAS.MY Melaka agency code
  static const String agencyBasMelaka = 'mybas-melaka';
  
  /// BAS.MY Johor agency code
  static const String agencyBasJohor = 'mybas-johor';
  
  /// BAS.MY Kuching agency code
  static const String agencyBasKuching = 'mybas-kuching';
  
  /// List of all available Malaysian transit agencies
  static const List<String> availableAgencies = [
    agencyKtmb,
    agencyRapidRailKl,
    agencyRapidBusKl,
    agencyRapidBusPenang,
    agencyRapidBusKuantan,
    agencyRapidBusMrtfeeder,
    agencyBasKangar,
    agencyBasAlorSetar,
    agencyBasKotaBharu,
    agencyBasKualaTerengganu,
    agencyBasIpoh,
    agencyBasSerembanA,
    agencyBasSerembanB,
    agencyBasMelaka,
    agencyBasJohor,
    agencyBasKuching,
  ];
  
  /// List of Prasarana agencies (require category parameter)
  static const List<String> prasaranaAgencies = [
    agencyRapidRailKl,
    agencyRapidBusKl,
    agencyRapidBusPenang,
    agencyRapidBusKuantan,
    agencyRapidBusMrtfeeder,
  ];
  
  /// Prasarana category options for bus services
  /// 
  /// These categories are used as query parameters when fetching data
  /// from Prasarana agencies. Each category represents a specific service type.
  static const List<String> prasaranaCategories = [
    agencyRapidBusKl,
    agencyRapidBusMrtfeeder,
    agencyRapidBusKuantan,
    agencyRapidBusPenang,
  ];
  
  // GTFS Realtime Feed Types
  
  /// Vehicle positions feed type
  /// Note: API uses singular "vehicle-position" not "vehicle-positions"
  static const String feedVehiclePositions = 'vehicle-position';
  
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
  
  /// Gets the available Prasarana categories for a given agency
  /// 
  /// For Prasarana bus agencies, this returns the list of valid category
  /// options that can be used as query parameters. For non-Prasarana agencies
  /// or Prasarana rail, returns an empty list.
  /// 
  /// [agency] - The agency code to get categories for
  /// 
  /// Returns: List of valid category codes for the agency, or empty list if not applicable
  static List<String> getPrasaranaCategories(String agency) {
    // Only bus services have category options
    if (agency == agencyRapidBusKl || 
        agency == agencyRapidBusPenang || 
        agency == agencyRapidBusKuantan ||
        agency == agencyRapidBusMrtfeeder) {
      return prasaranaCategories;
    }
    // Rail services don't use categories
    return [];
  }
}

