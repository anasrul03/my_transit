import 'dart:math' as math;
import '../../../domain/entities/vehicle_entity.dart';

/// Service for clustering nearby vehicle markers
/// 
/// This service groups vehicles that are close together to improve
/// map performance and readability when there are many vehicles in a small area.
class VehicleClusteringService {
  /// Cluster vehicles based on distance and zoom level
  /// 
  /// Groups vehicles that are within clusterDistance of each other.
  /// Returns a list of vehicle clusters, where each cluster contains
  /// one or more vehicles and a representative position.
  /// 
  /// [vehicles] - List of vehicles to cluster
  /// [zoomLevel] - Current map zoom level (determines clustering threshold)
  /// 
  /// Returns: List of vehicle clusters
  static List<VehicleCluster> clusterVehicles(
    List<VehicleEntity> vehicles,
    double zoomLevel,
  ) {
    // Don't cluster at high zoom levels (show all individual vehicles)
    // Cluster threshold: zoom < 12 = cluster, zoom >= 12 = no clustering
    if (zoomLevel >= 12.0) {
      // No clustering - return each vehicle as its own cluster
      return vehicles.map((VehicleEntity v) => VehicleCluster(
        vehicles: <VehicleEntity>[v],
        centerLatitude: v.latitude,
        centerLongitude: v.longitude,
      )).toList();
    }
    
    // Calculate clustering distance based on zoom level
    // Lower zoom = larger distance threshold (more aggressive clustering)
    final double clusterDistance = _calculateClusterDistance(zoomLevel);
    
    // List of final clusters
    final List<VehicleCluster> clusters = <VehicleCluster>[];
    
    // Set of vehicles already assigned to clusters
    final Set<String> clusteredVehicles = <String>{};
    
    // Iterate through each vehicle
    for (final VehicleEntity vehicle in vehicles) {
      // Skip if already in a cluster
      if (clusteredVehicles.contains(vehicle.id)) {
        continue;
      }
      
      // Start a new cluster with this vehicle
      final List<VehicleEntity> clusterMembers = <VehicleEntity>[vehicle];
      clusteredVehicles.add(vehicle.id);
      
      // Find nearby vehicles to add to this cluster
      for (final VehicleEntity otherVehicle in vehicles) {
        // Skip if already clustered or same vehicle
        if (clusteredVehicles.contains(otherVehicle.id)) {
          continue;
        }
        
        // Calculate distance between vehicles
        final double distance = _calculateDistance(
          vehicle.latitude,
          vehicle.longitude,
          otherVehicle.latitude,
          otherVehicle.longitude,
        );
        
        // If within cluster distance, add to cluster
        if (distance <= clusterDistance) {
          clusterMembers.add(otherVehicle);
          clusteredVehicles.add(otherVehicle.id);
        }
      }
      
      // Calculate cluster center (average position)
      final double centerLat = clusterMembers
          .map((VehicleEntity v) => v.latitude)
          .reduce((double a, double b) => a + b) / clusterMembers.length;
      final double centerLon = clusterMembers
          .map((VehicleEntity v) => v.longitude)
          .reduce((double a, double b) => a + b) / clusterMembers.length;
      
      // Create cluster
      clusters.add(VehicleCluster(
        vehicles: clusterMembers,
        centerLatitude: centerLat,
        centerLongitude: centerLon,
      ));
    }
    
    return clusters;
  }
  
  /// Calculate cluster distance threshold based on zoom level
  /// 
  /// Returns distance in kilometers for clustering threshold.
  /// Lower zoom = larger distance (more aggressive clustering).
  static double _calculateClusterDistance(double zoomLevel) {
    // Zoom 0-5: 5km clustering
    // Zoom 6-8: 2km clustering
    // Zoom 9-11: 0.5km clustering
    // Zoom 12+: No clustering
    if (zoomLevel < 6) {
      return 5.0; // 5km
    } else if (zoomLevel < 9) {
      return 2.0; // 2km
    } else if (zoomLevel < 12) {
      return 0.5; // 500m
    } else {
      return 0.0; // No clustering
    }
  }
  
  /// Calculate distance between two coordinates using Haversine formula
  /// 
  /// Returns distance in kilometers.
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371.0; // Earth radius in kilometers
    
    // Convert to radians
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double lat1Rad = _toRadians(lat1);
    final double lat2Rad = _toRadians(lat2);
    
    // Haversine formula
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}

/// Represents a cluster of vehicles
/// 
/// A cluster contains one or more vehicles that are geographically close.
/// When there's only one vehicle, it's displayed as an individual marker.
/// When there are multiple vehicles, it's displayed as a cluster marker
/// with a count indicator.
class VehicleCluster {
  /// List of vehicles in this cluster
  final List<VehicleEntity> vehicles;
  
  /// Center latitude of the cluster (average of all vehicle positions)
  final double centerLatitude;
  
  /// Center longitude of the cluster (average of all vehicle positions)
  final double centerLongitude;
  
  const VehicleCluster({
    required this.vehicles,
    required this.centerLatitude,
    required this.centerLongitude,
  });
  
  /// Whether this cluster contains multiple vehicles
  bool get isCluster => vehicles.length > 1;
  
  /// Number of vehicles in this cluster
  int get count => vehicles.length;
  
  /// Get the first vehicle (for single-vehicle clusters)
  VehicleEntity get vehicle => vehicles.first;
}

