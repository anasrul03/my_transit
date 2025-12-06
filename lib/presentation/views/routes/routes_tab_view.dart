import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class RoutesTabView extends ConsumerWidget {
  const RoutesTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppTheme.darkBackground,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Routes',
            style: AppTypography.heading2,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Start Location',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: const InputDecoration(
              labelText: 'End Location',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement route search
            },
            child: const Text('Search Routes'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Route results will appear here',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

