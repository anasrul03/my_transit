import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class SchedulesTabView extends ConsumerWidget {
  const SchedulesTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppTheme.darkBackground,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedules',
            style: AppTypography.heading2,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search bus/train name',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Schedule results will appear here',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

