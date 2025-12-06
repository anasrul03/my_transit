import '../../models/gtfs/route_dto.dart';
import '../../models/gtfs/stop_dto.dart';
import '../../models/gtfs/shape_dto.dart';
import '../../models/gtfs/trip_dto.dart';
import '../../models/gtfs/stop_time_dto.dart';
import '../../models/gtfs/agency_dto.dart';
import '../../models/gtfs/frequency_dto.dart';
import '../../models/gtfs/transfer_dto.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repositories/auth_repository.dart';

/// Parser for GTFS Static CSV files
class GtfsStaticParser {
  /// Parse CSV content into a list of maps
  List<Map<String, String>> _parseCsv(String csvContent) {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return [];

    // First line is header
    final headers = lines[0].split(',').map((h) => h.trim()).toList();
    
    // Parse data rows
    final rows = <Map<String, String>>[];
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      
      final values = _parseCsvLine(lines[i]);
      if (values.length != headers.length) continue;
      
      final row = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = values[j].trim();
      }
      rows.add(row);
    }
    
    return rows;
  }

  /// Parse a CSV line handling quoted values
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = '';
    var inQuotes = false;
    
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    result.add(current);
    
    return result;
  }

  /// Parse routes.txt
  Future<Result<List<RouteDto>>> parseRoutes(String csvContent) async {
    try {
      final rows = _parseCsv(csvContent);
      final routes = rows.map((row) => RouteDto.fromCsv(row)).toList();
      return Result.success(routes);
    } catch (e) {
      return Result.failure(
        GtfsParsingFailure('Failed to parse routes: ${e.toString()}'),
      );
    }
  }

  /// Parse stops.txt
  Future<Result<List<StopDto>>> parseStops(String csvContent) async {
    try {
      final rows = _parseCsv(csvContent);
      final stops = rows.map((row) => StopDto.fromCsv(row)).toList();
      return Result.success(stops);
    } catch (e) {
      return Result.failure(
        GtfsParsingFailure('Failed to parse stops: ${e.toString()}'),
      );
    }
  }

  /// Parse shapes.txt
  Future<Result<Map<String, ShapeDto>>> parseShapes(String csvContent) async {
    try {
      final rows = _parseCsv(csvContent);
      final shapesMap = <String, List<ShapePointDto>>{};
      
      for (final row in rows) {
        final shapeId = row['shape_id'] ?? '';
        if (shapeId.isEmpty) continue;
        
        final point = ShapePointDto.fromCsv(row);
        shapesMap.putIfAbsent(shapeId, () => []).add(point);
      }
      
      // Sort points by sequence and create ShapeDto objects
      final shapes = shapesMap.map((shapeId, points) {
        points.sort((a, b) => a.sequence.compareTo(b.sequence));
        return MapEntry(shapeId, ShapeDto(id: shapeId, points: points));
      });
      
      return Result.success(shapes);
    } catch (e) {
      return Result.failure(
        GtfsParsingFailure('Failed to parse shapes: ${e.toString()}'),
      );
    }
  }

  /// Parse trips.txt
  Future<Result<List<TripDto>>> parseTrips(String csvContent) async {
    try {
      final rows = _parseCsv(csvContent);
      final trips = rows.map((row) => TripDto.fromCsv(row)).toList();
      return Result.success(trips);
    } catch (e) {
      return Result.failure(
        GtfsParsingFailure('Failed to parse trips: ${e.toString()}'),
      );
    }
  }

  /// Parse stop_times.txt
  Future<Result<List<StopTimeDto>>> parseStopTimes(String csvContent) async {
    try {
      final rows = _parseCsv(csvContent);
      final stopTimes = rows.map((row) => StopTimeDto.fromCsv(row)).toList();
      return Result.success(stopTimes);
    } catch (e) {
      return Result.failure(
        GtfsParsingFailure('Failed to parse stop_times: ${e.toString()}'),
      );
    }
  }

  /// Parse agency.txt
  /// 
  /// Parses the agency.txt file which contains transit agency information.
  /// This file is required in GTFS feeds and contains agency details like name, URL, and timezone.
  Future<Result<List<AgencyDto>>> parseAgencies(String csvContent) async {
    try {
      final rows = _parseCsv(csvContent);
      final agencies = rows.map((row) => AgencyDto.fromCsv(row)).toList();
      return Result.success(agencies);
    } catch (e) {
      return Result.failure(
        GtfsParsingFailure('Failed to parse agencies: ${e.toString()}'),
      );
    }
  }

  /// Parse frequencies.txt
  /// 
  /// Parses the frequencies.txt file which represents trips that operate on regular headways.
  /// This file is optional and can represent frequency-based service or compressed schedule-based service.
  Future<Result<List<FrequencyDto>>> parseFrequencies(String csvContent) async {
    try {
      final rows = _parseCsv(csvContent);
      final frequencies = rows.map((row) => FrequencyDto.fromCsv(row)).toList();
      return Result.success(frequencies);
    } catch (e) {
      return Result.failure(
        GtfsParsingFailure('Failed to parse frequencies: ${e.toString()}'),
      );
    }
  }

  /// Parse transfers.txt
  /// 
  /// Parses the transfers.txt file which specifies additional rules and overrides for selected transfers.
  /// This file is optional and provides explicit transfer rules between routes.
  Future<Result<List<TransferDto>>> parseTransfers(String csvContent) async {
    try {
      final rows = _parseCsv(csvContent);
      final transfers = rows.map((row) => TransferDto.fromCsv(row)).toList();
      return Result.success(transfers);
    } catch (e) {
      return Result.failure(
        GtfsParsingFailure('Failed to parse transfers: ${e.toString()}'),
      );
    }
  }
}

