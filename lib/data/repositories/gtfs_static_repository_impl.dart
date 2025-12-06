import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/stop_entity.dart';
import '../../domain/entities/shape_entity.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/stop_time_entity.dart';
import '../../domain/entities/agency_entity.dart';
import '../../domain/entities/frequency_entity.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/repositories/gtfs_static_repository.dart';
import '../cache/gtfs_cache_manager.dart';
import '../parsers/gtfs/static_parser.dart';
import '../services/gtfs_api_service.dart';

class GtfsStaticRepositoryImpl implements GtfsStaticRepository {
  final GtfsStaticParser _parser;
  final GtfsCacheManager _cacheManager;
  final GtfsApiService _apiService;

  // In-memory cache for parsed data
  List<RouteEntity>? _cachedRoutes;
  List<StopEntity>? _cachedStops;
  Map<String, ShapeEntity>? _cachedShapes;
  List<TripEntity>? _cachedTrips;
  List<StopTimeEntity>? _cachedStopTimes;
  List<AgencyEntity>? _cachedAgencies;
  List<FrequencyEntity>? _cachedFrequencies;
  List<TransferEntity>? _cachedTransfers;
  bool _isDataLoaded = false;

  GtfsStaticRepositoryImpl({
    GtfsApiService? apiService,
    GtfsStaticParser? parser,
    GtfsCacheManager? cacheManager,
  })  : _apiService = apiService ?? GtfsApiService(),
        _parser = parser ?? GtfsStaticParser(),
        _cacheManager = cacheManager ?? GtfsCacheManager();

  Future<void> _loadStaticData({String agency = ApiConstants.defaultAgency}) async {
    if (_isDataLoaded) return;

    File? tempZipFile;
    
    try {
      // Build cache URL with agency for proper cache key
      final staticUrl = '${ApiConstants.gtfsStaticBaseUrl}/$agency';
      
      // Check cache first
      File? cachedFile = await _cacheManager.getCachedFile(staticUrl);
      List<int> zipBytes;
      
      // Try to use cached file if available and valid
      if (cachedFile != null && await cachedFile.exists()) {
        // Use cached file, but validate it's a ZIP file
        final List<int> cachedBytes = await cachedFile.readAsBytes();
        
        // Validate ZIP file signature (ZIP files start with "PK" - 0x50 0x4B)
        if (cachedBytes.length >= 2 && cachedBytes[0] == 0x50 && cachedBytes[1] == 0x4B) {
          // Valid ZIP file in cache, use it
          zipBytes = cachedBytes;
        } else {
          // Cached file is invalid, clear it and download fresh
          await _cacheManager.removeCachedFile(staticUrl);
          // Download using API service (which validates ZIP file signature)
          // For Prasarana agencies, category defaults to agency code
          zipBytes = await _apiService.fetchStaticGtfs(agency: agency);
        }
      } else {
        // No cached file, download using API service (which validates ZIP file signature)
        // For Prasarana agencies, category defaults to agency code
        zipBytes = await _apiService.fetchStaticGtfs(agency: agency);
      }

      // Save ZIP to temporary directory for validation and extraction
      // This follows Flutter best practices: save to temp directory first
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      tempZipFile = File('${tempDir.path}/gtfs_static_$timestamp.zip');
      
      // Write ZIP bytes to temp file
      await tempZipFile.writeAsBytes(zipBytes);
      
      // Validate ZIP file signature again after saving to disk
      // This ensures the file was written correctly
      final List<int> fileBytes = await tempZipFile.readAsBytes();
      if (fileBytes.length < 2 || fileBytes[0] != 0x50 || fileBytes[1] != 0x4B) {
        throw ServerFailure(
          'Downloaded file is not a valid ZIP file. '
          'Expected ZIP signature (PK) but got: ${fileBytes.take(10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
        );
      }

      // Extract ZIP from the temp file
      // Read bytes from file (ensuring we use bodyBytes pattern)
      final List<int> zipFileBytes = await tempZipFile.readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(zipFileBytes);

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
        } else if (filename == 'agency.txt') {
          final result = await _parser.parseAgencies(content);
          if (result.isSuccess) {
            _cachedAgencies = result.data?.map((dto) => dto.toEntity()).toList();
          }
        } else if (filename == 'frequencies.txt') {
          final result = await _parser.parseFrequencies(content);
          if (result.isSuccess) {
            _cachedFrequencies = result.data?.map((dto) => dto.toEntity()).toList();
          }
        } else if (filename == 'transfers.txt') {
          final result = await _parser.parseTransfers(content);
          if (result.isSuccess) {
            _cachedTransfers = result.data?.map((dto) => dto.toEntity()).toList();
          }
        }
      }

      _isDataLoaded = true;
    } catch (e) {
      // Re-throw if it's already a Failure
      if (e is Failure) {
        rethrow;
      }
      throw ServerFailure('Failed to load static GTFS data: ${e.toString()}');
    } finally {
      // Clean up temporary ZIP file after processing
      // This ensures we don't leave temp files on disk
      if (tempZipFile != null && await tempZipFile.exists()) {
        try {
          await tempZipFile.delete();
        } catch (e) {
          // Ignore errors when cleaning up temp file
          // It's not critical if temp file cleanup fails
        }
      }
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
  Future<Result<List<AgencyEntity>>> getAgencies() async {
    try {
      await _loadStaticData();
      return Result.success(_cachedAgencies ?? []);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get agencies: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<FrequencyEntity>>> getFrequencies() async {
    try {
      await _loadStaticData();
      return Result.success(_cachedFrequencies ?? []);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get frequencies: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<FrequencyEntity>>> getFrequenciesByTripId(String tripId) async {
    try {
      await _loadStaticData();
      final frequencies = _cachedFrequencies
          ?.where((f) => f.tripId == tripId)
          .toList() ?? [];
      return Result.success(frequencies);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get frequencies: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<TransferEntity>>> getTransfers() async {
    try {
      await _loadStaticData();
      return Result.success(_cachedTransfers ?? []);
    } catch (e) {
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        ServerFailure('Failed to get transfers: ${e.toString()}'),
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
    _cachedAgencies = null;
    _cachedFrequencies = null;
    _cachedTransfers = null;
    _isDataLoaded = false;
  }
}

