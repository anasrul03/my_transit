import 'package:geolocator/geolocator.dart';
import '../errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';

class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position
  Future<Result<Position>> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Result.failure(
          LocationFailure('Location services are disabled'),
        );
      }

      // Check permission
      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          return const Result.failure(
            LocationFailure('Location permissions are denied'),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Result.failure(
          LocationFailure(
            'Location permissions are permanently denied',
          ),
        );
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return Result.success(position);
    } catch (e) {
      return Result.failure(
        LocationFailure('Failed to get location: ${e.toString()}'),
      );
    }
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate bearing between two coordinates
  double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }
}

