class ApiConstants {
  // GTFS Realtime API
  static const String gtfsRealtimeBaseUrl = 
      'https://developer.data.gov.my/realtime-api/gtfs-realtime';
  
  // GTFS Static API
  static const String gtfsStaticBaseUrl = 
      'https://developer.data.gov.my/realtime-api/gtfs-static';
  
  // API endpoints
  static const String gtfsRealtimeEndpoint = '/vehicle-positions';
  static const String gtfsStaticEndpoint = '/static';
  
  // Polling intervals
  static const Duration realtimePollInterval = Duration(seconds: 30);
  static const Duration interpolationInterval = Duration(milliseconds: 100);
  
  // Cache durations
  static const Duration staticGtfsCacheDuration = Duration(days: 1);
  
  // Default operator filter
  static const String defaultOperator = 'MRT Feeder';
}

