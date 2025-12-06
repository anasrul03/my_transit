import '../entities/vehicle_entity.dart';
import '../entities/shape_entity.dart';
import 'dart:math' as math;

/// Use case for interpolating vehicle position along a shape
class InterpolateVehiclePositionUseCase {
  /// Interpolate vehicle position along shape polyline
  /// 
  /// Returns the interpolated position based on the vehicle's current position
  /// and the shape polyline. Uses linear interpolation between shape points.
  VehicleEntity interpolate({
    required VehicleEntity vehicle,
    required ShapeEntity shape,
    required double interpolationFactor, // 0.0 to 1.0
  }) {
    if (shape.points.isEmpty) {
      return vehicle;
    }

    // Find the segment where the vehicle should be
    final totalDistance = _calculateTotalDistance(shape.points);
    final targetDistance = totalDistance * interpolationFactor;

    // Find the two points that bracket the target distance
    double accumulatedDistance = 0.0;
    for (int i = 0; i < shape.points.length - 1; i++) {
      final point1 = shape.points[i];
      final point2 = shape.points[i + 1];
      
      final segmentDistance = _calculateDistance(
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude,
      );

      if (accumulatedDistance + segmentDistance >= targetDistance) {
        // Interpolate between point1 and point2
        final segmentFactor = (targetDistance - accumulatedDistance) / segmentDistance;
        
        final interpolatedLat = point1.latitude +
            (point2.latitude - point1.latitude) * segmentFactor;
        final interpolatedLon = point1.longitude +
            (point2.longitude - point1.longitude) * segmentFactor;

        // Calculate bearing
        final bearing = _calculateBearing(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        );

        return vehicle.copyWith(
          latitude: interpolatedLat,
          longitude: interpolatedLon,
          bearing: bearing,
        );
      }

      accumulatedDistance += segmentDistance;
    }

    // If we've gone past all points, return the last point
    final lastPoint = shape.points.last;
    return vehicle.copyWith(
      latitude: lastPoint.latitude,
      longitude: lastPoint.longitude,
    );
  }

  double _calculateTotalDistance(List<ShapePoint> points) {
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return total;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Calculate bearing between two points
  double _calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
  double _toDegrees(double radians) => radians * 180 / math.pi;
}

extension VehicleEntityExtension on VehicleEntity {
  VehicleEntity copyWith({
    String? id,
    String? routeId,
    String? tripId,
    double? latitude,
    double? longitude,
    double? bearing,
    double? speed,
    DateTime? timestamp,
    String? operatorId,
    String? vehicleLabel,
  }) {
    return VehicleEntity(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      tripId: tripId ?? this.tripId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bearing: bearing ?? this.bearing,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      operatorId: operatorId ?? this.operatorId,
      vehicleLabel: vehicleLabel ?? this.vehicleLabel,
    );
  }
}

