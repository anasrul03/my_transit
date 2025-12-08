import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/favorite_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_vehicles_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/gtfs_realtime_provider.dart';
import '../../widgets/map/vehicle_info_sheet.dart';

class FavouritesTabView extends ConsumerWidget {
  const FavouritesTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final favoritesState = ref.watch(favoriteVehiclesProvider);

    // Show message and Sign In CTA for guest users
    if (authState.isGuest || !authState.isAuthenticated) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Favourites are only available for logged-in users',
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Sign In CTA button for guest users
              // This encourages guests to create an account to access favourites
              SizedBox(
                height: 50, // Minimum 44pt height for better UX
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to login screen using GoRouter
                    context.go('/login');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading state while favorites are being loaded
    if (favoritesState.isLoading) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    // Show empty state when authenticated user has no favourites
    if (favoritesState.favorites.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    // Show favorites list when user has favourites
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Favourites',
                  style: AppTypography.heading2.copyWith(
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                // Show migration indicator if migrating
                if (favoritesState.isMigrating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
              ],
            ),
          ),
          // Favorites list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: favoritesState.favorites.length,
              itemBuilder: (context, index) {
                final favorite = favoritesState.favorites[index];
                return _FavoriteItem(
                  key: ValueKey(favorite.id), // Use key to ensure proper rebuild
                  favorite: favorite,
                  onRemove: () async {
                    // Remove favorite - provider will automatically refresh the list
                    await ref.read(favoriteVehiclesProvider.notifier).removeFavoriteById(favorite.id);
                  },
                  onTap: () {
                    // Find vehicle by ID and show vehicle info sheet
                    final realtimeState = ref.read(gtfsRealtimeProvider);
                    try {
                      final vehicle = realtimeState.vehicles.firstWhere(
                        (v) => v.id == favorite.vehicleId,
                      );
                      
                      // Navigate to map tab first
                      ref.read(navigationProvider.notifier).selectTab(TabType.map);
                      
                      // Show vehicle info sheet after a short delay to allow navigation
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            barrierColor: Colors.black.withOpacity(0.15),
                            isDismissible: true,
                            enableDrag: true,
                            useSafeArea: true,
                            showDragHandle: true,
                            builder: (BuildContext sheetContext) {
                              return VehicleInfoSheet(
                                vehicle: vehicle,
                                onDismissed: () {
                                  // Optionally handle dismissal
                                },
                              );
                            },
                          );
                        }
                      });
                    } catch (e) {
                      // Vehicle not found in current realtime data
                      // Show error message to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Vehicle "${favorite.displayName}" is not currently available on the map',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      
                      // Still navigate to map tab so user can explore
                      ref.read(navigationProvider.notifier).selectTab(TabType.map);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the empty state widget for authenticated users with no favourites
  /// 
  /// Displays an informative message with icon and optional CTA button
  /// to navigate to map/routes to add favourites.
  /// 
  /// [context] - Build context for navigation
  /// [ref] - WidgetRef for accessing providers
  /// 
  /// Returns: Widget displaying empty state message
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large icon with muted color
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            // Title text
            Text(
              'No favourites yet',
              style: AppTypography.body.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            // Subtitle with helpful guidance
            Text(
              'Add vehicles or routes to your favourites to see them here',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            // CTA button to navigate to map to add favourites
            SizedBox(
              height: 48, // Minimum 44pt for Apple HIG compliance
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to map tab to explore and add favourites
                  ref.read(navigationProvider.notifier).selectTab(TabType.map);
                },
                icon: const Icon(Icons.explore, size: 20),
                label: const Text('Explore Routes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying a single favorite item in the list
/// 
/// Shows favorite information with remove capability
class _FavoriteItem extends ConsumerWidget {
  /// The favorite entity to display
  final FavoriteEntity favorite;
  
  /// Callback when favorite is removed
  final Future<void> Function() onRemove;
  
  /// Callback when favorite item is tapped
  final VoidCallback onTap;

  const _FavoriteItem({
    super.key,
    required this.favorite,
    required this.onRemove,
    required this.onTap,
  });


  /// Gets the icon for the vehicle type
  /// 
  /// Returns: IconData representing the vehicle type
  IconData _getVehicleTypeIcon() {
    if (favorite.vehicleType == null) {
      return Icons.directions_bus;
    }
    
    final type = favorite.vehicleType!.toLowerCase();
    if (type.contains('train') || type.contains('rail') || type.contains('subway') || type.contains('tram')) {
      return Icons.train;
    }
    if (type.contains('ferry')) {
      return Icons.directions_boat;
    }
    return Icons.directions_bus;
  }

  /// Gets the emoji for the vehicle type
  /// 
  /// Returns: Emoji string representing the vehicle type
  String _getVehicleTypeEmoji() {
    if (favorite.vehicleType == null) {
      return '🚌';
    }
    
    final type = favorite.vehicleType!.toLowerCase();
    if (type.contains('train')) {
      return '🚆';
    }
    if (type.contains('subway')) {
      return '🚇';
    }
    if (type.contains('tram')) {
      return '🚊';
    }
    if (type.contains('ferry')) {
      return '⛴️';
    }
    return '🚌';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main row with icon, content, and action buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Leading icon with vehicle type emoji
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                    _getVehicleTypeEmoji(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display name
                      Text(
                        favorite.displayName,
                        style: AppTypography.body.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Vehicle type and route info
                      if (favorite.vehicleType != null) ...[
                        Row(
                          children: [
                            Icon(
                              _getVehicleTypeIcon(),
                              size: 14,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              favorite.vehicleType!,
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (favorite.routeId != null && favorite.routeId!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Route: ${favorite.routeId}',
                          style: AppTypography.caption.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Action button - Unfavorite (heart)
                IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 22,
                  ),
                  onPressed: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(
                          'Remove from Favorites',
                          style: TextStyle(
                            color: Theme.of(dialogContext).textTheme.titleLarge?.color,
                          ),
                        ),
                        content: Text(
                          'Remove "${favorite.displayName}" from your favorites?',
                          style: TextStyle(
                            color: Theme.of(dialogContext).textTheme.bodyMedium?.color,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              await onRemove();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Remove from favorites',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
