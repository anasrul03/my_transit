import '../entities/vehicle_entity.dart';
import '../entities/shape_entity.dart';
import 'dart:math' as math;

/// Use case for interpolating vehicle position along a shape
/// 
/// This use case provides multiple interpolation strategies:
/// - Factor-based interpolation (legacy, for backward compatibility)
/// - Speed-based interpolation (uses vehicle speed and time elapsed)
/// - Distance-based interpolation (moves vehicle along shape by a specific distance)
class InterpolateVehiclePositionUseCase {
  /// Default speed to use when vehicle speed data is unavailable (m/s)
  /// 
  /// This is approximately 40 km/h (11.11 m/s), a reasonable average
  /// speed for urban transit vehicles.
  static const double _defaultSpeedMetersPerSecond = 11.11;

  /// Minimum speed threshold to consider vehicle as moving (m/s)
  static const double _minimumMovingSpeed = 0.5;

  /// Interpolate vehicle position using speed and time elapsed
  /// 
  /// This is the preferred method for real-time interpolation. It calculates
  /// how far the vehicle has traveled based on its speed and the time elapsed,
  /// then moves it along the shape by that distance.
  /// 
  /// [vehicle] - The vehicle entity with current position and speed
  /// [shape] - The GTFS shape entity representing the route path
  /// [timeSinceUpdate] - Duration since the last GTFS realtime update
  /// [currentDistanceOnShape] - Optional cached distance along shape (meters)
  /// 
  /// Returns: Updated vehicle entity with interpolated position
  VehicleEntity interpolateBySpeed({
    required VehicleEntity vehicle,
    required ShapeEntity shape,
    required Duration timeSinceUpdate,
    double? currentDistanceOnShape,
  }) {
    if (shape.points.isEmpty) {
      return vehicle;
    }

    // Get vehicle speed in m/s (GTFS realtime provides speed in m/s)
    final double speedMetersPerSecond = vehicle.speed ?? _defaultSpeedMetersPerSecond;

    // If vehicle is stopped or moving very slowly, don't interpolate
    if (speedMetersPerSecond < _minimumMovingSpeed) {
      return vehicle;
    }

    // Calculate distance traveled
    final double secondsElapsed = timeSinceUpdate.inMilliseconds / 1000.0;
    final double distanceTraveled = speedMetersPerSecond * secondsElapsed;

    // Find current position on shape if not provided
    final double startDistance = currentDistanceOnShape ?? 
        _findNearestDistanceOnShape(vehicle, shape);

    // Calculate new distance along shape
    final double newDistance = startDistance + distanceTraveled;

    // Interpolate to the new distance
    return interpolateByDistance(
      vehicle: vehicle,
      shape: shape,
      distanceAlongShape: newDistance,
    );
  }

  /// Interpolate vehicle position to a specific distance along the shape
  /// 
  /// This method moves the vehicle to a specific distance along the shape polyline.
  /// 
  /// [vehicle] - The vehicle entity to update
  /// [shape] - The GTFS shape entity representing the route path
  /// [distanceAlongShape] - Distance along shape in meters
  /// 
  /// Returns: Updated vehicle entity at the specified distance
  VehicleEntity interpolateByDistance({
    required VehicleEntity vehicle,
    required ShapeEntity shape,
    required double distanceAlongShape,
  }) {
    if (shape.points.isEmpty) {
      return vehicle;
    }

    // Handle negative distance
    if (distanceAlongShape <= 0.0) {
      final ShapePoint firstPoint = shape.points.first;
      final double bearing = shape.points.length > 1
          ? _calculateBearing(
              firstPoint.latitude,
              firstPoint.longitude,
              shape.points[1].latitude,
              shape.points[1].longitude,
            )
          : vehicle.bearing ?? 0.0;
      
      return vehicle.copyWith(
        latitude: firstPoint.latitude,
        longitude: firstPoint.longitude,
        bearing: bearing,
      );
    }

    // Walk along shape to find the segment containing the target distance
    double accumulatedDistance = 0.0;
    for (int i = 0; i < shape.points.length - 1; i++) {
      final ShapePoint point1 = shape.points[i];
      final ShapePoint point2 = shape.points[i + 1];

      final double segmentDistance = _calculateDistance(
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude,
      );

      if (accumulatedDistance + segmentDistance >= distanceAlongShape) {
        // Target distance is within this segment
        final double remainingDistance = distanceAlongShape - accumulatedDistance;
        final double fraction = segmentDistance > 0 ? remainingDistance / segmentDistance : 0.0;

        // Linear interpolation between points
        final double latitude = point1.latitude + (point2.latitude - point1.latitude) * fraction;
        final double longitude = point1.longitude + (point2.longitude - point1.longitude) * fraction;

        // Calculate bearing along this segment
        final double bearing = _calculateBearing(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        );

        return vehicle.copyWith(
          latitude: latitude,
          longitude: longitude,
          bearing: bearing,
        );
      }

      accumulatedDistance += segmentDistance;
    }

    // Distance exceeds shape length - return last point
    final ShapePoint lastPoint = shape.points.last;
    final ShapePoint secondLastPoint = shape.points[shape.points.length - 2];
    final double bearing = _calculateBearing(
      secondLastPoint.latitude,
      secondLastPoint.longitude,
      lastPoint.latitude,
      lastPoint.longitude,
    );

    return vehicle.copyWith(
      latitude: lastPoint.latitude,
      longitude: lastPoint.longitude,
      bearing: bearing,
    );
  }

  /// Finds the nearest distance along a shape for a vehicle's current position
  /// 
  /// This method locates the vehicle on the shape and returns the distance
  /// along the shape polyline to that point.
  /// 
  /// [vehicle] - The vehicle entity with current coordinates
  /// [shape] - The GTFS shape entity to search
  /// 
  /// Returns: Distance along shape in meters
  double _findNearestDistanceOnShape(VehicleEntity vehicle, ShapeEntity shape) {
    if (shape.points.isEmpty) {
      return 0.0;
    }

    double minDistance = double.infinity;
    int nearestSegmentIndex = 0;
    double nearestSegmentFraction = 0.0;

    // Find the nearest segment on the shape
    for (int i = 0; i < shape.points.length - 1; i++) {
      final ShapePoint point1 = shape.points[i];
      final ShapePoint point2 = shape.points[i + 1];

      // Calculate perpendicular distance from vehicle to this segment
      final result = _pointToSegmentDistance(
        vehicle.latitude,
        vehicle.longitude,
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude,
      );

      if (result.distance < minDistance) {
        minDistance = result.distance;
        nearestSegmentIndex = i;
        nearestSegmentFraction = result.fraction;
      }
    }

    // Calculate cumulative distance to the nearest segment
    double cumulativeDistance = 0.0;
    for (int i = 0; i < nearestSegmentIndex; i++) {
      cumulativeDistance += _calculateDistance(
        shape.points[i].latitude,
        shape.points[i].longitude,
        shape.points[i + 1].latitude,
        shape.points[i + 1].longitude,
      );
    }

    // Add partial distance along the nearest segment
    if (nearestSegmentIndex < shape.points.length - 1) {
      final double segmentLength = _calculateDistance(
        shape.points[nearestSegmentIndex].latitude,
        shape.points[nearestSegmentIndex].longitude,
        shape.points[nearestSegmentIndex + 1].latitude,
        shape.points[nearestSegmentIndex + 1].longitude,
      );
      cumulativeDistance += segmentLength * nearestSegmentFraction;
    }

    return cumulativeDistance;
  }

  /// Calculates the perpendicular distance from a point to a line segment
  /// 
  /// Returns a tuple with distance in meters and fraction along segment (0.0 to 1.0)
  ({double distance, double fraction}) _pointToSegmentDistance(
    double pointLat,
    double pointLon,
    double seg1Lat,
    double seg1Lon,
    double seg2Lat,
    double seg2Lon,
  ) {
    // Calculate segment length
    final double segmentLength = _calculateDistance(seg1Lat, seg1Lon, seg2Lat, seg2Lon);

    if (segmentLength == 0.0) {
      final double distance = _calculateDistance(pointLat, pointLon, seg1Lat, seg1Lon);
      return (distance: distance, fraction: 0.0);
    }

    // Calculate projection using dot product
    final double dx = seg2Lon - seg1Lon;
    final double dy = seg2Lat - seg1Lat;
    final double px = pointLon - seg1Lon;
    final double py = pointLat - seg1Lat;

    final double dotProduct = px * dx + py * dy;
    final double lengthSquared = dx * dx + dy * dy;
    double fraction = dotProduct / lengthSquared;

    // Clamp to [0, 1]
    fraction = fraction.clamp(0.0, 1.0);

    // Calculate closest point on segment
    final double closestLat = seg1Lat + fraction * dy;
    final double closestLon = seg1Lon + fraction * dx;

    final double distance = _calculateDistance(pointLat, pointLon, closestLat, closestLon);

    return (distance: distance, fraction: fraction);
  }

  /// Interpolate vehicle position along shape polyline (LEGACY METHOD)
  /// 
  /// Returns the interpolated position based on the vehicle's current position
  /// and the shape polyline. Uses linear interpolation between shape points.
  /// 
  /// NOTE: This method is kept for backward compatibility. New code should use
  /// interpolateBySpeed() or interpolateByDistance() instead.
  /// 
  /// [vehicle] - The vehicle entity to interpolate
  /// [shape] - The shape to interpolate along
  /// [interpolationFactor] - Factor from 0.0 to 1.0 representing position along shape
  /// 
  /// Returns: Updated vehicle entity with interpolated position
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
    int? routeType,
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
      routeType: routeType ?? this.routeType,
    );
  }
}

