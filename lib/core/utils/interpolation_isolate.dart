import 'dart:async';
import 'dart:isolate';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/shape_entity.dart';
import '../../domain/usecases/interpolate_vehicle_position.dart';

/// Isolate entry point for vehicle position interpolation
void interpolationIsolateEntry(SendPort sendPort) async {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  await for (final message in receivePort) {
    if (message is Map<String, dynamic>) {
      final vehicle = message['vehicle'] as VehicleEntity;
      final shape = message['shape'] as ShapeEntity;
      final factor = message['factor'] as double;

      final useCase = InterpolateVehiclePositionUseCase();
      final interpolated = useCase.interpolate(
        vehicle: vehicle,
        shape: shape,
        interpolationFactor: factor,
      );

      sendPort.send(interpolated);
    }
  }
}

/// Helper class to run interpolation in isolate
class InterpolationIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;

  Future<void> initialize() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      interpolationIsolateEntry,
      receivePort.sendPort,
    );

    _sendPort = await receivePort.first as SendPort;
    _receivePort = ReceivePort();
    _sendPort!.send(_receivePort!.sendPort);
  }

  Future<VehicleEntity> interpolate({
    required VehicleEntity vehicle,
    required ShapeEntity shape,
    required double factor,
  }) async {
    if (_sendPort == null) {
      await initialize();
    }

    final completer = Completer<VehicleEntity>();
    
    _receivePort!.listen((message) {
      if (message is VehicleEntity) {
        completer.complete(message);
      }
    });

    _sendPort!.send({
      'vehicle': vehicle,
      'shape': shape,
      'factor': factor,
    });

    return completer.future;
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _isolate = null;
    _sendPort = null;
    _receivePort = null;
  }
}

