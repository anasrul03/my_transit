import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/vehicle_entity.dart';

/// Service for creating and managing vehicle markers on the Mapbox map
/// 
/// This service provides helper methods to convert VehicleEntity objects
/// into PointAnnotationOptions that can be displayed on the map. It handles
/// icon selection, rotation, and styling based on vehicle properties.
class VehicleMarkerService {
  /// Default icon size for vehicle markers
  /// 
  /// This size provides good visibility without cluttering the map
  static const double defaultIconSize = 0.5;

  /// Default icon name for vehicles
  /// 
  /// Uses Mapbox's built-in bus icon as the default marker
  static const String defaultIconName = 'bus';

  /// Creates a CircleAnnotationOptions from a VehicleEntity
  /// 
  /// This method converts a vehicle entity into a map annotation with:
  /// - Position based on vehicle latitude/longitude
  /// - Circle radius and color for visibility
  /// 
  /// Using CircleAnnotation instead of PointAnnotation because it doesn't
  /// require images and is simpler to use.
  /// 
  /// [vehicle] - The vehicle entity to convert to an annotation
  /// 
  /// Returns: CircleAnnotationOptions configured for the vehicle
  static CircleAnnotationOptions createAnnotationFromVehicle(VehicleEntity vehicle) {
    // Create circle annotation with vehicle position
    // Position uses longitude first (x), then latitude (y) as per GeoJSON spec
    final CircleAnnotationOptions options = CircleAnnotationOptions(
      geometry: Point(
        coordinates: Position(vehicle.longitude, vehicle.latitude),
      ),
      // Set circle radius for visibility (8 pixels)
      circleRadius: 8.0,
      // Set circle color to blue for visibility
      circleColor: 0xFF007AFF, // Blue color in ARGB format
      // Set circle stroke color to white for contrast
      circleStrokeColor: 0xFFFFFFFF, // White stroke
      // Set circle stroke width
      circleStrokeWidth: 2.0,
    );

    return options;
  }

}

