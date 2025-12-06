import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/services/mapbox_service.dart';
import '../../providers/connectivity_provider.dart';

class MapboxMapWidget extends ConsumerStatefulWidget {
  const MapboxMapWidget({super.key});

  @override
  ConsumerState<MapboxMapWidget> createState() => _MapboxMapWidgetState();
}

class _MapboxMapWidgetState extends ConsumerState<MapboxMapWidget> {
  MapboxMap? mapboxMap;
  bool _isDisposed = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isRetrying = false;
  bool _mapCreated = false;
  int _mapCreationCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Check connectivity first
    await ref.read(connectivityProvider.notifier).checkConnectivity();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    if (_isDisposed || _mapCreated) return;
    
    _mapCreated = true;
    _mapCreationCount++;
    this.mapboxMap = mapboxMap;
    debugPrint('✅ Mapbox map created successfully (count: $_mapCreationCount)');
    
    // Set initial camera position and hide loading indicator
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (_isDisposed || !mounted) return;
      
      try {
        await mapboxMap.setCamera(
          CameraOptions(
            center: Point(coordinates: Position(101.6869, 3.1390)), // KL coordinates
            zoom: 12.0,
            bearing: 0.0,
            pitch: 0.0,
          ),
        );
        debugPrint('✅ Camera position set successfully');
        
        if (mounted && !_hasError) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('❌ Error setting camera: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = e.toString();
          });
        }
      }
    });
  }
  
  void _onStyleLoadedListener(StyleLoadedEventData data) {
    if (!_mapCreated) {
      debugPrint('⚠️ Style loaded before map created - ignoring');
      return;
    }
    
    debugPrint('✅ Map style loaded successfully');
    if (mounted && _hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _isLoading = false;
      });
    }
  }
  
  void _onMapLoadErrorListener(MapLoadingErrorEventData data) {
    debugPrint('❌ Map load error: ${data.message}, type: ${data.type}');
    
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = data.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _retryConnection() async {
    setState(() {
      _isRetrying = true;
      _hasError = false;
      _errorMessage = null;
      _mapCreated = false; // Allow map to be recreated
    });

    // Force connectivity check
    await ref.read(connectivityProvider.notifier).checkConnectivity();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isRetrying = false;
        _isLoading = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only listen to connectivity on initial build
    final connectivityState = ref.watch(connectivityProvider);

    // Token not configured
    if (!MapboxService.isConfigured) {
      return _buildErrorState(
        icon: Icons.vpn_key_off,
        title: 'Mapbox Not Configured',
        message: 'Please provide ACCESS_TOKEN via --dart-define',
        action: null,
      );
    }

    // No internet connection (only show before map is created)
    if (!connectivityState.isConnected && !_isRetrying && !_mapCreated) {
      return _buildErrorState(
        icon: Icons.wifi_off,
        title: 'No Internet Connection',
        message: 'Please check your internet connection and try again',
        action: _buildRetryButton(),
      );
    }

    // Checking connectivity
    if ((connectivityState.isChecking || _isRetrying) && !_mapCreated) {
      return _buildLoadingState('Checking connection...');
    }

    // Once map is created, keep it stable - don't rebuild
    return Stack(
      children: [
        // Map Widget - stable key to prevent rebuilds
        MapWidget(
          key: const ValueKey("mapWidget_stable"),
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(101.6869, 3.1390)), // KL coordinates
            zoom: 12.0,
            bearing: 0.0,
            pitch: 0.0,
          ),
          styleUri: 'mapbox://styles/mapbox/streets-v12',
          textureView: true,
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoadedListener,
          onMapLoadErrorListener: _onMapLoadErrorListener,
        ),
        
        // Loading overlay
        if (_isLoading && !_hasError)
          _buildLoadingState('Loading map tiles...'),
        
        // Error overlay
        if (_hasError)
          _buildErrorOverlay(),
        
        // Connectivity indicator (top bar) - only show if map created
        if (_mapCreated)
          _buildConnectivityIndicator(connectivityState),
      ],
    );
  }

  Widget _buildLoadingState(String message) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This may take a few seconds',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required IconData icon,
    required String title,
    required String message,
    required Widget? action,
  }) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 80,
                color: Colors.white30,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: 32),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Map Loading Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'An error occurred while loading the map',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              _buildRetryButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: _isRetrying ? null : _retryConnection,
      icon: _isRetrying
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.refresh),
      label: Text(_isRetrying ? 'Retrying...' : 'Try Again'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildConnectivityIndicator(ConnectivityState state) {
    if (state.isConnected || _hasError) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.orange.withOpacity(0.9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Offline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    // MapWidget handles the MapboxMap disposal automatically
    // Only dispose if we're sure it hasn't been disposed already
    try {
      if (mapboxMap != null) {
        mapboxMap = null;
      }
    } catch (e) {
      debugPrint('Error disposing mapboxMap: $e');
    }
    super.dispose();
  }
}

