import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../models/gtfs/gtfs-realtime.pb.dart';
import '../../../core/errors/failures.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/vehicle_entity.dart';
import '../../../domain/repositories/auth_repository.dart';

/// Parser for GTFS Realtime protobuf feed
/// 
/// This parser extracts vehicle position data from GTFS Realtime protobuf feeds.
/// It handles the FeedMessage structure and converts VehiclePosition entities
/// into VehicleEntity objects for use throughout the application.
class GtfsRealtimeParser {
  /// Current agency being parsed (for special handling like rapid-bus-penang)
  String? _currentAgency;
  
  /// Parse protobuf feed to list of vehicle entities
  /// 
  /// Parses the GTFS Realtime protobuf feed and extracts all vehicle positions.
  /// Handles missing fields gracefully and includes data quality warnings when detected.
  /// 
  /// [feedData] - The protobuf binary data from the API
  /// [agency] - Optional agency code for special handling (e.g., rapid-bus-penang)
  /// 
  /// Returns: Result containing list of VehicleEntity objects on success,
  ///          or GtfsParsingFailure on error
  Future<Result<List<VehicleEntity>>> parseFeed(
    Uint8List feedData, {
    String? agency,
  }) async {
    try {
      _currentAgency = agency;
      
      // Log feed data size for debugging
      debugPrint('📦 Parsing feed data: ${feedData.length} bytes');
      
      // Check if feed data is empty
      if (feedData.isEmpty) {
        debugPrint('⚠️ Empty feed data received');
        return const Result.success([]);
      }
      
      // Parse the protobuf FeedMessage
      FeedMessage feed;
      try {
        feed = FeedMessage.fromBuffer(feedData.toList());
        debugPrint('✅ Successfully parsed FeedMessage');
      } catch (e) {
        debugPrint('❌ Failed to parse FeedMessage: $e');
        // Try to get more details about the error
        debugPrint('📊 First 50 bytes: ${feedData.take(50).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
        rethrow;
      }
      
      // Extract vehicle positions from entities
      final List<VehicleEntity> vehicles = <VehicleEntity>[];
      int skippedNoPosition = 0;
      int skippedDeleted = 0;
      
      debugPrint('📊 Feed contains ${feed.entity.length} entities');
      
      for (int i = 0; i < feed.entity.length; i++) {
        final FeedEntity entity = feed.entity[i];
        
        // Skip deleted entities (incremental updates)
        if (entity.hasIsDeleted() && entity.isDeleted) {
          skippedDeleted++;
          continue;
        }
        
        // Only process entities with vehicle position data
        if (!entity.hasVehicle()) {
          continue;
        }
        
        try {
          final VehicleEntity? vehicle = _parseVehiclePosition(
            entity.vehicle,
            entity.hasId() ? entity.id : 'unknown_$i',
          );
          
          if (vehicle != null) {
            vehicles.add(vehicle);
          } else {
            skippedNoPosition++;
          }
        } catch (e, stackTrace) {
          // Log parsing error for this vehicle but continue with others
          debugPrint('⚠️ Failed to parse vehicle entity ${entity.hasId() ? entity.id : i}: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }
      
      debugPrint('📊 Feed parsing summary:');
      debugPrint('  ✅ Successfully parsed: ${vehicles.length} vehicles');
      if (skippedNoPosition > 0) {
        debugPrint('  ⏭️ Skipped (no/invalid position): $skippedNoPosition vehicles');
      }
      if (skippedDeleted > 0) {
        debugPrint('  ⏭️ Skipped (deleted): $skippedDeleted entities');
      }
      
      return Result.success(vehicles);
    } catch (e, stackTrace) {
      debugPrint('❌ Error parsing GTFS Realtime feed: $e');
      debugPrint('Stack trace: $stackTrace');
      return Result.failure(
        GtfsParsingFailure('Failed to parse realtime feed: ${e.toString()}'),
      );
    }
  }

  /// Parse a single vehicle position from protobuf VehiclePosition
  /// 
  /// Extracts all available vehicle data including position, trip info,
  /// speed, bearing, and timestamps. Handles missing fields gracefully.
  /// 
  /// [vehiclePosition] - The VehiclePosition protobuf message
  /// [entityId] - The entity ID from the feed (used as fallback vehicle ID)
  /// 
  /// Returns: VehicleEntity with all available data, or null if position is missing
  VehicleEntity? _parseVehiclePosition(
    VehiclePosition vehiclePosition,
    String entityId,
  ) {
    // Extract vehicle ID (prefer vehicle descriptor ID, fallback to entity ID)
    final String vehicleId = vehiclePosition.hasVehicle() 
        ? (vehiclePosition.vehicle.id.isNotEmpty 
            ? vehiclePosition.vehicle.id 
            : vehiclePosition.vehicle.label.isNotEmpty 
                ? vehiclePosition.vehicle.label 
                : entityId)
        : entityId;
    
    // Extract route and trip IDs
    final String routeId = vehiclePosition.hasTrip() ? vehiclePosition.trip.routeId : '';
    final String tripId = vehiclePosition.hasTrip() ? vehiclePosition.trip.tripId : '';
    
    // Handle trip ID mismatches for rapid-bus-penang (special case)
    if (_currentAgency == ApiConstants.agencyRapidBusPenang && tripId.isEmpty) {
      debugPrint('⚠️ Trip ID missing for rapid-bus-penang vehicle: $vehicleId');
    }
    
    // Extract position data - skip if missing
    if (!vehiclePosition.hasPosition()) {
      return null;
    }
    
    final Position position = vehiclePosition.position;
    
    // Skip vehicles without valid coordinates
    if (!position.hasLatitude() || !position.hasLongitude()) {
      return null;
    }
    
    final double latitude = position.latitude;
    final double longitude = position.longitude;
    
    // Skip vehicles with invalid coordinates (0.0, 0.0)
    if (latitude == 0.0 && longitude == 0.0) {
      return null;
    }
    
    // Extract bearing and speed from position
    final double? bearing = position.hasBearing() ? position.bearing : null;
    final double? speed = position.hasSpeed() ? position.speed : null;
    
    // Extract timestamp (convert from Unix timestamp seconds to DateTime)
    DateTime timestamp = DateTime.now().toUtc();
    if (vehiclePosition.hasTimestamp() && vehiclePosition.timestamp.toInt() > 0) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(
        vehiclePosition.timestamp.toInt() * 1000,
        isUtc: true,
      );
    }
    
    // Extract vehicle label
    final String? vehicleLabel = vehiclePosition.hasVehicle() && vehiclePosition.vehicle.hasLabel()
        ? vehiclePosition.vehicle.label 
        : null;
    
    // Check for data quality issues
    final List<String> dataQualityWarnings = <String>[];
    
    // E028: GPS coordinates outside service area
    // Malaysia bounds: approximately 0.85°N to 7.36°N, 99.64°E to 119.27°E
    if (latitude < 0.0 || latitude > 8.0 || longitude < 99.0 || longitude > 120.0) {
      dataQualityWarnings.add('E028');
    }
    
    return VehicleEntity(
      id: vehicleId,
      routeId: routeId,
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      bearing: bearing,
      speed: speed,
      timestamp: timestamp,
      operatorId: _currentAgency,
      vehicleLabel: vehicleLabel,
      dataQualityWarnings: dataQualityWarnings.isNotEmpty ? dataQualityWarnings : null,
    );
  }
}

