import 'dart:async';
import 'dart:isolate';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/shape_entity.dart';
import '../../domain/usecases/interpolate_vehicle_position.dart';

/// Isolate entry point for vehicle position interpolation
/// 
/// This function runs in a separate isolate to perform computationally
/// intensive vehicle position interpolation without blocking the main UI thread.
/// It receives messages containing vehicle, shape, and interpolation factor,
/// performs the interpolation, and sends the result back.
/// 
/// [sendPort] - The port used to send messages back to the main isolate
/// 
/// The function sets up a receive port to listen for interpolation requests
/// and processes them asynchronously.
void interpolationIsolateEntry(SendPort sendPort) async {
  // Create a receive port to listen for messages from the main isolate
  final ReceivePort receivePort = ReceivePort();
  // Send the receive port's send port back to the main isolate
  sendPort.send(receivePort.sendPort);

  // Listen for interpolation requests
  await for (final dynamic message in receivePort) {
    // Validate that the message is in the expected format
    if (message is Map<String, dynamic>) {
      // Extract vehicle, shape, and interpolation factor from the message
      final VehicleEntity vehicle = message['vehicle'] as VehicleEntity;
      final ShapeEntity shape = message['shape'] as ShapeEntity;
      final double factor = message['factor'] as double;

      // Create the use case and perform interpolation
      final InterpolateVehiclePositionUseCase useCase = InterpolateVehiclePositionUseCase();
      final VehicleEntity interpolated = useCase.interpolate(
        vehicle: vehicle,
        shape: shape,
        interpolationFactor: factor,
      );

      // Send the interpolated result back to the main isolate
      sendPort.send(interpolated);
    }
  }
}

/// Helper class to run vehicle position interpolation in a separate isolate
/// 
/// This class manages the isolate lifecycle and provides a convenient interface
/// for performing vehicle position interpolation off the main thread. Interpolation
/// can be computationally expensive, especially with large shape data, so running
/// it in an isolate prevents UI blocking.
/// 
/// The class handles isolate creation, message passing, and cleanup.
class InterpolationIsolate {
  /// The isolate instance running the interpolation logic
  Isolate? _isolate;
  
  /// Port for sending messages to the isolate
  SendPort? _sendPort;
  
  /// Port for receiving messages from the isolate
  ReceivePort? _receivePort;

  /// Initializes the isolate and sets up communication channels
  /// 
  /// This method spawns a new isolate running the interpolationIsolateEntry
  /// function and establishes the communication ports needed for message passing.
  /// 
  /// This should be called before attempting to interpolate, or it will be
  /// called automatically on the first interpolation request.
  Future<void> initialize() async {
    // Create a receive port to receive the isolate's send port
    final ReceivePort receivePort = ReceivePort();
    
    // Spawn the isolate with the entry point function
    _isolate = await Isolate.spawn(
      interpolationIsolateEntry,
      receivePort.sendPort,
    );

    // Wait for the isolate to send back its send port
    _sendPort = await receivePort.first as SendPort;
    
    // Create a new receive port for receiving interpolation results
    _receivePort = ReceivePort();
    
    // Send the receive port's send port to the isolate so it can send results back
    _sendPort!.send(_receivePort!.sendPort);
  }

  /// Interpolates a vehicle position along a shape route
  /// 
  /// This method sends an interpolation request to the isolate and waits for
  /// the result. If the isolate hasn't been initialized, it initializes it first.
  /// 
  /// [vehicle] - The vehicle entity to interpolate
  /// [shape] - The shape entity representing the route
  /// [factor] - The interpolation factor (0.0 to 1.0) indicating position along the route
  /// 
  /// Returns: Future<VehicleEntity> containing the interpolated vehicle position
  Future<VehicleEntity> interpolate({
    required VehicleEntity vehicle,
    required ShapeEntity shape,
    required double factor,
  }) async {
    // Initialize isolate if not already done
    if (_sendPort == null) {
      await initialize();
    }

    // Create a completer to wait for the interpolation result
    final Completer<VehicleEntity> completer = Completer<VehicleEntity>();
    
    // Listen for the interpolation result from the isolate
    _receivePort!.listen((dynamic message) {
      if (message is VehicleEntity) {
        // Complete the future with the interpolated result
        completer.complete(message);
      }
    });

    // Send the interpolation request to the isolate
    _sendPort!.send({
      'vehicle': vehicle,
      'shape': shape,
      'factor': factor,
    });

    // Return the future that will complete when interpolation is done
    return completer.future;
  }

  /// Disposes of the isolate and cleans up resources
  /// 
  /// This method kills the isolate, closes the receive port, and clears
  /// all references. It should be called when the InterpolationIsolate
  /// is no longer needed to prevent memory leaks.
  void dispose() {
    // Kill the isolate immediately to free resources
    _isolate?.kill(priority: Isolate.immediate);
    // Close the receive port to stop listening for messages
    _receivePort?.close();
    // Clear all references
    _isolate = null;
    _sendPort = null;
    _receivePort = null;
  }
}

