import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/failures.dart';
import '../../core/services/supabase_service.dart';
import '../../domain/entities/favorite_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../domain/repositories/auth_repository.dart'; // For Result type
import '../models/favorite_model.dart';

/// Implementation of FavoriteRepository using Supabase
/// 
/// This repository handles all CRUD operations for user favorites stored in Supabase.
/// All operations require an authenticated user and automatically filter by the current user's ID.
class FavoriteRepositoryImpl implements FavoriteRepository {
  /// Creates a FavoriteRepositoryImpl instance
  FavoriteRepositoryImpl();

  /// Gets the current authenticated user's ID
  /// 
  /// Returns: User ID if authenticated, null otherwise
  /// 
  /// Throws: Exception if Supabase is not initialized
  String? _getCurrentUserId() {
    final user = SupabaseService.auth.currentUser;
    return user?.id;
  }

  /// Checks if the current user is authenticated
  /// 
  /// Returns: true if authenticated, false otherwise
  bool _isAuthenticated() {
    return _getCurrentUserId() != null;
  }

  @override
  Future<Result<List<FavoriteEntity>>> getFavorites() async {
    // Check if user is authenticated
    if (!_isAuthenticated()) {
      return Result.failure(
        const AuthFailure('Please sign in to view favorites'),
      );
    }

    try {
      final userId = _getCurrentUserId()!;
      
      // Query favorites table filtered by user_id, ordered by created_at descending
      final response = await SupabaseService.client
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Convert response to list of FavoriteModel, then to entities
      final List<FavoriteEntity> favorites = (response as List)
          .map<FavoriteEntity>((json) => FavoriteModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();

      return Result.success(favorites);
    } on AuthException catch (e) {
      // Handle authentication errors (e.g., expired token)
      return Result.failure(
        AuthFailure('Authentication error: ${e.message}'),
      );
    } on PostgrestException catch (e) {
      // Handle database errors
      return Result.failure(
        ServerFailure('Failed to load favorites: ${e.message}'),
      );
    } catch (e) {
      // Handle network errors and other exceptions
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('network') || 
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout')) {
        return Result.failure(
          NetworkFailure('Network error: Please check your internet connection'),
        );
      }
      
      return Result.failure(
        ServerFailure('Failed to load favorites: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<FavoriteEntity>> addFavorite({
    required String vehicleId,
    String? routeId,
    String? vehicleType,
    required String displayName,
  }) async {
    // Check if user is authenticated
    if (!_isAuthenticated()) {
      return Result.failure(
        const AuthFailure('Please sign in to add favorites'),
      );
    }

    try {
      final userId = _getCurrentUserId()!;
      
      // Check if favorite already exists for this vehicle
      final existingResult = await getFavoriteByVehicleId(vehicleId);
      if (existingResult.isSuccess && existingResult.data != null) {
        return Result.failure(
          const ServerFailure('This vehicle is already in your favorites'),
        );
      }

      // Insert new favorite into Supabase
      final response = await SupabaseService.client
          .from('favorites')
          .insert({
            'user_id': userId,
            'vehicle_id': vehicleId,
            'route_id': routeId,
            'vehicle_type': vehicleType,
            'display_name': displayName,
          })
          .select()
          .single();

      // Convert response to FavoriteEntity
      final favorite = FavoriteModel.fromJson(response as Map<String, dynamic>);
      return Result.success(favorite.toEntity());
    } on AuthException catch (e) {
      // Handle authentication errors
      return Result.failure(
        AuthFailure('Authentication error: ${e.message}'),
      );
    } on PostgrestException catch (e) {
      // Handle database errors (e.g., unique constraint violation)
      if (e.code == '23505') {
        // Unique constraint violation - favorite already exists
        return Result.failure(
          const ServerFailure('This vehicle is already in your favorites'),
        );
      }
      return Result.failure(
        ServerFailure('Failed to add favorite: ${e.message}'),
      );
    } catch (e) {
      // Handle network errors and other exceptions
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('network') || 
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout')) {
        return Result.failure(
          NetworkFailure('Network error: Please check your internet connection'),
        );
      }
      
      return Result.failure(
        ServerFailure('Failed to add favorite: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> removeFavorite(String favoriteId) async {
    // Check if user is authenticated
    if (!_isAuthenticated()) {
      return Result.failure(
        const AuthFailure('Please sign in to remove favorites'),
      );
    }

    try {
      final userId = _getCurrentUserId()!;
      
      // Delete favorite, ensuring it belongs to the current user
      final response = await SupabaseService.client
          .from('favorites')
          .delete()
          .eq('id', favoriteId)
          .eq('user_id', userId);

      // Check if any rows were deleted (favorite existed and belonged to user)
      if (response.isEmpty) {
        return Result.failure(
          const ServerFailure('Favorite not found or you do not have permission to delete it'),
        );
      }

      return const Result.success(null);
    } on AuthException catch (e) {
      // Handle authentication errors
      return Result.failure(
        AuthFailure('Authentication error: ${e.message}'),
      );
    } on PostgrestException catch (e) {
      // Handle database errors
      return Result.failure(
        ServerFailure('Failed to remove favorite: ${e.message}'),
      );
    } catch (e) {
      // Handle network errors and other exceptions
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('network') || 
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout')) {
        return Result.failure(
          NetworkFailure('Network error: Please check your internet connection'),
        );
      }
      
      return Result.failure(
        ServerFailure('Failed to remove favorite: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<FavoriteEntity>> updateFavorite({
    required String favoriteId,
    required String displayName,
  }) async {
    // Check if user is authenticated
    if (!_isAuthenticated()) {
      return Result.failure(
        const AuthFailure('Please sign in to update favorites'),
      );
    }

    try {
      final userId = _getCurrentUserId()!;
      
      // Update favorite, ensuring it belongs to the current user
      final response = await SupabaseService.client
          .from('favorites')
          .update({'display_name': displayName})
          .eq('id', favoriteId)
          .eq('user_id', userId)
          .select()
          .single();

      // Convert response to FavoriteEntity
      final favorite = FavoriteModel.fromJson(response as Map<String, dynamic>);
      return Result.success(favorite.toEntity());
    } on PostgrestException catch (e) {
      // Handle database errors (e.g., favorite not found)
      if (e.code == 'PGRST116') {
        // No rows returned - favorite not found or doesn't belong to user
        return Result.failure(
          const ServerFailure('Favorite not found or you do not have permission to update it'),
        );
      }
      return Result.failure(
        ServerFailure('Failed to update favorite: ${e.message}'),
      );
    } on AuthException catch (e) {
      // Handle authentication errors
      return Result.failure(
        AuthFailure('Authentication error: ${e.message}'),
      );
    } catch (e) {
      // Handle network errors and other exceptions
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('network') || 
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout')) {
        return Result.failure(
          NetworkFailure('Network error: Please check your internet connection'),
        );
      }
      
      return Result.failure(
        ServerFailure('Failed to update favorite: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<bool>> isFavorite(String vehicleId) async {
    // Check if user is authenticated
    if (!_isAuthenticated()) {
      return Result.failure(
        const AuthFailure('Please sign in to check favorites'),
      );
    }

    try {
      final userId = _getCurrentUserId()!;
      
      // Query for favorite with matching vehicle_id and user_id
      final response = await SupabaseService.client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('vehicle_id', vehicleId)
          .limit(1);

      // If response has any items, vehicle is favorited
      final isFavorited = response.isNotEmpty;
      return Result.success(isFavorited);
    } on AuthException catch (e) {
      // Handle authentication errors
      return Result.failure(
        AuthFailure('Authentication error: ${e.message}'),
      );
    } on PostgrestException catch (e) {
      // Handle database errors
      return Result.failure(
        ServerFailure('Failed to check favorite status: ${e.message}'),
      );
    } catch (e) {
      // Handle network errors and other exceptions
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('network') || 
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout')) {
        return Result.failure(
          NetworkFailure('Network error: Please check your internet connection'),
        );
      }
      
      return Result.failure(
        ServerFailure('Failed to check favorite status: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<FavoriteEntity?>> getFavoriteByVehicleId(String vehicleId) async {
    // Check if user is authenticated
    if (!_isAuthenticated()) {
      return Result.failure(
        const AuthFailure('Please sign in to get favorite'),
      );
    }

    try {
      final userId = _getCurrentUserId()!;
      
      // Query for favorite with matching vehicle_id and user_id
      final response = await SupabaseService.client
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('vehicle_id', vehicleId)
          .limit(1)
          .maybeSingle();

      // If no favorite found, return null
      if (response == null) {
        return const Result.success(null);
      }

      // Convert response to FavoriteEntity
      final favorite = FavoriteModel.fromJson(response as Map<String, dynamic>);
      return Result.success(favorite.toEntity());
    } on AuthException catch (e) {
      // Handle authentication errors
      return Result.failure(
        AuthFailure('Authentication error: ${e.message}'),
      );
    } on PostgrestException catch (e) {
      // Handle database errors
      return Result.failure(
        ServerFailure('Failed to get favorite: ${e.message}'),
      );
    } catch (e) {
      // Handle network errors and other exceptions
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('network') || 
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout')) {
        return Result.failure(
          NetworkFailure('Network error: Please check your internet connection'),
        );
      }
      
      return Result.failure(
        ServerFailure('Failed to get favorite: ${e.toString()}'),
      );
    }
  }
}

