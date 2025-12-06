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

  /// Shows a bottom sheet with agency selection options
  /// 
  /// This method displays a modal bottom sheet that allows users to select
  /// a transit agency. The selection updates the mapFiltersProvider.
  /// 
  /// [context] - Build context for showing the bottom sheet
  /// [ref] - WidgetRef for accessing providers
  void _showOperatorSelectionSheet(BuildContext context, WidgetRef ref) {
    // Get the current selected agency
    final String? currentAgency = ref.read(mapFiltersProvider).selectedAgency;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Select Transit Agency',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // "All Agencies" option
                  ListTile(
                    leading: Icon(
                      currentAgency == null ? Icons.check_circle : Icons.circle_outlined,
                      color: currentAgency == null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    title: const Text('All Agencies'),
                    onTap: () {
                      // Set agency to null to show all agencies
                      ref.read(mapFiltersProvider.notifier).setAgency(null);
                      Navigator.of(bottomSheetContext).pop();
                    },
                    selected: currentAgency == null,
                    selectedTileColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                  ),
                  // Category filter (shown when Prasarana bus agency is selected)
                  const CategoryFilterWidget(),
                  const SizedBox(height: 8),
                  // Agency list
                  ...ApiConstants.availableAgencies.map((String agencyCode) {
                    // Determine if this agency is currently selected
                    final bool isSelected = agencyCode == currentAgency;
                    final String displayName = getAgencyDisplayName(agencyCode);

                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      title: Text(displayName),
                      onTap: () {
                        // Update the agency filter
                        ref.read(mapFiltersProvider.notifier).setAgency(agencyCode);
                        
                        // Close the bottom sheet
                        Navigator.of(bottomSheetContext).pop();
                      },
                      selected: isSelected,
                      selectedTileColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

