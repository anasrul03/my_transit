import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class representing the currently highlighted route on the map
/// 
/// This state tracks which vehicle's route is currently highlighted,
/// along with the shape ID and route color for drawing the route polyline.
class RouteHighlightState {
  /// ID of the vehicle whose route is currently highlighted, or null if none
  final String? highlightedVehicleId;
  
  /// ID of the shape being highlighted, or null if none
  final String? highlightedShapeId;
  
  /// Route color for the highlight (hex string, e.g., "CF3476"), or null if none
  final String? highlightedRouteColor;

  const RouteHighlightState({
    this.highlightedVehicleId,
    this.highlightedShapeId,
    this.highlightedRouteColor,
  });

  /// Whether a route is currently highlighted
  bool get isHighlighted => highlightedVehicleId != null && highlightedShapeId != null;

  /// Creates a copy of this state with the given fields replaced with new values
  RouteHighlightState copyWith({
    String? highlightedVehicleId,
    String? highlightedShapeId,
    String? highlightedRouteColor,
    bool clearHighlight = false,
  }) {
    if (clearHighlight) {
      return const RouteHighlightState();
    }
    return RouteHighlightState(
      highlightedVehicleId: highlightedVehicleId ?? this.highlightedVehicleId,
      highlightedShapeId: highlightedShapeId ?? this.highlightedShapeId,
      highlightedRouteColor: highlightedRouteColor ?? this.highlightedRouteColor,
    );
  }
}

/// Provider for managing route highlight state
/// 
/// This provider manages which vehicle's route is currently highlighted on the map.
/// It uses a StateNotifier to allow updating the highlight state.
final routeHighlightProvider = StateNotifierProvider<RouteHighlightNotifier, RouteHighlightState>((ref) {
  return RouteHighlightNotifier();
});

/// Notifier class for managing RouteHighlightState
/// 
/// Provides methods to highlight routes and clear highlights.
class RouteHighlightNotifier extends StateNotifier<RouteHighlightState> {
  /// Initializes the notifier with default state (no route highlighted)
  RouteHighlightNotifier() : super(const RouteHighlightState());

  /// Highlights a route for a specific vehicle
  /// 
  /// [vehicleId] - The ID of the vehicle whose route should be highlighted
  /// [shapeId] - The ID of the shape to highlight
  /// [routeColor] - Optional route color (hex string) for the highlight
  /// 
  /// This method updates the state to highlight the specified route,
  /// which will cause the map to draw the route shape as a polyline.
  void highlightRoute(String vehicleId, String shapeId, String? routeColor) {
    state = state.copyWith(
      highlightedVehicleId: vehicleId,
      highlightedShapeId: shapeId,
      highlightedRouteColor: routeColor,
    );
  }

  /// Clears the current route highlight
  /// 
  /// This method sets all highlight fields to null, which will cause
  /// the map to remove the highlighted route polyline.
  void clearHighlight() {
    state = state.copyWith(clearHighlight: true);
  }
}

