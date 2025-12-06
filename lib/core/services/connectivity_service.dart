import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Service to manage and monitor internet connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Timer? _connectivityTimer;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Initial check
    await checkConnectivity();
    
    // Start periodic checks every 5 seconds
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => checkConnectivity(),
    );
  }

  /// Check internet connectivity by attempting to connect to reliable hosts
  Future<bool> checkConnectivity() async {
    try {
      // Try multiple reliable hosts
      final results = await Future.wait([
        _checkHost('google.com', 443),
        _checkHost('cloudflare.com', 443),
        _checkHost('api.mapbox.com', 443),
      ]);

      // If any host is reachable, we have connectivity
      final hasConnection = results.any((result) => result);
      
      if (_isConnected != hasConnection) {
        _isConnected = hasConnection;
        _connectivityController.add(_isConnected);
        debugPrint('🌐 Connectivity changed: ${_isConnected ? "Online" : "Offline"}');
      }

      return _isConnected;
    } catch (e) {
      debugPrint('❌ Connectivity check error: $e');
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(false);
      }
      return false;
    }
  }

  /// Check if a specific host is reachable
  Future<bool> _checkHost(String host, int port) async {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Force a connectivity check
  Future<bool> forceCheck() async {
    return await checkConnectivity();
  }

  /// Dispose resources
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }
}

