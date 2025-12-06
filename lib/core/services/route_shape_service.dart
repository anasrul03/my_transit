import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/shape_entity.dart';

/// Service for drawing route shapes as polylines on Mapbox maps
/// 
/// This service handles the creation and management of polyline annotations
/// that represent route shapes on the map. It converts route shapes into
/// Mapbox polyline annotations with appropriate styling.
class RouteShapeService {
  /// Default line width for route polylines (in pixels)
  /// 
  /// This width provides good visibility without being too thick
  static const double defaultLineWidth = 4.0;

  /// Default line color if route color is not provided (blue)
  /// 
  /// Color is in ARGB format: 0xFF007AFF
  static const int defaultLineColor = 0xFF007AFF;

  /// Converts a hex color string to ARGB integer
  /// 
  /// [hexColor] - Hex color string (e.g., "CF3476" or "#CF3476")
  /// 
  /// Returns: ARGB integer color (e.g., 0xFFCF3476)
  /// If the hex string is invalid, returns the default color.
  static int hexToArgb(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return defaultLineColor;
    }

    // Remove # if present
    String cleanHex = hexColor.startsWith('#') ? hexColor.substring(1) : hexColor;

    // Ensure we have 6 hex digits
    if (cleanHex.length != 6) {
      return defaultLineColor;
    }

    try {
      // Parse hex string and add alpha channel (0xFF for fully opaque)
      return int.parse('FF$cleanHex', radix: 16);
    } catch (e) {
      // If parsing fails, return default color
      return defaultLineColor;
    }
  }

  /// Converts a ShapeEntity to a LineString geometry for Mapbox
  /// 
  /// [shape] - The shape entity containing points to convert
  /// 
  /// Returns: LineString geometry with coordinates in [longitude, latitude] format
  static LineString _shapeToLineString(ShapeEntity shape) {
    // Convert shape points to coordinates array
    // Mapbox uses [longitude, latitude] format (x, y)
    final List<Position> coordinates = shape.points
        .map((point) => Position(point.longitude, point.latitude))
        .toList();

    return LineString(coordinates: coordinates);
  }

  /// Draws a route shape as a polyline on the map
  /// 
  /// [mapboxMap] - The MapboxMap instance to draw on
  /// [polylineManager] - The PolylineAnnotationManager to use for creating annotations
  /// [shape] - The shape entity to draw
  /// [routeColor] - Optional route color (hex string, e.g., "CF3476")
  /// 
  /// Returns: The created PolylineAnnotation, or null if creation fails
  /// 
  /// This method creates a polyline annotation representing the route shape.
  /// The polyline will be styled with the route color if provided, or a default blue color.
  static Future<PolylineAnnotation?> drawRouteShape(
    MapboxMap mapboxMap,
    PolylineAnnotationManager polylineManager,
    ShapeEntity shape,
    String? routeColor,
  ) async {
    try {
      // Convert shape to LineString geometry
      final LineString lineString = _shapeToLineString(shape);

      // Convert hex color to ARGB integer
      final int color = hexToArgb(routeColor);

      // Create polyline annotation options
      final PolylineAnnotationOptions options = PolylineAnnotationOptions(
        geometry: lineString,
        lineColor: color,
        lineWidth: defaultLineWidth,
        lineJoin: LineJoin.ROUND,
      );

      // Create and return the annotation
      final PolylineAnnotation annotation = await polylineManager.create(options);
      return annotation;
    } catch (e) {
      // Log error and return null if creation fails
      debugPrint('❌ Error drawing route shape: $e');
      return null;
    }
  }

  /// Clears a route shape polyline from the map
  /// 
  /// [polylineManager] - The PolylineAnnotationManager to use
  /// [annotation] - The PolylineAnnotation to remove
  /// 
  /// This method removes the specified polyline annotation from the map.
  static Future<void> clearRouteShape(
    PolylineAnnotationManager polylineManager,
    PolylineAnnotation annotation,
  ) async {
    try {
      await polylineManager.delete(annotation);
    } catch (e) {
      debugPrint('❌ Error clearing route shape: $e');
    }
  }
}

