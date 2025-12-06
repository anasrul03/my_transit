import 'dart:io';
import 'package:archive/archive.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/stop_entity.dart';
import '../../domain/entities/shape_entity.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/stop_time_entity.dart';
import '../../domain/repositories/gtfs_static_repository.dart';
import '../cache/gtfs_cache_manager.dart';
import '../models/gtfs/route_dto.dart';
import '../models/gtfs/stop_dto.dart';
import '../models/gtfs/shape_dto.dart';
import '../models/gtfs/trip_dto.dart';
import '../models/gtfs/stop_time_dto.dart';
import '../parsers/gtfs/static_parser.dart';
import '../services/gtfs_api_service.dart';

class GtfsStaticRepositoryImpl implements GtfsStaticRepository {
  final GtfsStaticParser _parser;
  final GtfsCacheManager _cacheManager;

  // In-memory cache for parsed data
  List<RouteEntity>? _cachedRoutes;
  List<StopEntity>? _cachedStops;
  Map<String, ShapeEntity>? _cachedShapes;
  List<TripEntity>? _cachedTrips;
  List<StopTimeEntity>? _cachedStopTimes;
  bool _isDataLoaded = false;

  GtfsStaticRepositoryImpl({
    GtfsApiService? apiService,
    GtfsStaticParser? parser,
    GtfsCacheManager? cacheManager,
  })  : _parser = parser ?? GtfsStaticParser(),
        _cacheManager = cacheManager ?? GtfsCacheManager();

  Future<void> _loadStaticData() async {
    if (_isDataLoaded) return;

    try {
      final staticUrl = '${ApiConstants.gtfsStaticBaseUrl}${ApiConstants.gtfsStaticEndpoint}';
      
      // Check cache first
      File? cachedFile = await _cacheManager.getCachedFile(staticUrl);
      
      if (cachedFile == null) {
        // Download and cache
        cachedFile = await _cacheManager.downloadAndCache(staticUrl);
      }

      // Extract ZIP
      final bytes = await cachedFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Parse each file
      for (final file in archive) {
        final filename = file.name;
        final content = String.fromCharCodes(file.content);

        if (filename == 'routes.txt') {
          final result = await _parser.parseRoutes(content);
          if (result.isSuccess) {
            _cachedRoutes = result.data?.map((dto) => dto.toEntity()).toList();
          }
        } else if (filename == 'stops.txt') {
          final result = await _parser.parseStops(content);
          if (result.isSuccess) {
            _cachedStops = result.data?.map((dto) => dto.toEntity()).toList();
          }
        } else if (filename == 'shapes.txt') {
          final result = await _parser.parseShapes(content);
          if (result.isSuccess) {
            _cachedShapes = result.data?.map(
              (id, dto) => MapEntry(id, dto.toEntity()),
            );
          }
        } else if (filename == 'trips.txt') {
          final result = await _parser.parseTrips(content);
          if (result.isSuccess) {
            _cachedTrips = result.data?.map((dto) => dto.toEntity()).toList();
          }
        } else if (filename == 'stop_times.txt') {
          final result = await _parser.parseStopTimes(content);
          if (result.isSuccess) {
            _cachedStopTimes = result.data?.map((dto) => dto.toEntity()).toList();
          }
        }
      }

      _isDataLoaded = true;
    } catch (e) {
      throw ServerFailure('Failed to load static GTFS data: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<RouteEntity>>> getRoutes() async {
    try {
      await _loadStaticData();
      return Result.success(_cachedRoutes ?? []);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get routes: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<StopEntity>>> getStops() async {
    try {
      await _loadStaticData();
      return Result.success(_cachedStops ?? []);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get stops: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<ShapeEntity?>> getShapeById(String shapeId) async {
    try {
      await _loadStaticData();
      final shape = _cachedShapes?[shapeId];
      return Result.success(shape);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get shape: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<ShapeEntity>>> getShapes() async {
    try {
      await _loadStaticData();
      return Result.success(_cachedShapes?.values.toList() ?? []);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get shapes: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<TripEntity?>> getTripById(String tripId) async {
    try {
      await _loadStaticData();
      final trip = _cachedTrips?.firstWhere(
        (t) => t.id == tripId,
        orElse: () => throw Exception('Trip not found'),
      );
      return Result.success(trip);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return const Result.success(null);
    }
  }

  @override
  Future<Result<List<TripEntity>>> getTripsByRouteId(String routeId) async {
    try {
      await _loadStaticData();
      final trips = _cachedTrips
          ?.where((t) => t.routeId == routeId)
          .toList() ?? [];
      return Result.success(trips);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get trips: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<StopTimeEntity>>> getStopTimesByTripId(String tripId) async {
    try {
      await _loadStaticData();
      final stopTimes = _cachedStopTimes
          ?.where((st) => st.tripId == tripId)
          .toList() ?? [];
      return Result.success(stopTimes);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get stop times: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<StopTimeEntity>>> getStopTimesByStopId(String stopId) async {
    try {
      await _loadStaticData();
      final stopTimes = _cachedStopTimes
          ?.where((st) => st.stopId == stopId)
          .toList() ?? [];
      return Result.success(stopTimes);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get stop times: ${e.toString()}'),
      );
    }
  }

  @override
  bool isCached() {
    return _isDataLoaded;
  }

  @override
  Future<void> clearCache() async {
    await _cacheManager.clearCache();
    _cachedRoutes = null;
    _cachedStops = null;
    _cachedShapes = null;
    _cachedTrips = null;
    _cachedStopTimes = null;
    _isDataLoaded = false;
  }
}

