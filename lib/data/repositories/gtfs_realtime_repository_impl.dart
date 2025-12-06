import 'dart:typed_data';
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
  Future<Result<List<VehicleEntity>>> getVehiclePositions() async {
    try {
      final feedData = await _apiService.fetchRealtimeFeed();
      final result = await _parser.parseFeed(Uint8List.fromList(feedData));
      
      if (result.isSuccess) {
        return Result.success(result.data ?? []);
      } else {
        return result;
      }
    } on NetworkFailure {
      return const Result.failure(
        NetworkFailure('No internet connection'),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to fetch vehicle positions: ${e.toString()}'),
      );
    }
  }
}

