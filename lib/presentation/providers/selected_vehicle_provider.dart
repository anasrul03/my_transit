import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vehicle_entity.dart';

final selectedVehicleProvider =
    StateProvider<VehicleEntity?>((ref) => null);

