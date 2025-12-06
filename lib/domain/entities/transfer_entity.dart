import 'package:equatable/equatable.dart';

/// Domain entity representing transfer rules from GTFS transfers.txt
/// 
/// Specifies additional rules and overrides for selected transfers between routes.
/// When calculating an itinerary, GTFS-consuming applications interpolate transfers
/// based on allowable time and stop proximity. This entity provides explicit transfer rules.
class TransferEntity extends Equatable {
  /// Identifies a stop or station where a connection between routes begins (conditionally required).
  /// Required if transfer_type is 1, 2, or 3.
  /// Optional if transfer_type is 4 or 5.
  /// Foreign key referencing stops.stop_id.
  final String? fromStopId;
  
  /// Identifies a stop or station where a connection between routes ends (conditionally required).
  /// Required if transfer_type is 1, 2, or 3.
  /// Optional if transfer_type is 4 or 5.
  /// Foreign key referencing stops.stop_id.
  final String? toStopId;
  
  /// Identifies a route where a connection begins (optional).
  /// Foreign key referencing routes.route_id.
  /// If both from_trip_id and from_route_id are defined, from_trip_id takes precedence.
  final String? fromRouteId;
  
  /// Identifies a route where a connection ends (optional).
  /// Foreign key referencing routes.route_id.
  /// If both to_trip_id and to_route_id are defined, to_trip_id takes precedence.
  final String? toRouteId;
  
  /// Identifies a trip where a connection between routes begins (conditionally required).
  /// Required if transfer_type is 4 or 5.
  /// Foreign key referencing trips.trip_id.
  /// If both from_trip_id and from_route_id are defined, from_trip_id takes precedence.
  final String? fromTripId;
  
  /// Identifies a trip where a connection between routes ends (conditionally required).
  /// Required if transfer_type is 4 or 5.
  /// Foreign key referencing trips.trip_id.
  /// If both to_trip_id and to_route_id are defined, to_trip_id takes precedence.
  final String? toTripId;
  
  /// Indicates the type of connection for the specified (from_stop_id, to_stop_id) pair (required).
  /// Valid values:
  /// 0 or empty - Recommended transfer point between routes
  /// 1 - Timed transfer point (departing vehicle waits for arriving one)
  /// 2 - Transfer requires minimum time (specified by min_transfer_time)
  /// 3 - Transfers are not possible between routes at the location
  /// 4 - In-seat transfer allowed (passengers stay onboard same vehicle)
  /// 5 - In-seat transfers not allowed (passengers must alight and re-board)
  final int transferType;
  
  /// Amount of time, in seconds, that must be available to permit a transfer (optional).
  /// Only relevant when transfer_type is 2.
  /// Must be a non-negative integer.
  final int? minTransferTime;

  const TransferEntity({
    this.fromStopId,
    this.toStopId,
    this.fromRouteId,
    this.toRouteId,
    this.fromTripId,
    this.toTripId,
    required this.transferType,
    this.minTransferTime,
  });

  @override
  List<Object?> get props => [
        fromStopId,
        toStopId,
        fromRouteId,
        toRouteId,
        fromTripId,
        toTripId,
        transferType,
        minTransferTime,
      ];
}

