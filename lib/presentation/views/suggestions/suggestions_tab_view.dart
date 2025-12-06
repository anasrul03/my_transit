import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SuggestionsTabView extends ConsumerWidget {
  const SuggestionsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Container(
      color: AppTheme.darkBackground,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions',
            style: AppTypography.heading2,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Your suggestion or feedback',
              hintText: 'Enter your route suggestion or UX feedback here...',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (authState.isGuest)
            const Text(
              'Note: Limited functionality for guest users',
              style: AppTypography.caption,
            ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement suggestion submission
            },
            child: const Text('Submit Suggestion'),
          ),
        ],
      ),
    );
  }
}

