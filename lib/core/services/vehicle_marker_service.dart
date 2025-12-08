import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../constants/api_constants.dart';

/// Service for creating and managing vehicle markers on the Mapbox map
/// 
/// This service provides helper methods to convert VehicleEntity objects
/// into CircleAnnotationOptions that can be displayed on the map. It handles
/// color selection and styling based on vehicle operator (bus vs train).
class VehicleMarkerService {
  /// Circle radius for vehicle markers in pixels
  /// 
  /// This size provides good visibility without cluttering the map
  static const double markerRadius = 8.0;

  /// Circle stroke width in pixels
  static const double strokeWidth = 2.0;

  /// Color for bus markers (orange/amber)
  /// 
  /// Format: ARGB in hex (0xFFRRGGBB)
  static const int busColor = 0xFFFF9800; // Amber/Orange

  /// Color for train/rail markers (blue)
  /// 
  /// Format: ARGB in hex (0xFFRRGGBB)
  static const int trainColor = 0xFF2196F3; // Blue

  /// Default color for unknown vehicle types (gray)
  /// 
  /// Format: ARGB in hex (0xFFRRGGBB)
  static const int defaultColor = 0xFF9E9E9E; // Gray

  /// Stroke color for all markers (white)
  /// 
  /// Format: ARGB in hex (0xFFRRGGBB)
  static const int strokeColor = 0xFFFFFFFF; // White

  /// Rail/train operators
  /// 
  /// Only these operators have train/rail vehicles:
  /// - KTMB: National railway operator
  /// - Rapid Rail KL: Prasarana rail services (LRT, MRT, Monorail)
  static const List<String> railOperators = [
    ApiConstants.agencyKtmb,           // 'ktmb'
    ApiConstants.agencyRapidRailKl,    // 'rapid-rail-kl'
  ];

  /// Creates a CircleAnnotationOptions from a VehicleEntity
  /// 
  /// This method converts a vehicle entity into a map annotation with:
  /// - Position based on vehicle latitude/longitude
  /// - Circle radius and color based on vehicle operator (bus vs train)
  /// - White stroke for visibility against various backgrounds
  /// 
  /// Using CircleAnnotation instead of PointAnnotation because it doesn't
  /// require images and is simpler to use.
  /// 
  /// [vehicle] - The vehicle entity to convert to an annotation
  /// 
  /// Returns: CircleAnnotationOptions configured for the vehicle
  static CircleAnnotationOptions createAnnotationFromVehicle(VehicleEntity vehicle) {
    // Determine marker color based on vehicle operator
    final int markerColor = _getColorForVehicle(vehicle);

    // Create circle annotation with vehicle position
    // Position uses longitude first (x), then latitude (y) as per GeoJSON spec
    final CircleAnnotationOptions options = CircleAnnotationOptions(
      geometry: Point(
        coordinates: Position(vehicle.longitude, vehicle.latitude),
      ),
      // Set circle radius for visibility
      circleRadius: markerRadius,
      // Set circle color based on vehicle operator
      circleColor: markerColor,
      // Set circle stroke color to white for contrast
      circleStrokeColor: strokeColor,
      // Set circle stroke width
      circleStrokeWidth: strokeWidth,
    );

    return options;
  }

  /// Determines the appropriate color for a vehicle based on its operator
  /// 
  /// - KTMB and Rapid Rail KL (trains) get blue color 🚆
  /// - All other operators (buses) get orange/amber color 🚌
  /// - Unknown operators get gray color
  /// 
  /// [vehicle] - The vehicle entity to get color for
  /// 
  /// Returns: Color in ARGB hex format (0xFFRRGGBB)
  static int _getColorForVehicle(VehicleEntity vehicle) {
    // Check if vehicle has operator information
    if (vehicle.operatorId == null || vehicle.operatorId!.isEmpty) {
      return defaultColor;
    }

    // Return color based on operator
    if (railOperators.contains(vehicle.operatorId)) {
      return trainColor; // Blue for trains
    } else {
      return busColor; // Orange for buses
    }
  }
}

