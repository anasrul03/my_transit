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
  // Essential data kept in memory for performance
  List<RouteEntity>? _cachedRoutes;
  List<StopEntity>? _cachedStops;
  List<AgencyEntity>? _cachedAgencies;
  
  // Optional data loaded on-demand to reduce memory usage
  Map<String, ShapeEntity>? _cachedShapes; // Lazy-loaded shapes
  List<TripEntity>? _cachedTrips; // Lazy-loaded trips
  List<StopTimeEntity>? _cachedStopTimes; // Lazy-loaded stop times
  List<FrequencyEntity>? _cachedFrequencies; // Lazy-loaded frequencies
  List<TransferEntity>? _cachedTransfers; // Lazy-loaded transfers
  
  // Raw shape data stored for lazy parsing
  String? _rawShapesData;
  String? _rawTripsData;
  String? _rawStopTimesData;
  String? _rawFrequenciesData;
  String? _rawTransfersData;
  
  bool _isDataLoaded = false;

  GtfsStaticRepositoryImpl({
    GtfsApiService? apiService,
    GtfsStaticParser? parser,
    GtfsCacheManager? cacheManager,
  })  : _apiService = apiService ?? GtfsApiService(),
        _parser = parser ?? GtfsStaticParser(),
        _cacheManager = cacheManager ?? GtfsCacheManager() {
    // Clean up old temp files on initialization
    _cleanupOldTempFiles();
  }
  
  /// Clean up old temporary GTFS files
  /// 
  /// Removes temporary ZIP files older than 1 hour to prevent storage bloat.
  /// This runs asynchronously on repository initialization.
  Future<void> _cleanupOldTempFiles() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final DateTime cutoffTime = DateTime.now().subtract(const Duration(hours: 1));
      
      // Find and delete old GTFS temp files
      if (await tempDir.exists()) {
        await for (final FileSystemEntity entity in tempDir.list()) {
          if (entity is File && entity.path.contains('gtfs_static_')) {
            try {
              final FileStat stat = await entity.stat();
              if (stat.modified.isBefore(cutoffTime)) {
                await entity.delete();
              }
            } catch (e) {
              // Continue even if we can't delete a specific file
              continue;
            }
          }
        }
      }
    } catch (e) {
      // Silently fail - temp cleanup is not critical
    }
  }

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
      // Parse essential data immediately, store raw data for lazy loading
      for (final file in archive) {
        final String filename = file.name;
        final String content = String.fromCharCodes(file.content);

        if (filename == 'routes.txt') {
          // Essential: Parse routes immediately
          final result = await _parser.parseRoutes(content);
          if (result.isSuccess) {
            _cachedRoutes = result.data?.map((dto) => dto.toEntity()).toList();
          }
        } else if (filename == 'stops.txt') {
          // Essential: Parse stops immediately
          final result = await _parser.parseStops(content);
          if (result.isSuccess) {
            _cachedStops = result.data?.map((dto) => dto.toEntity()).toList();
          }
        } else if (filename == 'agency.txt') {
          // Essential: Parse agencies immediately
          final result = await _parser.parseAgencies(content);
          if (result.isSuccess) {
            _cachedAgencies = result.data?.map((dto) => dto.toEntity()).toList();
          }
        } else if (filename == 'shapes.txt') {
          // Optional: Store raw data for lazy loading
          _rawShapesData = content;
        } else if (filename == 'trips.txt') {
          // Optional: Store raw data for lazy loading
          _rawTripsData = content;
        } else if (filename == 'stop_times.txt') {
          // Optional: Store raw data for lazy loading
          _rawStopTimesData = content;
        } else if (filename == 'frequencies.txt') {
          // Optional: Store raw data for lazy loading
          _rawFrequenciesData = content;
        } else if (filename == 'transfers.txt') {
          // Optional: Store raw data for lazy loading
          _rawTransfersData = content;
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

  /// Lazy-load shapes from raw data
  /// 
  /// Parses shape data only when first requested to reduce memory usage.
  Future<void> _ensureShapesLoaded() async {
    if (_cachedShapes != null) return;
    
    if (_rawShapesData != null) {
      final result = await _parser.parseShapes(_rawShapesData!);
      if (result.isSuccess) {
        _cachedShapes = result.data?.map(
          (String id, dynamic dto) => MapEntry(id, dto.toEntity()),
        );
      }
    }
  }
  
  /// Lazy-load trips from raw data
  Future<void> _ensureTripsLoaded() async {
    if (_cachedTrips != null) return;
    
    if (_rawTripsData != null) {
      final result = await _parser.parseTrips(_rawTripsData!);
      if (result.isSuccess) {
        _cachedTrips = result.data?.map((dto) => dto.toEntity()).toList();
      }
    }
  }
  
  /// Lazy-load stop times from raw data
  Future<void> _ensureStopTimesLoaded() async {
    if (_cachedStopTimes != null) return;
    
    if (_rawStopTimesData != null) {
      final result = await _parser.parseStopTimes(_rawStopTimesData!);
      if (result.isSuccess) {
        _cachedStopTimes = result.data?.map((dto) => dto.toEntity()).toList();
      }
    }
  }
  
  /// Lazy-load frequencies from raw data
  Future<void> _ensureFrequenciesLoaded() async {
    if (_cachedFrequencies != null) return;
    
    if (_rawFrequenciesData != null) {
      final result = await _parser.parseFrequencies(_rawFrequenciesData!);
      if (result.isSuccess) {
        _cachedFrequencies = result.data?.map((dto) => dto.toEntity()).toList();
      }
    }
  }
  
  /// Lazy-load transfers from raw data
  Future<void> _ensureTransfersLoaded() async {
    if (_cachedTransfers != null) return;
    
    if (_rawTransfersData != null) {
      final result = await _parser.parseTransfers(_rawTransfersData!);
      if (result.isSuccess) {
        _cachedTransfers = result.data?.map((dto) => dto.toEntity()).toList();
      }
    }
  }

  @override
  Future<Result<ShapeEntity?>> getShapeById(String shapeId) async {
    try {
      await _loadStaticData();
      await _ensureShapesLoaded();
      final ShapeEntity? shape = _cachedShapes?[shapeId];
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
      await _ensureShapesLoaded();
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
      await _ensureTripsLoaded();
      final TripEntity? trip = _cachedTrips?.firstWhere(
        (TripEntity t) => t.id == tripId,
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
      await _ensureTripsLoaded();
      final List<TripEntity> trips = _cachedTrips
          ?.where((TripEntity t) => t.routeId == routeId)
          .toList() ?? <TripEntity>[];
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
      await _ensureStopTimesLoaded();
      final List<StopTimeEntity> stopTimes = _cachedStopTimes
          ?.where((StopTimeEntity st) => st.tripId == tripId)
          .toList() ?? <StopTimeEntity>[];
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
      await _ensureStopTimesLoaded();
      final List<StopTimeEntity> stopTimes = _cachedStopTimes
          ?.where((StopTimeEntity st) => st.stopId == stopId)
          .toList() ?? <StopTimeEntity>[];
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
      return Result.success(_cachedAgencies ?? <AgencyEntity>[]);
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
      await _ensureFrequenciesLoaded();
      return Result.success(_cachedFrequencies ?? <FrequencyEntity>[]);
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
      await _ensureFrequenciesLoaded();
      final List<FrequencyEntity> frequencies = _cachedFrequencies
          ?.where((FrequencyEntity f) => f.tripId == tripId)
          .toList() ?? <FrequencyEntity>[];
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
      await _ensureTransfersLoaded();
      return Result.success(_cachedTransfers ?? <TransferEntity>[]);
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
    
    // Clear parsed data
    _cachedRoutes = null;
    _cachedStops = null;
    _cachedShapes = null;
    _cachedTrips = null;
    _cachedStopTimes = null;
    _cachedAgencies = null;
    _cachedFrequencies = null;
    _cachedTransfers = null;
    
    // Clear raw data
    _rawShapesData = null;
    _rawTripsData = null;
    _rawStopTimesData = null;
    _rawFrequenciesData = null;
    _rawTransfersData = null;
    
    _isDataLoaded = false;
  }
}

