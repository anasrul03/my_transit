import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/debounce.dart';
import '../../../domain/entities/stop_entity.dart';
import '../../../domain/entities/schedule_entry_entity.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/gtfs_static_provider.dart';

class SchedulesTabView extends ConsumerStatefulWidget {
  const SchedulesTabView({super.key});

  @override
  ConsumerState<SchedulesTabView> createState() => _SchedulesTabViewState();
}

class _SchedulesTabViewState extends ConsumerState<SchedulesTabView> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ScheduleState scheduleState = ref.watch(scheduleProvider);
    final GtfsStaticState gtfsStaticState = ref.watch(gtfsStaticProvider);

    return Container(
      color: AppTheme.darkBackground,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Schedules',
            style: AppTypography.heading2,
          ),
          const SizedBox(height: AppSpacing.md),

          // GTFS static data loading indicator
          if (gtfsStaticState.isLoading)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Loading transit data...',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

          // Search field
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search stop name',
              hintText: 'Enter stop name or code',
              prefixIcon: Icon(Icons.search),
            ),
            enabled: gtfsStaticState.isLoaded && !gtfsStaticState.isLoading,
            onChanged: (String value) {
              // Debounce search to avoid excessive filtering
              _searchDebouncer(() {
                ref.read(scheduleProvider.notifier).searchStops(value);
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Error display
          if (scheduleState.error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      scheduleState.error!.toString(),
                      style: AppTypography.bodySmall.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Selected stop display
          if (scheduleState.selectedStop != null) ...[
            _buildSelectedStopHeader(scheduleState.selectedStop!),
            const SizedBox(height: AppSpacing.md),
          ],

          // Content area: either stop search results or schedule list
          Expanded(
            child: _buildContent(scheduleState),
          ),
        ],
      ),
    );
  }

  /// Builds the selected stop header widget
  /// 
  /// Displays the selected stop name and a clear button to deselect the stop.
  /// 
  /// [stop] - The selected stop entity
  /// 
  /// Returns: Widget displaying selected stop information
  Widget _buildSelectedStopHeader(StopEntity stop) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppTheme.primaryColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name ?? 'Unknown Stop',
                  style: AppTypography.heading3,
                ),
                if (stop.code != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Code: ${stop.code}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(scheduleProvider.notifier).clearSelection();
              _searchController.clear();
            },
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }

  /// Builds the main content area based on current state
  /// 
  /// Shows different content based on whether a stop is selected, loading,
  /// or showing search results.
  /// 
  /// [state] - The current schedule state
  /// 
  /// Returns: Widget displaying appropriate content for current state
  Widget _buildContent(ScheduleState state) {
    // Show loading indicator if loading schedule data
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    // If stop is selected, show schedule list
    if (state.selectedStop != null) {
      return _buildScheduleList(state.scheduleEntries);
    }

    // If search query exists, show matching stops
    if (state.searchQuery.isNotEmpty) {
      return _buildStopSearchResults(state.matchingStops);
    }

    // Default: show empty state
    return _buildEmptyState();
  }

  /// Builds the stop search results list
  /// 
  /// Displays a scrollable list of stops matching the search query.
  /// Each stop can be tapped to view its schedule.
  /// 
  /// [stops] - List of matching stop entities
  /// 
  /// Returns: Widget displaying list of matching stops
  Widget _buildStopSearchResults(List<StopEntity> stops) {
    if (stops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No stops found',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different search term',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: stops.length,
      itemBuilder: (BuildContext context, int index) {
        final StopEntity stop = stops[index];
        return _buildStopListItem(stop);
      },
    );
  }

  /// Builds a single stop list item
  /// 
  /// Displays stop information in a tappable card that selects the stop
  /// when tapped.
  /// 
  /// [stop] - The stop entity to display
  /// 
  /// Returns: Widget displaying stop information
  Widget _buildStopListItem(StopEntity stop) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const Icon(
          Icons.location_on,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          stop.name ?? 'Unknown Stop',
          style: AppTypography.body,
        ),
        subtitle: stop.code != null
            ? Text(
                'Code: ${stop.code}',
                style: AppTypography.bodySmall,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Select stop and load schedule
          ref.read(scheduleProvider.notifier).selectStop(stop);
        },
      ),
    );
  }

  /// Builds the schedule list for the selected stop
  /// 
  /// Displays a chronological list of all schedule entries (arrival/departure times)
  /// for the selected stop. Each entry shows time, route, and destination.
  /// 
  /// [entries] - List of schedule entry entities sorted chronologically
  /// 
  /// Returns: Widget displaying schedule list
  Widget _buildScheduleList(List<ScheduleEntryEntity> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No schedule available',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This stop has no scheduled trips',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    // Group entries by time period for better readability
    final Map<String, List<ScheduleEntryEntity>> groupedEntries =
        _groupEntriesByPeriod(entries);

    return ListView.builder(
      itemCount: groupedEntries.length,
      itemBuilder: (BuildContext context, int index) {
        final String period = groupedEntries.keys.elementAt(index);
        final List<ScheduleEntryEntity> periodEntries =
            groupedEntries[period]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              child: Text(
                period,
                style: AppTypography.heading3,
              ),
            ),
            // Schedule entries for this period
            ...periodEntries.map((ScheduleEntryEntity entry) =>
                _buildScheduleEntryItem(entry)),
          ],
        );
      },
    );
  }

  /// Groups schedule entries by time period (Morning, Afternoon, Evening, Night)
  /// 
  /// This helps organize the schedule display for better readability.
  /// 
  /// [entries] - List of schedule entries to group
  /// 
  /// Returns: Map of period names to lists of entries in that period
  Map<String, List<ScheduleEntryEntity>> _groupEntriesByPeriod(
      List<ScheduleEntryEntity> entries) {
    final Map<String, List<ScheduleEntryEntity>> grouped = <String, List<ScheduleEntryEntity>>{};

    for (final ScheduleEntryEntity entry in entries) {
      final String? timeString = entry.getDisplayTime();
      if (timeString == null) continue;

      // Extract hour from time string (HH:MM format)
      final int? hour = int.tryParse(timeString.split(':').first);
      if (hour == null) continue;

      // Determine period based on hour
      String period;
      if (hour >= 5 && hour < 12) {
        period = 'Morning (5:00 - 11:59)';
      } else if (hour >= 12 && hour < 17) {
        period = 'Afternoon (12:00 - 16:59)';
      } else if (hour >= 17 && hour < 22) {
        period = 'Evening (17:00 - 21:59)';
      } else {
        period = 'Night (22:00 - 4:59)';
      }

      // Add entry to appropriate period group
      grouped.putIfAbsent(period, () => <ScheduleEntryEntity>[]).add(entry);
    }

    // Sort periods in chronological order
    final List<String> sortedPeriods = grouped.keys.toList()
      ..sort((String a, String b) {
        // Extract start hour from period name for sorting
        final int hourA = int.tryParse(a.split('(')[1].split(':')[0]) ?? 0;
        final int hourB = int.tryParse(b.split('(')[1].split(':')[0]) ?? 0;
        return hourA.compareTo(hourB);
      });

    // Return map with sorted periods
    final Map<String, List<ScheduleEntryEntity>> sortedGrouped =
        <String, List<ScheduleEntryEntity>>{};
    for (final String period in sortedPeriods) {
      sortedGrouped[period] = grouped[period]!;
    }

    return sortedGrouped;
  }

  /// Builds a single schedule entry item
  /// 
  /// Displays time, route name, and destination for a schedule entry.
  /// 
  /// [entry] - The schedule entry entity to display
  /// 
  /// Returns: Widget displaying schedule entry information
  Widget _buildScheduleEntryItem(ScheduleEntryEntity entry) {
    final String? displayTime = entry.getDisplayTime();
    final String routeName = entry.getRouteDisplayName();
    final String? headsign = entry.getTripHeadsign();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            displayTime ?? '--:--',
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        title: Text(
          routeName,
          style: AppTypography.body,
        ),
        subtitle: headsign != null
            ? Text(
                headsign,
                style: AppTypography.bodySmall,
              )
            : null,
        trailing: const Icon(Icons.directions_transit),
      ),
    );
  }

  /// Builds the empty state widget
  /// 
  /// Displays a message prompting the user to search for a stop.
  /// 
  /// Returns: Widget displaying empty state message
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Search for a stop',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter a stop name or code above to view schedules',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

