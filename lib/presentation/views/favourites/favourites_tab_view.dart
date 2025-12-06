import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class FavouritesTabView extends ConsumerWidget {
  const FavouritesTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Hide for guest users
    if (authState.isGuest || !authState.isAuthenticated) {
      return Container(
        color: AppTheme.darkBackground,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_border,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                'Favourites are only available for logged-in users',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.darkBackground,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Favourites',
            style: AppTypography.heading2,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Your favourite vehicles and routes will appear here',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

