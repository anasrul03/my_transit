import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../providers/map_filters_provider.dart';
import 'category_filter_widget.dart';

/// Floating action button widget for selecting transit agencies
/// 
/// This widget displays a floating action button that shows the currently
/// selected agency and opens a bottom sheet to select a different agency.
/// It integrates with the mapFiltersProvider to update the agency filter.
class OperatorSelectionButton extends ConsumerWidget {
  /// Creates an OperatorSelectionButton widget
  const OperatorSelectionButton({super.key});

  /// Map of agency codes to display names
  /// 
  /// This maps Malaysian transit agency codes to user-friendly display names.
  static const Map<String, String> agencyDisplayNames = {
    ApiConstants.agencyKtmb: 'KTMB',
    ApiConstants.agencyRapidRailKl: 'Rapid Rail KL',
    ApiConstants.agencyRapidBusKl: 'Rapid Bus KL',
    ApiConstants.agencyRapidBusPenang: 'Rapid Bus Penang',
    ApiConstants.agencyRapidBusKuantan: 'Rapid Bus Kuantan',
    ApiConstants.agencyRapidBusMrtfeeder: 'Rapid Bus MRT Feeder',
    ApiConstants.agencyBasKangar: 'BAS Kangar',
    ApiConstants.agencyBasAlorSetar: 'BAS Alor Setar',
    ApiConstants.agencyBasKotaBharu: 'BAS Kota Bharu',
    ApiConstants.agencyBasKualaTerengganu: 'BAS Kuala Terengganu',
    ApiConstants.agencyBasIpoh: 'BAS Ipoh',
    ApiConstants.agencyBasSerembanA: 'BAS Seremban A',
    ApiConstants.agencyBasSerembanB: 'BAS Seremban B',
    ApiConstants.agencyBasMelaka: 'BAS Melaka',
    ApiConstants.agencyBasJohor: 'BAS Johor',
    ApiConstants.agencyBasKuching: 'BAS Kuching',
  };

  /// Gets display name for an agency code
  /// 
  /// [agencyCode] - The agency code to get display name for
  /// 
  /// Returns: Display name for the agency, or the agency code if not found
  static String getAgencyDisplayName(String? agencyCode) {
    if (agencyCode == null) return 'All';
    return agencyDisplayNames[agencyCode] ?? agencyCode;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current agency selection from map filters
    final String? selectedAgency = ref.watch(
      mapFiltersProvider.select((state) => state.selectedAgency),
    );

    // Get the display text for the button
    // Show "All" if null, otherwise show agency display name
    final String displayText = getAgencyDisplayName(selectedAgency);

    return FloatingActionButton.extended(
      onPressed: () => _showOperatorSelectionSheet(context, ref),
      icon: const Icon(Icons.filter_list),
      label: Text(displayText),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      tooltip: 'Select transit agency',
    );
  }

  /// Groups agencies by their type for better organization
  /// 
  /// Returns a map where keys are group names and values are lists of agency codes
  static Map<String, List<String>> _getAgencyGroups() {
    return {
      'Rail Services': [
        ApiConstants.agencyKtmb,
        ApiConstants.agencyRapidRailKl,
      ],
      'Bus Services - Major Cities': [
        ApiConstants.agencyRapidBusKl,
        ApiConstants.agencyRapidBusPenang,
        ApiConstants.agencyRapidBusKuantan,
        ApiConstants.agencyRapidBusMrtfeeder,
      ],
      'Bus Services - Regional': [
        ApiConstants.agencyBasKangar,
        ApiConstants.agencyBasAlorSetar,
        ApiConstants.agencyBasKotaBharu,
        ApiConstants.agencyBasKualaTerengganu,
        ApiConstants.agencyBasIpoh,
        ApiConstants.agencyBasSerembanA,
        ApiConstants.agencyBasSerembanB,
        ApiConstants.agencyBasMelaka,
        ApiConstants.agencyBasJohor,
        ApiConstants.agencyBasKuching,
      ],
    };
  }

  /// Filters agencies based on search query
  /// 
  /// [searchQuery] - The search text to filter by
  /// 
  /// Returns: Map of filtered agency groups
  static Map<String, List<String>> _filterAgencies(String searchQuery) {
    if (searchQuery.isEmpty) {
      return _getAgencyGroups();
    }

    final Map<String, List<String>> allGroups = _getAgencyGroups();
    final Map<String, List<String>> filteredGroups = {};
    final String lowerQuery = searchQuery.toLowerCase();

    // Filter each group's agencies
    for (final MapEntry<String, List<String>> entry in allGroups.entries) {
      final List<String> filteredAgencies = entry.value
          .where((String agencyCode) {
            final String displayName = getAgencyDisplayName(agencyCode).toLowerCase();
            return displayName.contains(lowerQuery);
          })
          .toList();

      // Only include groups that have matching agencies
      if (filteredAgencies.isNotEmpty) {
        filteredGroups[entry.key] = filteredAgencies;
      }
    }

    return filteredGroups;
  }

  /// Builds an animated agency list tile
  /// 
  /// [context] - Build context
  /// [agencyCode] - The agency code
  /// [isSelected] - Whether this agency is currently selected
  /// [onTap] - Callback when tapped
  /// [animationDelay] - Delay for staggered animation effect
  Widget _buildAgencyTile(
    BuildContext context,
    String agencyCode,
    bool isSelected,
    VoidCallback onTap,
    int animationDelay,
  ) {
    final String displayName = getAgencyDisplayName(agencyCode);

    return TweenAnimationBuilder<double>(
      // Staggered fade-in animation
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (animationDelay * 50)),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: AnimatedScale(
            // Animate icon scale on selection
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 28,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          title: Text(
            displayName,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Builds a section header for agency groups
  /// 
  /// [context] - Build context
  /// [title] - Section title
  /// [count] - Number of agencies in this section
  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(width: 8),
          // Agency count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a bottom sheet with agency selection options
  /// 
  /// This method displays a modal bottom sheet that allows users to select
  /// a transit agency. The selection updates the mapFiltersProvider.
  /// Features include search, grouping, animations, and improved UX.
  /// 
  /// [context] - Build context for showing the bottom sheet
  /// [ref] - WidgetRef for accessing providers
  void _showOperatorSelectionSheet(BuildContext context, WidgetRef ref) {
    // Get the current selected agency
    final String? currentAgency = ref.read(mapFiltersProvider).selectedAgency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Search query state
            String searchQuery = '';

            // Get filtered agencies based on search
            final Map<String, List<String>> filteredGroups = _filterAgencies(searchQuery);

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle indicator
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header with title and close button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select Transit Agency',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            // Close button
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                              tooltip: 'Close',
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search field
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: TextField(
                          onChanged: (String value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search agencies...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      // Scrollable content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            // "All Agencies" option
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: currentAgency == null
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.12)
                                      : Colors.transparent,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: AnimatedScale(
                                    scale: currentAgency == null ? 1.1 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      currentAgency == null
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      size: 28,
                                      color: currentAgency == null
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                    ),
                                  ),
                                  title: Text(
                                    'All Agencies',
                                    style: TextStyle(
                                      fontWeight: currentAgency == null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: currentAgency == null
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    ),
                                  ),
                                  onTap: () {
                                    ref
                                        .read(mapFiltersProvider.notifier)
                                        .setAgency(null);
                                    Navigator.of(context).pop();
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            // Category filter (shown when Prasarana bus agency is selected)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: CategoryFilterWidget(),
                            ),

                            const SizedBox(height: 8),

                            // Show grouped agencies or "no results" message
                            if (filteredGroups.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No agencies found',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try a different search term',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.4),
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              // Display grouped agencies
                              ...filteredGroups.entries.map(
                                (MapEntry<String, List<String>> entry) {
                                  final String groupName = entry.key;
                                  final List<String> agencies = entry.value;
                                  int animationIndex = 0;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Section header with count
                                      _buildSectionHeader(
                                        context,
                                        groupName,
                                        agencies.length,
                                      ),

                                      // Agency tiles with staggered animation
                                      ...agencies.map((String agencyCode) {
                                        final bool isSelected =
                                            agencyCode == currentAgency;
                                        final int delay = animationIndex++;

                                        return _buildAgencyTile(
                                          context,
                                          agencyCode,
                                          isSelected,
                                          () {
                                            ref
                                                .read(mapFiltersProvider.notifier)
                                                .setAgency(agencyCode);
                                            Navigator.of(context).pop();
                                          },
                                          delay,
                                        );
                                      }).toList(),

                                      // Divider between groups
                                      if (entry.key !=
                                          filteredGroups.keys.last)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          child: Divider(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

