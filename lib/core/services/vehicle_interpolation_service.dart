import 'dart:math' as math;
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/shape_entity.dart';

/// Service for interpolating vehicle positions along GTFS shapes
/// 
/// This service handles the core logic for smooth vehicle position updates
/// between 30-second GTFS realtime feeds. It uses vehicle speed and elapsed
/// time to calculate accurate positions along route shapes.
class VehicleInterpolationService {
  /// Default speed to use when vehicle speed data is unavailable (m/s)
  /// 
  /// This is approximately 40 km/h (11.11 m/s), a reasonable average
  /// speed for urban transit vehicles.
  static const double _defaultSpeedMetersPerSecond = 11.11;

  /// Minimum speed threshold to consider vehicle as moving (m/s)
  /// 
  /// Vehicles below this speed (0.5 m/s = 1.8 km/h) are considered stopped
  /// and won't be interpolated.
  static const double _minimumMovingSpeed = 0.5;

  /// Maximum reasonable speed for transit vehicles (m/s)
  /// 
  /// This is approximately 120 km/h (33.33 m/s). Speeds above this are
  /// likely data errors and will be capped.
  static const double _maximumSpeedMetersPerSecond = 33.33;

  /// Calculates the interpolated position of a vehicle along its shape
  /// 
  /// Uses the vehicle's speed and elapsed time since last update to determine
  /// how far the vehicle has traveled, then moves it along the shape accordingly.
  /// 
  /// [vehicle] - The vehicle entity with current position and speed
  /// [shape] - The GTFS shape entity representing the route path
  /// [lastUpdateTime] - When the vehicle position was last updated from GTFS realtime
  /// [currentPositionOnShape] - Optional cached position along shape (distance in meters)
  /// 
  /// Returns: A tuple of (interpolatedVehicle, newPositionOnShape) or null if interpolation fails
  ({VehicleEntity vehicle, double positionOnShape})? calculateInterpolatedPosition({
    required VehicleEntity vehicle,
    required ShapeEntity shape,
    required DateTime lastUpdateTime,
    double? currentPositionOnShape,
  }) {
    // Validate shape has points
    if (shape.points.isEmpty) {
      return null;
    }

    // Calculate time elapsed since last update
    final DateTime now = DateTime.now();
    final Duration timeSinceUpdate = now.difference(lastUpdateTime);
    final double secondsElapsed = timeSinceUpdate.inMilliseconds / 1000.0;

    // Get vehicle speed in m/s
    // GTFS realtime provides speed in m/s, but may be null
    double speedMetersPerSecond = vehicle.speed ?? _defaultSpeedMetersPerSecond;

    // Clamp speed to reasonable bounds
    speedMetersPerSecond = speedMetersPerSecond.clamp(
      _minimumMovingSpeed,
      _maximumSpeedMetersPerSecond,
    );

    // If vehicle is stopped or moving very slowly, don't interpolate
    if (speedMetersPerSecond < _minimumMovingSpeed) {
      return null;
    }

    // Calculate distance traveled since last update
    final double distanceTraveled = speedMetersPerSecond * secondsElapsed;

    // Find current position on shape if not cached
    final double startPosition = currentPositionOnShape ?? 
        findPositionOnShape(vehicle, shape);

    // Calculate new position on shape
    final double newPosition = startPosition + distanceTraveled;

    // Interpolate along shape to find new coordinates
    final ({double latitude, double longitude, double bearing})? interpolated = 
        _interpolateAlongShape(shape, newPosition);

    if (interpolated == null) {
      return null;
    }

    // Create updated vehicle with interpolated position
    final VehicleEntity interpolatedVehicle = vehicle.copyWith(
      latitude: interpolated.latitude,
      longitude: interpolated.longitude,
      bearing: interpolated.bearing,
    );

    return (vehicle: interpolatedVehicle, positionOnShape: newPosition);
  }

  /// Checks if a vehicle is within the viewport bounds
  /// 
  /// [vehicle] - The vehicle to check
  /// [minLat] - Minimum latitude of viewport
  /// [maxLat] - Maximum latitude of viewport
  /// [minLon] - Minimum longitude of viewport
  /// [maxLon] - Maximum longitude of viewport
  /// [padding] - Optional padding factor (0.0 to 1.0) to expand bounds
  /// 
  /// Returns: true if vehicle is visible in viewport, false otherwise
  bool isVehicleInViewport({
    required VehicleEntity vehicle,
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    double padding = 0.1,
  }) {
    // Calculate padded bounds to include vehicles slightly outside viewport
    final double latPadding = (maxLat - minLat) * padding;
    final double lonPadding = (maxLon - minLon) * padding;

    final double paddedMinLat = minLat - latPadding;
    final double paddedMaxLat = maxLat + latPadding;
    final double paddedMinLon = minLon - lonPadding;
    final double paddedMaxLon = maxLon + lonPadding;

    // Check if vehicle is within padded bounds
    return vehicle.latitude >= paddedMinLat &&
           vehicle.latitude <= paddedMaxLat &&
           vehicle.longitude >= paddedMinLon &&
           vehicle.longitude <= paddedMaxLon;
  }

  /// Finds the position of a vehicle along its shape
  /// 
  /// Locates the nearest point on the shape to the vehicle's current position
  /// and calculates the distance along the shape to that point.
  /// 
  /// [vehicle] - The vehicle entity with current coordinates
  /// [shape] - The GTFS shape entity to search
  /// 
  /// Returns: Distance along shape in meters
  double findPositionOnShape(VehicleEntity vehicle, ShapeEntity shape) {
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
      final ({double distance, double fraction}) result = _pointToSegmentDistance(
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

  /// Interpolates a position along a shape given a distance
  /// 
  /// Walks along the shape polyline until reaching the specified distance,
  /// then calculates the exact coordinates at that point.
  /// 
  /// [shape] - The GTFS shape entity
  /// [distance] - Distance along shape in meters
  /// 
  /// Returns: Coordinates and bearing at the specified distance, or null if distance exceeds shape length
  ({double latitude, double longitude, double bearing})? _interpolateAlongShape(
    ShapeEntity shape,
    double distance,
  ) {
    if (shape.points.isEmpty) {
      return null;
    }

    // If distance is negative, return first point
    if (distance <= 0.0) {
      final ShapePoint firstPoint = shape.points.first;
      final double bearing = shape.points.length > 1
          ? _calculateBearing(
              firstPoint.latitude,
              firstPoint.longitude,
              shape.points[1].latitude,
              shape.points[1].longitude,
            )
          : 0.0;
      return (
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

      if (accumulatedDistance + segmentDistance >= distance) {
        // Target distance is within this segment
        final double remainingDistance = distance - accumulatedDistance;
        final double fraction = remainingDistance / segmentDistance;

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

        return (latitude: latitude, longitude: longitude, bearing: bearing);
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

    return (
      latitude: lastPoint.latitude,
      longitude: lastPoint.longitude,
      bearing: bearing,
    );
  }

  /// Calculates the perpendicular distance from a point to a line segment
  /// 
  /// [pointLat] - Latitude of the point
  /// [pointLon] - Longitude of the point
  /// [seg1Lat] - Latitude of segment start
  /// [seg1Lon] - Longitude of segment start
  /// [seg2Lat] - Latitude of segment end
  /// [seg2Lon] - Longitude of segment end
  /// 
  /// Returns: Distance in meters and fraction along segment (0.0 to 1.0)
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
      // Segment is a point, return distance to that point
      final double distance = _calculateDistance(pointLat, pointLon, seg1Lat, seg1Lon);
      return (distance: distance, fraction: 0.0);
    }

    // Calculate projection of point onto segment
    // Using dot product to find the closest point on the segment
    final double dx = seg2Lon - seg1Lon;
    final double dy = seg2Lat - seg1Lat;
    final double px = pointLon - seg1Lon;
    final double py = pointLat - seg1Lat;

    final double dotProduct = px * dx + py * dy;
    final double lengthSquared = dx * dx + dy * dy;
    double fraction = dotProduct / lengthSquared;

    // Clamp fraction to [0, 1] to stay within segment
    fraction = fraction.clamp(0.0, 1.0);

    // Calculate closest point on segment
    final double closestLat = seg1Lat + fraction * dy;
    final double closestLon = seg1Lon + fraction * dx;

    // Calculate distance from point to closest point on segment
    final double distance = _calculateDistance(pointLat, pointLon, closestLat, closestLon);

    return (distance: distance, fraction: fraction);
  }

  /// Calculates distance between two points using Haversine formula
  /// 
  /// [lat1] - Latitude of first point
  /// [lon1] - Longitude of first point
  /// [lat2] - Latitude of second point
  /// [lon2] - Longitude of second point
  /// 
  /// Returns: Distance in meters
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000.0; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Calculates bearing between two points
  /// 
  /// [lat1] - Latitude of first point
  /// [lon1] - Longitude of first point
  /// [lat2] - Latitude of second point
  /// [lon2] - Longitude of second point
  /// 
  /// Returns: Bearing in degrees (0-360)
  double _calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double dLon = _toRadians(lon2 - lon1);
    final double lat1Rad = _toRadians(lat1);
    final double lat2Rad = _toRadians(lat2);

    final double y = math.sin(dLon) * math.cos(lat2Rad);
    final double x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final double bearing = math.atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  /// Converts degrees to radians
  double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// Converts radians to degrees
  double _toDegrees(double radians) => radians * 180.0 / math.pi;
}

