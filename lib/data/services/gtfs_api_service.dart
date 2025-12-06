import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class GtfsApiService {
  final http.Client _client;

  GtfsApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch GTFS Realtime feed (protobuf format)
  Future<List<int>> fetchRealtimeFeed() async {
    final url = Uri.parse('${ApiConstants.gtfsRealtimeBaseUrl}${ApiConstants.gtfsRealtimeEndpoint}');
    final response = await _client.get(url);
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to fetch realtime feed: ${response.statusCode}');
    }
  }

  /// Fetch GTFS Static file (ZIP format)
  Future<List<int>> fetchStaticGtfs() async {
    final url = Uri.parse('${ApiConstants.gtfsStaticBaseUrl}${ApiConstants.gtfsStaticEndpoint}');
    final response = await _client.get(url);
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to fetch static GTFS: ${response.statusCode}');
    }
  }

  /// Fetch a specific GTFS static file as text (CSV)
  Future<String> fetchStaticFile(String filename) async {
    final url = Uri.parse('$filename');
    final response = await _client.get(url);
    
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to fetch $filename: ${response.statusCode}');
    }
  }

  void dispose() {
    _client.close();
  }
}

