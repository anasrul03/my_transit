import '../entities/route_entity.dart';
import '../entities/stop_entity.dart';
import '../entities/shape_entity.dart';
import '../entities/trip_entity.dart';
import '../entities/stop_time_entity.dart';
import '../entities/agency_entity.dart';
import '../entities/frequency_entity.dart';
import '../entities/transfer_entity.dart';
import 'auth_repository.dart';

abstract class GtfsStaticRepository {
  /// Fetch all routes
  Future<Result<List<RouteEntity>>> getRoutes();
  
  /// Fetch all stops
  Future<Result<List<StopEntity>>> getStops();
  
  /// Fetch shape by ID
  Future<Result<ShapeEntity?>> getShapeById(String shapeId);
  
  /// Fetch all shapes
  Future<Result<List<ShapeEntity>>> getShapes();
  
  /// Fetch trip by ID
  Future<Result<TripEntity?>> getTripById(String tripId);
  
  /// Fetch trips by route ID
  Future<Result<List<TripEntity>>> getTripsByRouteId(String routeId);
  
  /// Fetch stop times by trip ID
  Future<Result<List<StopTimeEntity>>> getStopTimesByTripId(String tripId);
  
  /// Fetch stop times by stop ID
  Future<Result<List<StopTimeEntity>>> getStopTimesByStopId(String stopId);
  
  /// Fetch all agencies
  Future<Result<List<AgencyEntity>>> getAgencies();
  
  /// Fetch all frequencies
  Future<Result<List<FrequencyEntity>>> getFrequencies();
  
  /// Fetch frequencies by trip ID
  Future<Result<List<FrequencyEntity>>> getFrequenciesByTripId(String tripId);
  
  /// Fetch all transfers
  Future<Result<List<TransferEntity>>> getTransfers();
  
  /// Check if static GTFS data is cached
  bool isCached();
  
  /// Clear cached data
  Future<void> clearCache();
}

