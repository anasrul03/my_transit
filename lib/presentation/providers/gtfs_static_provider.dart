import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../data/repositories/gtfs_static_repository_impl.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/stop_entity.dart';
import '../../domain/entities/shape_entity.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/stop_time_entity.dart';
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
  final bool isLoading;
  final Failure? error;
  final bool isLoaded;

  const GtfsStaticState({
    this.routes = const [],
    this.stops = const [],
    this.shapes = const {},
    this.trips = const [],
    this.stopTimes = const [],
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

  Future<void> loadStaticData() async {
    if (state.isLoaded) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final routesResult = await _repository.getRoutes();
      final stopsResult = await _repository.getStops();
      final shapesResult = await _repository.getShapes();

      if (routesResult.isSuccess &&
          stopsResult.isSuccess &&
          shapesResult.isSuccess) {
        final shapesMap = <String, ShapeEntity>{};
        for (final shape in shapesResult.data ?? []) {
          shapesMap[shape.id] = shape;
        }

        state = state.copyWith(
          routes: routesResult.data ?? [],
          stops: stopsResult.data ?? [],
          shapes: shapesMap,
          isLoading: false,
          isLoaded: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: routesResult.failure ??
              stopsResult.failure ??
              shapesResult.failure,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ServerFailure('Failed to load static data: ${e.toString()}'),
      );
    }
  }

  Future<ShapeEntity?> getShapeById(String shapeId) async {
    final result = await _repository.getShapeById(shapeId);
    return result.data;
  }

  Future<List<TripEntity>> getTripsByRouteId(String routeId) async {
    final result = await _repository.getTripsByRouteId(routeId);
    return result.data ?? [];
  }

  Future<List<StopTimeEntity>> getStopTimesByTripId(String tripId) async {
    final result = await _repository.getStopTimesByTripId(tripId);
    return result.data ?? [];
  }
}

