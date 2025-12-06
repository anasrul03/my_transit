import '../entities/vehicle_entity.dart';
import 'auth_repository.dart';

abstract class GtfsRealtimeRepository {
  /// Fetch realtime vehicle positions
  Future<Result<List<VehicleEntity>>> getVehiclePositions();
}

