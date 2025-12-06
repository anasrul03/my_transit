// This file contains manually defined protobuf message classes for GTFS Realtime
// Based on GTFS Realtime specification v2.0
// 
// Note: This is a simplified implementation. For production use, consider
// using the official GTFS Realtime protobuf definitions or generating
// them from the .proto file using protoc.

import 'dart:typed_data';
import 'dart:typed_data' show ByteData, Uint8List, Endian;

/// GTFS Realtime FeedMessage - root message containing all entities
/// 
/// This is the top-level message type in a GTFS Realtime feed.
/// It contains a header and a list of entities (vehicles, trips, alerts).
class FeedMessage {
  /// Header containing feed metadata
  FeedHeader? header;
  
  /// List of entities in the feed (vehicles, trips, alerts)
  List<FeedEntity> entity = [];
  
  FeedMessage();
  
  /// Creates a copy of this FeedMessage
  FeedMessage clone() => FeedMessage()
    ..header = header?.clone()
    ..entity = entity.map((e) => e.clone()).toList();
  
  /// Parse from protobuf buffer
  /// 
  /// This manually parses the protobuf binary format to extract
  /// the FeedMessage structure. This is a simplified parser that
  /// handles the basic GTFS Realtime structure.
  static FeedMessage fromBuffer(List<int> buffer) {
    final FeedMessage message = FeedMessage();
    final _ProtobufReader reader = _ProtobufReader(buffer);
    
    while (reader.hasNext()) {
      final int tag = reader.readTag();
      final int fieldNumber = tag >> 3;
      final int wireType = tag & 0x7;
      
      switch (fieldNumber) {
        case 1: // header
          if (wireType == 2) { // Length-delimited
            final int length = reader.readVarint();
            final List<int> headerBytes = reader.readBytes(length);
            message.header = FeedHeader.fromBuffer(headerBytes);
          }
          break;
        case 2: // entity (repeated)
          if (wireType == 2) { // Length-delimited
            final int length = reader.readVarint();
            final List<int> entityBytes = reader.readBytes(length);
            message.entity.add(FeedEntity.fromBuffer(entityBytes));
          }
          break;
        default:
          // Skip unknown fields
          reader.skipField(wireType);
      }
    }
    
    return message;
  }
}

/// GTFS Realtime FeedHeader - metadata about the feed
class FeedHeader {
  /// GTFS Realtime specification version (e.g., "2.0")
  String? gtfsRealtimeVersion;
  
  /// Incrementing counter for feed updates
  int? incrementality;
  
  /// Timestamp when this feed was generated (Unix time)
  int? timestamp;
  
  FeedHeader();
  
  /// Creates a copy of this FeedHeader
  FeedHeader clone() => FeedHeader()
    ..gtfsRealtimeVersion = gtfsRealtimeVersion
    ..incrementality = incrementality
    ..timestamp = timestamp;
  
  static FeedHeader fromBuffer(List<int> buffer) {
    final FeedHeader header = FeedHeader();
    final _ProtobufReader reader = _ProtobufReader(buffer);
    
    while (reader.hasNext()) {
      final int tag = reader.readTag();
      final int fieldNumber = tag >> 3;
      final int wireType = tag & 0x7;
      
      switch (fieldNumber) {
        case 1: // gtfs_realtime_version
          if (wireType == 2) { // String
            header.gtfsRealtimeVersion = reader.readString();
          }
          break;
        case 2: // incrementality
          if (wireType == 0) { // Varint
            header.incrementality = reader.readVarint();
          }
          break;
        case 3: // timestamp
          if (wireType == 0) { // Varint
            header.timestamp = reader.readVarint();
          }
          break;
        default:
          reader.skipField(wireType);
      }
    }
    
    return header;
  }
}

/// GTFS Realtime FeedEntity - a single entity in the feed
class FeedEntity {
  /// Unique identifier for this entity
  String? id;
  
  /// Whether this entity should be deleted (incremental updates)
  bool? isDeleted;
  
  /// Vehicle position data (if this entity is a vehicle)
  VehiclePosition? vehicle;
  
  FeedEntity();
  
  /// Creates a copy of this FeedEntity
  FeedEntity clone() => FeedEntity()
    ..id = id
    ..isDeleted = isDeleted
    ..vehicle = vehicle?.clone();
  
  static FeedEntity fromBuffer(List<int> buffer) {
    final FeedEntity entity = FeedEntity();
    final _ProtobufReader reader = _ProtobufReader(buffer);
    
    while (reader.hasNext()) {
      final int tag = reader.readTag();
      final int fieldNumber = tag >> 3;
      final int wireType = tag & 0x7;
      
      switch (fieldNumber) {
        case 1: // id
          if (wireType == 2) { // String
            entity.id = reader.readString();
          }
          break;
        case 2: // is_deleted
          if (wireType == 0) { // Varint (bool)
            entity.isDeleted = reader.readVarint() != 0;
          }
          break;
        case 3: // trip_update (not used for vehicle positions)
          reader.skipField(wireType);
          break;
        case 4: // vehicle (VehiclePosition) - field 4 in GTFS Realtime spec
          if (wireType == 2) { // Length-delimited
            final int length = reader.readVarint();
            final List<int> vehicleBytes = reader.readBytes(length);
            try {
              entity.vehicle = VehiclePosition.fromBuffer(vehicleBytes);
            } catch (e) {
              // Log error but continue - might be a parsing issue
              print('⚠️ Error parsing VehiclePosition: $e');
            }
          }
          break;
        case 5: // alert (not used for vehicle positions)
          reader.skipField(wireType);
          break;
        default:
          reader.skipField(wireType);
      }
    }
    
    return entity;
  }
}

/// GTFS Realtime VehiclePosition - vehicle position data
class VehiclePosition {
  /// Trip information for this vehicle
  TripDescriptor? trip;
  
  /// Vehicle descriptor (ID, label)
  VehicleDescriptor? vehicle;
  
  /// Current position (lat/lng)
  Position? position;
  
  /// Current bearing (degrees, 0-359)
  double? bearing;
  
  /// Current speed (m/s)
  double? speed;
  
  /// Odometer reading (meters)
  double? odometer;
  
  /// Timestamp when this position was recorded (Unix time)
  int? timestamp;
  
  /// Current stop sequence
  int? currentStopSequence;
  
  /// Current stop ID
  String? stopId;
  
  /// Current status (e.g., IN_TRANSIT_TO, STOPPED_AT)
  int? currentStatus;
  
  VehiclePosition();
  
  /// Creates a copy of this VehiclePosition
  VehiclePosition clone() => VehiclePosition()
    ..trip = trip?.clone()
    ..vehicle = vehicle?.clone()
    ..position = position?.clone()
    ..bearing = bearing
    ..speed = speed
    ..odometer = odometer
    ..timestamp = timestamp
    ..currentStopSequence = currentStopSequence
    ..stopId = stopId
    ..currentStatus = currentStatus;
  
  static VehiclePosition fromBuffer(List<int> buffer) {
    final VehiclePosition vehicle = VehiclePosition();
    final _ProtobufReader reader = _ProtobufReader(buffer);
    
    print('🚗 Parsing VehiclePosition from ${buffer.length} bytes');
    
    while (reader.hasNext()) {
      final int tag = reader.readTag();
      final int fieldNumber = tag >> 3;
      final int wireType = tag & 0x7;
      
      print('🚗 VehiclePosition field: $fieldNumber, wireType: $wireType');
      
      switch (fieldNumber) {
        case 1: // trip
          if (wireType == 2) { // Length-delimited
            final int length = reader.readVarint();
            final List<int> tripBytes = reader.readBytes(length);
            vehicle.trip = TripDescriptor.fromBuffer(tripBytes);
          }
          break;
        case 2: // vehicle
          if (wireType == 2) { // Length-delimited
            final int length = reader.readVarint();
            final List<int> vehicleDescBytes = reader.readBytes(length);
            vehicle.vehicle = VehicleDescriptor.fromBuffer(vehicleDescBytes);
          }
          break;
        case 3: // position
          print('🚗 Found position field (field 3), wireType: $wireType');
          if (wireType == 2) { // Length-delimited
            final int length = reader.readVarint();
            print('🚗 Position field length: $length bytes');
            final List<int> positionBytes = reader.readBytes(length);
            print('🚗 Parsing position for vehicle, ${positionBytes.length} bytes');
            try {
              vehicle.position = Position.fromBuffer(positionBytes);
              print('🚗 Position parsed successfully: lat=${vehicle.position?.latitude}, lon=${vehicle.position?.longitude}');
            } catch (e, stackTrace) {
              print('❌ Error parsing Position: $e');
              print('❌ Stack trace: $stackTrace');
              vehicle.position = null;
            }
          } else {
            print('⚠️ Position field has unexpected wire type: $wireType (expected 2 for length-delimited)');
            reader.skipField(wireType);
          }
          break;
        case 4: // current_stop_sequence
          if (wireType == 0) { // Varint
            vehicle.currentStopSequence = reader.readVarint();
          }
          break;
        case 5: // current_status
          if (wireType == 0) { // Varint
            vehicle.currentStatus = reader.readVarint();
          }
          break;
        case 6: // timestamp
          if (wireType == 0) { // Varint
            vehicle.timestamp = reader.readVarint();
          }
          break;
        case 7: // congestion_level
          // Skip for now
          reader.skipField(wireType);
          break;
        case 8: // stop_id
          if (wireType == 2) { // String
            vehicle.stopId = reader.readString();
          }
          break;
        case 9: // vehicle
          // Already handled above
          reader.skipField(wireType);
          break;
        case 10: // occupancy_status
          // Skip for now
          reader.skipField(wireType);
          break;
        default:
          // Log unknown fields to help debug - might be position in different format
          if (fieldNumber == 3) {
            print('⚠️ Field 3 (position) found with unexpected wireType: $wireType (expected 2 for length-delimited)');
          }
          print('🚗 Unknown VehiclePosition field: $fieldNumber, wireType: $wireType, skipping');
          reader.skipField(wireType);
      }
    }
    
    print('🚗 VehiclePosition parsed: hasPosition=${vehicle.position != null}, lat=${vehicle.position?.latitude}, lon=${vehicle.position?.longitude}');
    return vehicle;
  }
}

/// GTFS Realtime TripDescriptor - trip information
class TripDescriptor {
  /// Trip ID from GTFS static
  String? tripId;
  
  /// Route ID from GTFS static
  String? routeId;
  
  /// Direction ID (0 or 1)
  int? directionId;
  
  /// Start time of the trip (HH:MM:SS format)
  String? startTime;
  
  /// Start date of the trip (YYYYMMDD format)
  String? startDate;
  
  /// Schedule relationship (SCHEDULED, ADDED, etc.)
  int? scheduleRelationship;
  
  TripDescriptor();
  
  /// Creates a copy of this TripDescriptor
  TripDescriptor clone() => TripDescriptor()
    ..tripId = tripId
    ..routeId = routeId
    ..directionId = directionId
    ..startTime = startTime
    ..startDate = startDate
    ..scheduleRelationship = scheduleRelationship;
  
  static TripDescriptor fromBuffer(List<int> buffer) {
    final TripDescriptor trip = TripDescriptor();
    final _ProtobufReader reader = _ProtobufReader(buffer);
    
    while (reader.hasNext()) {
      final int tag = reader.readTag();
      final int fieldNumber = tag >> 3;
      final int wireType = tag & 0x7;
      
      switch (fieldNumber) {
        case 1: // trip_id
          if (wireType == 2) { // String
            trip.tripId = reader.readString();
          }
          break;
        case 3: // route_id
          if (wireType == 2) { // String
            trip.routeId = reader.readString();
          }
          break;
        case 4: // direction_id
          if (wireType == 0) { // Varint
            trip.directionId = reader.readVarint();
          }
          break;
        case 5: // start_time
          if (wireType == 2) { // String
            trip.startTime = reader.readString();
          }
          break;
        case 6: // start_date
          if (wireType == 2) { // String
            trip.startDate = reader.readString();
          }
          break;
        case 7: // schedule_relationship
          if (wireType == 0) { // Varint
            trip.scheduleRelationship = reader.readVarint();
          }
          break;
        default:
          reader.skipField(wireType);
      }
    }
    
    return trip;
  }
}

/// GTFS Realtime VehicleDescriptor - vehicle identification
class VehicleDescriptor {
  /// Vehicle ID
  String? id;
  
  /// Vehicle label (display name)
  String? label;
  
  /// License plate
  String? licensePlate;
  
  VehicleDescriptor();
  
  /// Creates a copy of this VehicleDescriptor
  VehicleDescriptor clone() => VehicleDescriptor()
    ..id = id
    ..label = label
    ..licensePlate = licensePlate;
  
  static VehicleDescriptor fromBuffer(List<int> buffer) {
    final VehicleDescriptor vehicle = VehicleDescriptor();
    final _ProtobufReader reader = _ProtobufReader(buffer);
    
    while (reader.hasNext()) {
      final int tag = reader.readTag();
      final int fieldNumber = tag >> 3;
      final int wireType = tag & 0x7;
      
      switch (fieldNumber) {
        case 1: // id
          if (wireType == 2) { // String
            vehicle.id = reader.readString();
          }
          break;
        case 2: // label
          if (wireType == 2) { // String
            vehicle.label = reader.readString();
          }
          break;
        case 3: // license_plate
          if (wireType == 2) { // String
            vehicle.licensePlate = reader.readString();
          }
          break;
        default:
          reader.skipField(wireType);
      }
    }
    
    return vehicle;
  }
}

/// GTFS Realtime Position - geographic position
class Position {
  /// Latitude in degrees
  double? latitude;
  
  /// Longitude in degrees
  double? longitude;
  
  /// Bearing in degrees (0-359, clockwise from North)
  double? bearing;
  
  /// Speed in meters per second
  double? speed;
  
  /// Odometer reading in meters
  double? odometer;
  
  Position();
  
  /// Creates a copy of this Position
  Position clone() => Position()
    ..latitude = latitude
    ..longitude = longitude
    ..bearing = bearing
    ..speed = speed
    ..odometer = odometer;
  
  static Position fromBuffer(List<int> buffer) {
    final Position position = Position();
    final _ProtobufReader reader = _ProtobufReader(buffer);
    
    print('📍 Parsing Position from ${buffer.length} bytes');
    
    while (reader.hasNext()) {
      final int tag = reader.readTag();
      final int fieldNumber = tag >> 3;
      final int wireType = tag & 0x7;
      
      print('📍 Position field: $fieldNumber, wireType: $wireType');
      
      switch (fieldNumber) {
        case 1: // latitude
          if (wireType == 5) { // Fixed32 (float)
            position.latitude = reader.readFloat();
            print('📍 Read latitude (float): ${position.latitude}');
          } else if (wireType == 1) { // Fixed64 (double)
            position.latitude = reader.readDouble();
            print('📍 Read latitude (double): ${position.latitude}');
          } else {
            // Unexpected wire type for latitude, skip it
            print('⚠️ Unexpected wire type $wireType for latitude field, skipping');
            reader.skipField(wireType);
          }
          break;
        case 2: // longitude
          if (wireType == 5) { // Fixed32 (float)
            position.longitude = reader.readFloat();
            print('📍 Read longitude (float): ${position.longitude}');
          } else if (wireType == 1) { // Fixed64 (double)
            position.longitude = reader.readDouble();
            print('📍 Read longitude (double): ${position.longitude}');
          } else {
            // Unexpected wire type for longitude, skip it
            print('⚠️ Unexpected wire type $wireType for longitude field, skipping');
            reader.skipField(wireType);
          }
          break;
        case 3: // bearing
          if (wireType == 5) { // Fixed32 (float)
            position.bearing = reader.readFloat();
          } else if (wireType == 1) { // Fixed64 (double)
            position.bearing = reader.readDouble();
          }
          break;
        case 4: // speed
          if (wireType == 5) { // Fixed32 (float)
            position.speed = reader.readFloat();
          } else if (wireType == 1) { // Fixed64 (double)
            position.speed = reader.readDouble();
          }
          break;
        case 5: // odometer
          if (wireType == 5) { // Fixed32 (float)
            position.odometer = reader.readFloat();
          } else if (wireType == 1) { // Fixed64 (double)
            position.odometer = reader.readDouble();
          }
          break;
        default:
          reader.skipField(wireType);
      }
    }
    
    print('📍 Position parsed: lat=${position.latitude}, lon=${position.longitude}');
    return position;
  }
}

/// Simple protobuf reader for manual parsing
class _ProtobufReader {
  final List<int> _buffer;
  int _offset = 0;
  
  _ProtobufReader(this._buffer);
  
  bool hasNext() => _offset < _buffer.length;
  
  int readTag() {
    return readVarint();
  }
  
  int readVarint() {
    int result = 0;
    int shift = 0;
    while (_offset < _buffer.length) {
      final int byte = _buffer[_offset++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) {
        break;
      }
      shift += 7;
    }
    return result;
  }
  
  String readString() {
    final int length = readVarint();
    final List<int> bytes = _buffer.sublist(_offset, _offset + length);
    _offset += length;
    return String.fromCharCodes(bytes);
  }
  
  List<int> readBytes(int length) {
    final List<int> bytes = _buffer.sublist(_offset, _offset + length);
    _offset += length;
    return bytes;
  }
  
  double readFloat() {
    // Read 4 bytes as IEEE 754 float using Dart's ByteData
    if (_offset + 4 > _buffer.length) {
      throw Exception('Not enough bytes for float');
    }
    final ByteData byteData = ByteData.sublistView(
      Uint8List.fromList(_buffer),
      _offset,
      _offset + 4,
    );
    final double value = byteData.getFloat32(0, Endian.little);
    _offset += 4;
    return value;
  }
  
  double readDouble() {
    // Read 8 bytes as IEEE 754 double using Dart's ByteData
    if (_offset + 8 > _buffer.length) {
      throw Exception('Not enough bytes for double');
    }
    final ByteData byteData = ByteData.sublistView(
      Uint8List.fromList(_buffer),
      _offset,
      _offset + 8,
    );
    final double value = byteData.getFloat64(0, Endian.little);
    _offset += 8;
    return value;
  }
  
  void skipField(int wireType) {
    switch (wireType) {
      case 0: // Varint
        readVarint();
        break;
      case 1: // Fixed64
        _offset += 8;
        break;
      case 2: // Length-delimited
        final int length = readVarint();
        _offset += length;
        break;
      case 5: // Fixed32
        _offset += 4;
        break;
      case 3: // Start group (deprecated, not used in proto3)
      case 4: // End group (deprecated, not used in proto3)
        // These are deprecated wire types from proto2, skip them
        // For start/end group, we need to skip until we find the matching end
        // For simplicity, just skip 1 byte (this is a simplified approach)
        if (_offset < _buffer.length) {
          _offset++;
        }
        break;
      default:
        // For any other unknown wire types, log a warning but don't throw
        // This allows parsing to continue even with unknown fields
        // Note: Using print instead of debugPrint since this file doesn't import foundation
        print('⚠️ Unknown wire type: $wireType, skipping field');
        // Try to skip at least 1 byte to avoid infinite loops
        if (_offset < _buffer.length) {
          _offset++;
        }
        break;
    }
  }
  
}

