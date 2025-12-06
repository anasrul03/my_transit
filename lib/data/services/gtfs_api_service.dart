import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';

/// Service for making API calls to GTFS Realtime and Static APIs
/// 
/// This service handles HTTP requests to the Malaysian government's GTFS APIs,
/// including proper headers, query parameters, error handling, and response validation.
class GtfsApiService {
  final http.Client _client;

  /// Creates a GtfsApiService instance
  /// 
  /// [client] - Optional HTTP client for testing. Defaults to http.Client()
  GtfsApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch GTFS Realtime feed (protobuf format)
  /// 
  /// Fetches real-time transit data from the GTFS Realtime API.
  /// The response is in protobuf format and contains vehicle positions, trip updates, or service alerts.
  /// 
  /// API endpoint format: `https://api.data.gov.my/gtfs-realtime/<feed>/<agency>?category=<category>`
  /// Examples:
  /// - KTMB: `https://api.data.gov.my/gtfs-realtime/vehicle-positions/ktmb`
  /// - Prasarana: `https://api.data.gov.my/gtfs-realtime/vehicle-positions/rapid-rail-kl?category=rapid-rail-kl`
  /// 
  /// [feed] - Feed type (default: 'vehicle-positions')
  ///          Options: 'vehicle-positions', 'trip-updates', 'service-alerts'
  /// [agency] - Required agency code (e.g., 'ktmb', 'rapid-rail-kl', 'bas-melaka')
  /// [category] - Optional category parameter (required for Prasarana agencies)
  ///              If not provided and agency is Prasarana, category will default to agency code
  /// 
  /// Returns: List of bytes containing the protobuf feed data
  /// 
  /// Throws: Appropriate Failure type based on HTTP status code
  Future<List<int>> fetchRealtimeFeed({
    String feed = ApiConstants.feedVehiclePositions,
    required String agency,
    String? category,
  }) async {
    // Build URL with feed and agency in path
    // Base URL ends with '/', so we append feed/agency directly
    final String path = '$feed/$agency';
    final String baseUrl = '${ApiConstants.gtfsRealtimeBaseUrl}$path';
    
    // For Prasarana agencies, category is required
    // If not provided, use agency code as category
    String? finalCategory = category;
    if (ApiConstants.isPrasaranaAgency(agency) && finalCategory == null) {
      finalCategory = agency;
    }
    
    // Build URI with optional category query parameter
    final Uri url = finalCategory != null
        ? Uri.parse(baseUrl).replace(queryParameters: {'category': finalCategory})
        : Uri.parse(baseUrl);
    
    // Debug: Log the actual URL being called
    debugPrint('🌐 Fetching realtime feed from: $url');
    
    // Set Accept header to request protobuf format (preferred) or octet-stream
    final Map<String, String> headers = {
      'Accept': 'application/x-protobuf, application/octet-stream',
    };
    
    try {
      final http.Response response = await _client.get(url, headers: headers);
      
      // Debug: Log response status
      debugPrint('📡 Response status: ${response.statusCode}');
      
      // Handle different HTTP status codes
      if (response.statusCode == 200) {
        // Validate Content-Type header matches expected protobuf format
        final String? contentType = response.headers['content-type'];
        if (contentType != null && 
            !contentType.contains('application/x-protobuf') && 
            !contentType.contains('application/octet-stream')) {
          debugPrint('⚠️ Unexpected Content-Type: $contentType');
          // Still return the data if it's valid protobuf (check magic bytes if needed)
        }
        debugPrint('✅ Successfully fetched realtime feed from: $url');
        return response.bodyBytes;
      } else {
        // Map HTTP status codes to appropriate failure types
        throw _handleHttpError(response.statusCode, response.body, 'realtime feed');
      }
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw ServerFailure('Failed to fetch realtime feed: ${e.toString()}');
    }
  }

  /// Fetch GTFS Static file (ZIP format)
  /// 
  /// Fetches static GTFS data (routes, stops, schedules) from the GTFS Static API.
  /// The response is a ZIP file containing CSV files with static transit data.
  /// 
  /// API endpoint format: `https://api.data.gov.my/gtfs-static/<agency>?category=<category>`
  /// Examples:
  /// - KTMB: `https://api.data.gov.my/gtfs-static/ktmb`
  /// - Prasarana: `https://api.data.gov.my/gtfs-static/rapid-rail-kl?category=rapid-rail-kl`
  /// 
  /// [agency] - Required agency code (e.g., 'ktmb', 'rapid-rail-kl', 'bas-melaka')
  /// [category] - Optional category parameter (required for Prasarana agencies)
  ///              If not provided and agency is Prasarana, category will default to agency code
  /// 
  /// This method handles cases where the server returns HTML (with wrong Content-Type)
  /// but the actual response body is a ZIP file. It validates the ZIP file signature
  /// (magic bytes) instead of relying solely on Content-Type headers.
  /// 
  /// Returns: List of bytes containing the ZIP file data
  /// 
  /// Throws: Appropriate Failure type based on HTTP status code
  Future<List<int>> fetchStaticGtfs({
    required String agency,
    String? category,
  }) async {
    // Build URL with agency in path
    final String baseUrl = '${ApiConstants.gtfsStaticBaseUrl}/$agency';
    
    // For Prasarana agencies, category is required
    // If not provided, use agency code as category
    String? finalCategory = category;
    if (ApiConstants.isPrasaranaAgency(agency) && finalCategory == null) {
      finalCategory = agency;
    }
    
    // Build URI with optional category query parameter
    final Uri url = finalCategory != null
        ? Uri.parse(baseUrl).replace(queryParameters: {'category': finalCategory})
        : Uri.parse(baseUrl);
    
    // Set Accept header to request ZIP format
    final Map<String, String> headers = {
      'Accept': 'application/zip, application/octet-stream, */*',
    };
    
    debugPrint('🌐 Fetching GTFS static data from: $url');
    
    final http.Response response = await _client.get(url, headers: headers);
    
    debugPrint('📡 Response status: ${response.statusCode}');
    debugPrint('📄 Content-Type: ${response.headers['content-type']}');
    debugPrint('📦 Response body size: ${response.bodyBytes.length} bytes');
    
    // Handle different HTTP status codes according to API documentation
    if (response.statusCode == 200) {
      // Check if response body is actually a ZIP file by checking magic bytes
      // ZIP files start with "PK" (0x50 0x4B) - the signature of ZIP format
      final List<int> bodyBytes = response.bodyBytes;
      
      if (bodyBytes.isEmpty) {
        throw ServerFailure('Received empty response from GTFS static API');
      }
      
      // Check for ZIP file signature (PK - 0x50 0x4B)
      final bool isZipFile = bodyBytes.length >= 2 && 
          bodyBytes[0] == 0x50 && 
          bodyBytes[1] == 0x4B;
      
      if (isZipFile) {
        // Response is a valid ZIP file, return it regardless of Content-Type
        debugPrint('✅ Valid ZIP file detected (magic bytes: PK)');
        return bodyBytes;
      } else {
        // Response is not a ZIP file - might be HTML error page or redirect
        final String? contentType = response.headers['content-type'];
        debugPrint('⚠️ Response is not a ZIP file. Content-Type: $contentType');
        
        // Check if response is HTML (common for error pages or redirects)
        if (contentType != null && contentType.contains('text/html')) {
          // Try to extract download link from HTML if present
          final String bodyText = response.body;
          
          // Look for common patterns in HTML that might indicate a download link
          // or check if there's a redirect to the actual ZIP file
          // Pattern: href="..." or href='...' containing .zip
          final RegExp zipLinkPattern = RegExp(
            'href=["\']([^"\']*\\.zip[^"\']*)["\']',
            caseSensitive: false,
          );
          final Match? match = zipLinkPattern.firstMatch(bodyText);
          
          if (match != null) {
            // Found a ZIP file link in HTML, try to fetch it
            final String zipUrl = match.group(1)!;
            debugPrint('🔗 Found ZIP file link in HTML: $zipUrl');
            
            // Handle relative URLs
            final Uri zipUri = zipUrl.startsWith('http')
                ? Uri.parse(zipUrl)
                : url.resolve(zipUrl);
            
            // Recursively fetch the ZIP file (with limit to prevent infinite loops)
            return await _fetchZipFromUrl(zipUri);
          }
          
          // If no link found, show error with HTML preview
          final String htmlPreview = bodyText.length > 500
              ? bodyText.substring(0, 500)
              : bodyText;
          throw ServerFailure(
            'Server returned HTML instead of ZIP file. '
            'This might indicate an error page or redirect. '
            'Response preview: ${htmlPreview.replaceAll(RegExp(r'\s+'), ' ')}',
          );
        }
        
        // Unknown content type that's not a ZIP file
        throw ServerFailure(
          'Response is not a valid ZIP file. '
          'Content-Type: ${contentType ?? 'unknown'}. '
          'Expected ZIP file signature (PK) but got: ${bodyBytes.take(10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
        );
      }
    } else {
      // Map HTTP status codes to appropriate failure types
      throw _handleHttpError(response.statusCode, response.body, 'static GTFS');
    }
  }

  /// Fetches a ZIP file from a URL with validation
  /// 
  /// This is a helper method to fetch ZIP files from URLs found in HTML responses.
  /// It validates that the response is actually a ZIP file before returning it.
  /// 
  /// [zipUrl] - The URL to fetch the ZIP file from
  /// 
  /// Returns: List of bytes containing the ZIP file data
  /// 
  /// Throws: ServerFailure if the response is not a valid ZIP file
  Future<List<int>> _fetchZipFromUrl(Uri zipUrl) async {
    debugPrint('🌐 Fetching ZIP file from: $zipUrl');
    
    final http.Response response = await _client.get(zipUrl);
    
    if (response.statusCode != 200) {
      throw _handleHttpError(response.statusCode, response.body, 'ZIP file');
    }
    
    final List<int> bodyBytes = response.bodyBytes;
    
    // Validate ZIP file signature
    if (bodyBytes.length < 2 || bodyBytes[0] != 0x50 || bodyBytes[1] != 0x4B) {
      throw ServerFailure(
        'Response from $zipUrl is not a valid ZIP file. '
        'Expected ZIP signature (PK) but got: ${bodyBytes.take(10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );
    }
    
    debugPrint('✅ Successfully fetched ZIP file from: $zipUrl');
    return bodyBytes;
  }

  /// Fetch a specific GTFS static file as text (CSV)
  /// 
  /// Fetches a specific static GTFS file by URL. This is used for fetching
  /// individual CSV files from the static GTFS data.
  /// 
  /// [filename] - The URL of the file to fetch
  /// 
  /// Returns: The file content as a string
  /// 
  /// Throws: Appropriate Failure type based on HTTP status code
  Future<String> fetchStaticFile(String filename) async {
    final Uri url = Uri.parse(filename);
    final http.Response response = await _client.get(url);
    
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw _handleHttpError(response.statusCode, response.body, filename);
    }
  }

  /// Handles HTTP error responses and maps them to appropriate Failure types
  /// 
  /// This method maps HTTP status codes to the appropriate failure types
  /// according to the GTFS API documentation:
  /// - 400: Bad Request → ServerFailure
  /// - 401: Unauthorized → AuthFailure
  /// - 403: Forbidden → AuthFailure
  /// - 404: Not Found → ServerFailure
  /// - 429: Too Many Requests → ServerFailure (rate limiting)
  /// - 500: Internal Server Error → ServerFailure
  /// - 503: Service Unavailable → ServerFailure
  /// 
  /// [statusCode] - The HTTP status code from the response
  /// [responseBody] - The response body (may contain error details)
  /// [resource] - Description of the resource that failed (for error messages)
  /// 
  /// Returns: A Failure instance appropriate for the status code
  Failure _handleHttpError(int statusCode, String responseBody, String resource) {
    // Extract error message from response body if available
    final String errorMessage = responseBody.isNotEmpty 
        ? 'Failed to fetch $resource: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}'
        : 'Failed to fetch $resource: HTTP $statusCode';
    
    switch (statusCode) {
      case 400:
        // Bad Request - Invalid request parameters
        return ServerFailure('Bad Request: $errorMessage');
      case 401:
        // Unauthorized - Authentication required
        return const AuthFailure('Unauthorized: Authentication required to access this resource');
      case 403:
        // Forbidden - Access denied
        return const AuthFailure('Forbidden: Access denied to this resource');
      case 404:
        // Not Found - Resource doesn't exist
        return ServerFailure('Not Found: The requested $resource was not found');
      case 429:
        // Too Many Requests - Rate limiting
        return ServerFailure('Too Many Requests: Rate limit exceeded. Please try again later');
      case 500:
        // Internal Server Error - Server-side error
        return ServerFailure('Internal Server Error: The server encountered an error processing your request');
      case 503:
        // Service Unavailable - Service temporarily unavailable
        return ServerFailure('Service Unavailable: The service is temporarily unavailable. Please try again later');
      default:
        // Unknown error code
        return ServerFailure('Unexpected error (HTTP $statusCode): $errorMessage');
    }
  }

  /// Disposes of the HTTP client and releases resources
  /// 
  /// This should be called when the service is no longer needed to properly
  /// clean up network connections.
  void dispose() {
    _client.close();
  }
}

