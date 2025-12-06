import '../entities/vehicle_entity.dart';
import 'auth_repository.dart';

/// Repository interface for GTFS Realtime data
/// 
/// This interface defines the contract for fetching real-time vehicle position
/// data from the GTFS Realtime API. Implementations should handle API calls,
/// parsing, and error handling.
abstract class GtfsRealtimeRepository {
  /// Fetch realtime vehicle positions
  /// 
  /// Retrieves the current vehicle positions from the GTFS Realtime API.
  /// The positions are returned as a list of VehicleEntity objects containing
  /// location, route, and trip information for each vehicle.
  /// 
  /// [agency] - Agency code to fetch vehicle positions for (e.g., 'rapid-bus-kl', 'rapid-rail-kl').
  ///            Defaults to the default agency from ApiConstants if not provided.
  /// [feed] - Feed type to fetch (default: 'vehicle-position').
  ///          Options: 'vehicle-position', 'trip-updates', 'service-alerts'
  /// [category] - Optional category parameter for Prasarana agencies.
  ///              Required for Prasarana bus services (e.g., 'rapid-bus-kl', 'rapid-bus-mrtfeeder').
  ///              If not provided and agency is Prasarana, defaults to agency code.
  /// 
  /// Returns: Result containing a list of VehicleEntity objects on success,
  ///          or a Failure on error
  Future<Result<List<VehicleEntity>>> getVehiclePositions({
    String? agency,
    String feed = 'vehicle-position',
    String? category,
  });
}

