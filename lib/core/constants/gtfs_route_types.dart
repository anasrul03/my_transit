/// GTFS Route Type constants and utilities
/// 
/// Defines the standard GTFS route types and provides helper methods
/// for categorizing and identifying different transit modes.
/// 
/// Reference: https://developers.google.com/transit/gtfs/reference#routestxt
class GtfsRouteType {
  /// Light rail, Tram, Streetcar
  /// 
  /// Any light rail or street level system within a metropolitan area.
  static const int tram = 0;

  /// Subway, Metro
  /// 
  /// Any underground rail system within a metropolitan area.
  static const int subway = 1;

  /// Rail
  /// 
  /// Used for intercity or long-distance travel.
  static const int rail = 2;

  /// Bus
  /// 
  /// Used for short- and long-distance bus routes.
  static const int bus = 3;

  /// Ferry
  /// 
  /// Used for short- and long-distance boat service.
  static const int ferry = 4;

  /// Cable tram
  /// 
  /// Used for street-level rail cars where the cable runs beneath the vehicle.
  static const int cableTram = 5;

  /// Aerial lift, Suspended cable car
  /// 
  /// Cable transport where cabins are suspended from cables.
  static const int aerialLift = 6;

  /// Funicular
  /// 
  /// Any rail system designed for steep inclines.
  static const int funicular = 7;

  /// Trolleybus
  /// 
  /// Electric buses that draw power from overhead wires using poles.
  static const int trolleybus = 11;

  /// Monorail
  /// 
  /// Railway in which the track consists of a single rail or a beam.
  static const int monorail = 12;

  /// Checks if a route type is a rail-based transit mode
  /// 
  /// Includes tram, subway, rail, cable tram, funicular, and monorail.
  /// 
  /// [routeType] - The GTFS route type integer
  /// 
  /// Returns: true if the route type is rail-based, false otherwise
  static bool isRailType(int? routeType) {
    if (routeType == null) return false;
    
    return routeType == tram ||
           routeType == subway ||
           routeType == rail ||
           routeType == cableTram ||
           routeType == funicular ||
           routeType == monorail;
  }

  /// Checks if a route type is a bus-based transit mode
  /// 
  /// Includes bus and trolleybus.
  /// 
  /// [routeType] - The GTFS route type integer
  /// 
  /// Returns: true if the route type is bus-based, false otherwise
  static bool isBusType(int? routeType) {
    if (routeType == null) return false;
    
    return routeType == bus || routeType == trolleybus;
  }

  /// Gets a human-readable name for a route type
  /// 
  /// [routeType] - The GTFS route type integer
  /// 
  /// Returns: Display name for the route type, or "Unknown" if not recognized
  static String getDisplayName(int? routeType) {
    if (routeType == null) return 'Unknown';
    
    switch (routeType) {
      case tram:
        return 'Tram';
      case subway:
        return 'Subway';
      case rail:
        return 'Train';
      case bus:
        return 'Bus';
      case ferry:
        return 'Ferry';
      case cableTram:
        return 'Cable Tram';
      case aerialLift:
        return 'Cable Car';
      case funicular:
        return 'Funicular';
      case trolleybus:
        return 'Trolleybus';
      case monorail:
        return 'Monorail';
      default:
        return 'Unknown';
    }
  }

  /// Gets an emoji icon for a route type
  /// 
  /// [routeType] - The GTFS route type integer
  /// 
  /// Returns: Emoji representing the route type
  static String getEmoji(int? routeType) {
    if (routeType == null) return '🚌';
    
    switch (routeType) {
      case tram:
        return '🚊';
      case subway:
        return '🚇';
      case rail:
        return '🚆';
      case bus:
        return '🚌';
      case ferry:
        return '⛴️';
      case cableTram:
        return '🚡';
      case aerialLift:
        return '🚠';
      case funicular:
        return '🚞';
      case trolleybus:
        return '🚎';
      case monorail:
        return '🚝';
      default:
        return '🚌';
    }
  }
}



