import 'package:my_transit/core/errors/failures.dart';

import '../entities/vehicle_entity.dart';
import '../../core/services/location_service.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for calculating distance and ETA to a vehicle
class CalculateDistanceEtaUseCase {
  final LocationService _locationService;

  CalculateDistanceEtaUseCase(this._locationService);

  /// Calculate distance and ETA to vehicle from user's current position
  Future<Result<DistanceEtaResult>> calculate({
    required VehicleEntity vehicle,
    required double userLatitude,
    required double userLongitude,
    double? vehicleSpeed, // in m/s
  }) async {
    try {
      final distance = _locationService.calculateDistance(
        userLatitude,
        userLongitude,
        vehicle.latitude,
        vehicle.longitude,
      );

      // Calculate ETA if speed is available
      Duration? eta;
      if (vehicleSpeed != null && vehicleSpeed > 0) {
        final seconds = (distance / vehicleSpeed).round();
        eta = Duration(seconds: seconds);
      }

      return Result.success(
        DistanceEtaResult(
          distanceMeters: distance,
          eta: eta,
        ),
      );
    } catch (e) {
      return Result.failure(
        LocationFailure('Failed to calculate distance/ETA: ${e.toString()}'),
      );
    }
  }
}

class DistanceEtaResult {
  final double distanceMeters;
  final Duration? eta;

  DistanceEtaResult({
    required this.distanceMeters,
    this.eta,
  });

  String get distanceFormatted {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  String get etaFormatted {
    if (eta == null) return 'N/A';
    
    final minutes = eta!.inMinutes;
    if (minutes < 1) {
      return '${eta!.inSeconds}s';
    } else {
      return '${minutes}m';
    }
  }
}

