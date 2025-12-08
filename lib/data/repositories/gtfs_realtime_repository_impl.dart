import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/gtfs_realtime_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../parsers/gtfs/realtime_parser.dart';
import '../services/gtfs_api_service.dart';

class GtfsRealtimeRepositoryImpl implements GtfsRealtimeRepository {
  final GtfsApiService _apiService;
  final GtfsRealtimeParser _parser;

  GtfsRealtimeRepositoryImpl({
    GtfsApiService? apiService,
    GtfsRealtimeParser? parser,
  })  : _apiService = apiService ?? GtfsApiService(),
        _parser = parser ?? GtfsRealtimeParser();

  @override
  Future<Result<List<VehicleEntity>>> getVehiclePositions({
    String? agency,
    String feed = ApiConstants.feedVehiclePositions,
    String? category,
  }) async {
    try {
      // Use default agency if not provided
      final String finalAgency = agency ?? ApiConstants.defaultAgency;
      
      // Fetch realtime feed for the specified agency
      // For Prasarana agencies, "prasarana" is used in the URL path, and the agency code
      // (e.g., 'rapid-bus-kl') is passed as the category query parameter
      // For other agencies, the agency code is used directly in the URL path
      final List<int> feedData = await _apiService.fetchRealtimeFeed(
        feed: feed,
        agency: finalAgency,
        category: category,
      );
      
      // Parse the feed data
      // Pass agency to parser for special handling (e.g., rapid-bus-penang)
      final Result<List<VehicleEntity>> result = await _parser.parseFeed(
        Uint8List.fromList(feedData),
        agency: finalAgency,
      );
      
      if (result.isSuccess) {
        debugPrint('✅ Fetched ${result.data?.length ?? 0} vehicles for agency "$finalAgency"${category != null ? " (category: $category)" : ""}');
        return Result.success(result.data ?? []);
      } else {
        return result;
      }
    } on NetworkFailure {
      // Handle network connectivity issues
      return const Result.failure(
        NetworkFailure('No internet connection'),
      );
    } on Failure catch (e) {
      // Re-throw Failure types (AuthFailure, ServerFailure, etc.) from API service
      return Result.failure(e);
    } catch (e) {
      // Handle any unexpected errors
      return Result.failure(
        ServerFailure('Failed to fetch vehicle positions: ${e.toString()}'),
      );
    }
  }
}

