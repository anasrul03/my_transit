import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../data/repositories/gtfs_static_repository_impl.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/stop_entity.dart';
import '../../domain/entities/shape_entity.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/stop_time_entity.dart';
import '../../domain/entities/agency_entity.dart';
import '../../domain/entities/frequency_entity.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/repositories/gtfs_static_repository.dart';

final gtfsStaticRepositoryProvider = Provider<GtfsStaticRepository>((ref) {
  return GtfsStaticRepositoryImpl();
});

final gtfsStaticProvider = StateNotifierProvider<GtfsStaticNotifier, GtfsStaticState>(
  (ref) {
    return GtfsStaticNotifier(
      repository: ref.read(gtfsStaticRepositoryProvider),
    );
  },
);

class GtfsStaticState {
  final List<RouteEntity> routes;
  final List<StopEntity> stops;
  final Map<String, ShapeEntity> shapes;
  final List<TripEntity> trips;
  final List<StopTimeEntity> stopTimes;
  final List<AgencyEntity> agencies;
  final List<FrequencyEntity> frequencies;
  final List<TransferEntity> transfers;
  final bool isLoading;
  final Failure? error;
  final bool isLoaded;

  const GtfsStaticState({
    this.routes = const [],
    this.stops = const [],
    this.shapes = const {},
    this.trips = const [],
    this.stopTimes = const [],
    this.agencies = const [],
    this.frequencies = const [],
    this.transfers = const [],
    this.isLoading = false,
    this.error,
    this.isLoaded = false,
  });

  GtfsStaticState copyWith({
    List<RouteEntity>? routes,
    List<StopEntity>? stops,
    Map<String, ShapeEntity>? shapes,
    List<TripEntity>? trips,
    List<StopTimeEntity>? stopTimes,
    List<AgencyEntity>? agencies,
    List<FrequencyEntity>? frequencies,
    List<TransferEntity>? transfers,
    bool? isLoading,
    Failure? error,
    bool? isLoaded,
  }) {
    return GtfsStaticState(
      routes: routes ?? this.routes,
      stops: stops ?? this.stops,
      shapes: shapes ?? this.shapes,
      trips: trips ?? this.trips,
      stopTimes: stopTimes ?? this.stopTimes,
      agencies: agencies ?? this.agencies,
      frequencies: frequencies ?? this.frequencies,
      transfers: transfers ?? this.transfers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class GtfsStaticNotifier extends StateNotifier<GtfsStaticState> {
  final GtfsStaticRepository _repository;

  GtfsStaticNotifier({required GtfsStaticRepository repository})
      : _repository = repository,
        super(const GtfsStaticState()) {
    loadStaticData();
  }

  /// Loads static GTFS data (routes, stops, shapes) from the repository
  /// 
  /// This method fetches all static transit data needed for the app to function.
  /// It only loads data once (if already loaded, it returns early). The data
  /// includes routes, stops, and shapes which are used for displaying transit
  /// information on the map and in route planning.
  /// 
  /// The shapes are converted from a list to a map for efficient lookups by shape ID.
  Future<void> loadStaticData() async {
    // Skip loading if data is already loaded
    if (state.isLoaded) return;

    // Set loading state and clear any previous errors
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch all static data in parallel for better performance
      final routesResult = await _repository.getRoutes();
      final stopsResult = await _repository.getStops();
      final shapesResult = await _repository.getShapes();
      final agenciesResult = await _repository.getAgencies();
      final frequenciesResult = await _repository.getFrequencies();
      final transfersResult = await _repository.getTransfers();

      // Only update state if all fetches succeeded
      if (routesResult.isSuccess &&
          stopsResult.isSuccess &&
          shapesResult.isSuccess &&
          agenciesResult.isSuccess &&
          frequenciesResult.isSuccess &&
          transfersResult.isSuccess) {
        // Convert shapes list to map for efficient lookups by shape ID
        final Map<String, ShapeEntity> shapesMap = <String, ShapeEntity>{};
        for (final ShapeEntity shape in shapesResult.data ?? []) {
          shapesMap[shape.id] = shape;
        }

        // Update state with all loaded data
        state = state.copyWith(
          routes: routesResult.data ?? [],
          stops: stopsResult.data ?? [],
          shapes: shapesMap,
          agencies: agenciesResult.data ?? [],
          frequencies: frequenciesResult.data ?? [],
          transfers: transfersResult.data ?? [],
          isLoading: false,
          isLoaded: true,
        );
      } else {
        // Update state with the first error encountered
        state = state.copyWith(
          isLoading: false,
          error: routesResult.failure ??
              stopsResult.failure ??
              shapesResult.failure ??
              agenciesResult.failure ??
              frequenciesResult.failure ??
              transfersResult.failure,
        );
      }
    } catch (e) {
      // Handle unexpected errors
      state = state.copyWith(
        isLoading: false,
        error: ServerFailure('Failed to load static data: ${e.toString()}'),
      );
    }
  }

  /// Gets a shape entity by its ID
  /// 
  /// [shapeId] - The ID of the shape to retrieve
  /// 
  /// Returns: The ShapeEntity if found, or null if not found
  Future<ShapeEntity?> getShapeById(String shapeId) async {
    final result = await _repository.getShapeById(shapeId);
    return result.data;
  }

  /// Gets all trips for a specific route
  /// 
  /// [routeId] - The ID of the route to get trips for
  /// 
  /// Returns: List of TripEntity objects for the specified route
  Future<List<TripEntity>> getTripsByRouteId(String routeId) async {
    final result = await _repository.getTripsByRouteId(routeId);
    return result.data ?? [];
  }

  /// Gets all stop times for a specific trip
  /// 
  /// [tripId] - The ID of the trip to get stop times for
  /// 
  /// Returns: List of StopTimeEntity objects for the specified trip
  Future<List<StopTimeEntity>> getStopTimesByTripId(String tripId) async {
    final result = await _repository.getStopTimesByTripId(tripId);
    return result.data ?? [];
  }

  /// Gets all frequencies for a specific trip
  /// 
  /// [tripId] - The ID of the trip to get frequencies for
  /// 
  /// Returns: List of FrequencyEntity objects for the specified trip
  Future<List<FrequencyEntity>> getFrequenciesByTripId(String tripId) async {
    final result = await _repository.getFrequenciesByTripId(tripId);
    return result.data ?? [];
  }

  /// Gets a trip entity by its ID
  /// 
  /// [tripId] - The ID of the trip to retrieve
  /// 
  /// Returns: The TripEntity if found, or null if not found
  /// This method first checks the cached trips in state, and if not found,
  /// queries the repository. This allows efficient lookups for vehicle-to-shape mapping.
  Future<TripEntity?> getTripById(String tripId) async {
    // First check cached trips in state for fast lookup
    try {
      final cachedTrip = state.trips.firstWhere(
        (TripEntity trip) => trip.id == tripId,
        orElse: () => throw Exception('Trip not found in cache'),
      );
      return cachedTrip;
    } catch (e) {
      // If not in cache, query repository
      final result = await _repository.getTripById(tripId);
      return result.data;
    }
  }
}

