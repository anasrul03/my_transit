import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/connectivity_service.dart';

/// State class representing the current connectivity status
/// 
/// This state tracks whether the device has an active internet connection,
/// whether a connectivity check is currently in progress, and when the
/// last connectivity check was performed.
class ConnectivityState {
  /// Whether the device currently has an active internet connection
  final bool isConnected;
  
  /// Whether a connectivity check is currently in progress
  final bool isChecking;
  
  /// Timestamp of the last connectivity check, or null if never checked
  final DateTime? lastChecked;

  /// Creates a ConnectivityState with the specified values
  /// 
  /// [isConnected] - Whether connected. Defaults to false.
  /// [isChecking] - Whether checking. Defaults to false.
  /// [lastChecked] - Optional timestamp of last check
  const ConnectivityState({
    this.isConnected = false,
    this.isChecking = false,
    this.lastChecked,
  });

  /// Creates a copy of this state with the given fields replaced with new values
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

/// Provider for managing connectivity state
/// 
/// This provider monitors internet connectivity and provides real-time updates
/// when connectivity status changes. It uses the ConnectivityService to check
/// connectivity and listen for changes.
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

/// Notifier class for managing ConnectivityState
/// 
/// This notifier initializes the connectivity service, listens for connectivity
/// changes, and provides methods to manually check connectivity status.
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  /// The connectivity service instance used for checking connectivity
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Initializes the notifier and sets up connectivity monitoring
  ConnectivityNotifier() : super(const ConnectivityState()) {
    _init();
  }

  /// Initializes the connectivity service and sets up listeners
  /// 
  /// This method initializes the connectivity service, sets up a listener
  /// for connectivity changes, and performs an initial connectivity check.
  Future<void> _init() async {
    // Initialize the connectivity service to start monitoring
    await _connectivityService.initialize();
    
    // Listen to connectivity changes from the service
    // When connectivity changes, update the state immediately
    _connectivityService.connectivityStream.listen((bool isConnected) {
      state = state.copyWith(
        isConnected: isConnected,
        isChecking: false,
        lastChecked: DateTime.now(),
      );
    });

    // Perform an initial connectivity check to get current status
    await checkConnectivity();
  }

  /// Manually checks the current connectivity status
  /// 
  /// This method forces a connectivity check and updates the state with
  /// the result. It sets isChecking to true during the check, then updates
  /// with the result when complete.
  Future<void> checkConnectivity() async {
    // Set checking state to show loading indicator
    state = state.copyWith(isChecking: true);
    
    // Force a connectivity check
    final bool isConnected = await _connectivityService.forceCheck();
    
    // Update state with the result
    state = state.copyWith(
      isConnected: isConnected,
      isChecking: false,
      lastChecked: DateTime.now(),
    );
  }

  @override
  void dispose() {
    // Clean up the connectivity service when the notifier is disposed
    _connectivityService.dispose();
    super.dispose();
  }
}

