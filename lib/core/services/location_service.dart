import 'package:geolocator/geolocator.dart';
import '../errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';

/// Service for managing device location services and permissions
/// 
/// This service provides a high-level interface for location-related operations,
/// including checking permissions, requesting permissions, getting current position,
/// and calculating distances and bearings between coordinates. It wraps the
/// Geolocator package and provides error handling through the Result type.
class LocationService {
  /// Checks if location services are enabled on the device
  /// 
  /// Returns true if location services (GPS, network location) are enabled,
  /// false otherwise. This should be checked before attempting to get location.
  /// 
  /// Returns: Future<bool> indicating if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Checks the current location permission status
  /// 
  /// This method checks what permission level the app currently has for
  /// accessing device location. It does not request permission, only checks status.
  /// 
  /// Returns: Future<LocationPermission> indicating current permission level
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Requests location permission from the user
  /// 
  /// This method prompts the user to grant location permissions if they haven't
  /// already. The permission dialog will only show if permission hasn't been
  /// granted or permanently denied.
  /// 
  /// Returns: Future<LocationPermission> indicating the permission result
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Gets the current device position
  /// 
  /// This method handles the complete flow of getting the current location:
  /// 1. Checks if location services are enabled
  /// 2. Checks and requests permissions if needed
  /// 3. Gets the current position with high accuracy
  /// 
  /// Returns: Result<Position> containing either the position or a LocationFailure
  /// 
  /// The method will return a failure if:
  /// - Location services are disabled
  /// - Permissions are denied or permanently denied
  /// - An error occurs while getting the position
  Future<Result<Position>> getCurrentPosition() async {
    try {
      // Step 1: Check if location services are enabled on the device
      // If disabled, we cannot proceed with getting location
      final bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Result.failure(
          LocationFailure('Location services are disabled'),
        );
      }

      // Step 2: Check current permission status
      // If denied, attempt to request permission
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission and check the result
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          // User denied permission, cannot proceed
          return const Result.failure(
            LocationFailure('Location permissions are denied'),
          );
        }
      }

      // Step 3: Check if permission was permanently denied
      // If so, user must enable it in settings manually
      if (permission == LocationPermission.deniedForever) {
        return const Result.failure(
          LocationFailure(
            'Location permissions are permanently denied',
          ),
        );
      }

      // Step 4: Get current position with high accuracy
      // High accuracy provides the most precise location data
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return Result.success(position);
    } catch (e) {
      // Catch any unexpected errors and return as failure
      return Result.failure(
        LocationFailure('Failed to get location: ${e.toString()}'),
      );
    }
  }

  /// Calculates the distance between two coordinates in meters
  /// 
  /// Uses the Haversine formula to calculate the great-circle distance
  /// between two points on Earth's surface.
  /// 
  /// [lat1] - Latitude of the first point
  /// [lon1] - Longitude of the first point
  /// [lat2] - Latitude of the second point
  /// [lon2] - Longitude of the second point
  /// 
  /// Returns: Distance in meters between the two points
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculates the bearing (direction) between two coordinates
  /// 
  /// The bearing is the compass direction from the first point to the second,
  /// measured in degrees clockwise from north (0-360 degrees).
  /// 
  /// [lat1] - Latitude of the starting point
  /// [lon1] - Longitude of the starting point
  /// [lat2] - Latitude of the destination point
  /// [lon2] - Longitude of the destination point
  /// 
  /// Returns: Bearing in degrees (0-360) from first point to second point
  double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }
}

