import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../providers/map_filters_provider.dart';

/// Widget for selecting Prasarana service categories
/// 
/// This widget displays category selection options for Prasarana bus agencies.
/// It only appears when a Prasarana bus agency is selected and allows users
/// to choose which service category to view (e.g., rapid-bus-kl, rapid-bus-mrtfeeder).
class CategoryFilterWidget extends ConsumerWidget {
  /// Creates a CategoryFilterWidget
  const CategoryFilterWidget({super.key});

  /// Map of category codes to display names
  /// 
  /// Maps Prasarana category codes to user-friendly display names.
  static const Map<String, String> categoryDisplayNames = {
    ApiConstants.agencyRapidBusKl: 'Rapid Bus KL',
    ApiConstants.agencyRapidBusMrtfeeder: 'MRT Feeder',
    ApiConstants.agencyRapidBusKuantan: 'Rapid Bus Kuantan',
    ApiConstants.agencyRapidBusPenang: 'Rapid Bus Penang',
  };

  /// Gets display name for a category code
  /// 
  /// [categoryCode] - The category code to get display name for
  /// 
  /// Returns: Display name for the category, or the category code if not found
  static String getCategoryDisplayName(String? categoryCode) {
    if (categoryCode == null) return 'Default';
    return categoryDisplayNames[categoryCode] ?? categoryCode;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current agency and category selection
    final MapFiltersState filtersState = ref.watch(mapFiltersProvider);
    final String? selectedAgency = filtersState.selectedAgency;
    final String? selectedCategory = filtersState.selectedCategory;

    // Only show category filter for Prasarana bus agencies
    final bool isPrasaranaBus = selectedAgency != null &&
        (selectedAgency == ApiConstants.agencyRapidBusKl ||
            selectedAgency == ApiConstants.agencyRapidBusPenang ||
            selectedAgency == ApiConstants.agencyRapidBusKuantan ||
            selectedAgency == ApiConstants.agencyRapidBusMrtfeeder);

    // Don't show widget if not a Prasarana bus agency
    if (!isPrasaranaBus) {
      return const SizedBox.shrink();
    }

    // Get available categories for this agency
    final List<String> availableCategories =
        ApiConstants.getPrasaranaCategories(selectedAgency);

    // If no categories available, don't show widget
    if (availableCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.category,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Service Category',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Default option (use agency code as category)
              _CategoryChip(
                label: 'Default',
                isSelected: selectedCategory == null,
                onTap: () {
                  ref.read(mapFiltersProvider.notifier).clearCategory();
                },
              ),
              // Category options
              ...availableCategories.map((String categoryCode) {
                return _CategoryChip(
                  label: getCategoryDisplayName(categoryCode),
                  isSelected: selectedCategory == categoryCode,
                  onTap: () {
                    ref.read(mapFiltersProvider.notifier).setCategory(categoryCode);
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual category chip button
/// 
/// Displays a single category option as a chip that can be selected.
class _CategoryChip extends StatelessWidget {
  /// Label text for the chip
  final String label;
  
  /// Whether this chip is currently selected
  final bool isSelected;
  
  /// Callback when chip is tapped
  final VoidCallback onTap;

  /// Creates a _CategoryChip
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

