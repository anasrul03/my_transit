import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/connectivity_service.dart';

/// Connectivity state
class ConnectivityState {
  final bool isConnected;
  final bool isChecking;
  final DateTime? lastChecked;

  const ConnectivityState({
    this.isConnected = false,
    this.isChecking = false,
    this.lastChecked,
  });

  ConnectivityState copyWith({
    bool? isConnected,
    bool? isChecking,
    DateTime? lastChecked,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      isChecking: isChecking ?? this.isChecking,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

/// Connectivity provider
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ConnectivityService _connectivityService = ConnectivityService();

  ConnectivityNotifier() : super(const ConnectivityState()) {
    _init();
  }

  Future<void> _init() async {
    // Initialize connectivity service
    await _connectivityService.initialize();
    
    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((isConnected) {
      state = state.copyWith(
        isConnected: isConnected,
        isChecking: false,
        lastChecked: DateTime.now(),
      );
    });

    // Initial check
    await checkConnectivity();
  }

  Future<void> checkConnectivity() async {
    state = state.copyWith(isChecking: true);
    
    final isConnected = await _connectivityService.forceCheck();
    
    state = state.copyWith(
      isConnected: isConnected,
      isChecking: false,
      lastChecked: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
}

