import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/debounce.dart';
import '../../../core/errors/failures.dart';
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
  
  // Cache for grouped schedule entries to avoid recalculating on every build
  Map<String, List<ScheduleEntryEntity>>? _cachedGroupedEntries;
  List<ScheduleEntryEntity>? _cachedEntriesList;
  
  // Cache for period order to avoid recalculating
  List<String>? _cachedPeriodOrder;
  
  // Track last selected stop ID to detect stop changes and reset cache
  String? _lastSelectedStopId;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    // Reset cache when widget is disposed
    _cachedGroupedEntries = null;
    _cachedEntriesList = null;
    _cachedPeriodOrder = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use selective provider watching to minimize rebuilds
    // Only watch specific properties that affect this widget
    final bool isLoading = ref.watch(scheduleProvider.select((ScheduleState s) => s.isLoading));
    final StopEntity? selectedStop = ref.watch(scheduleProvider.select((ScheduleState s) => s.selectedStop));
    final String searchQuery = ref.watch(scheduleProvider.select((ScheduleState s) => s.searchQuery));
    final List<StopEntity> matchingStops = ref.watch(scheduleProvider.select((ScheduleState s) => s.matchingStops));
    final List<ScheduleEntryEntity> scheduleEntries = ref.watch(scheduleProvider.select((ScheduleState s) => s.scheduleEntries));
    final Failure? error = ref.watch(scheduleProvider.select((ScheduleState s) => s.error));
    
    // Watch GTFS static state selectively
    final bool gtfsIsLoading = ref.watch(gtfsStaticProvider.select((GtfsStaticState s) => s.isLoading));
    final bool gtfsIsLoaded = ref.watch(gtfsStaticProvider.select((GtfsStaticState s) => s.isLoaded));
    final List<StopEntity> allStops = ref.watch(gtfsStaticProvider.select((GtfsStaticState s) => s.stops));

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Schedules',
            style: AppTypography.heading2.copyWith(
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // GTFS static data loading indicator
          if (gtfsIsLoading)
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
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
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
            enabled: gtfsIsLoaded && !gtfsIsLoading,
            onChanged: (String value) {
              // Debounce search to avoid excessive filtering
              _searchDebouncer(() {
                ref.read(scheduleProvider.notifier).searchStops(value);
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Error display
          if (error != null)
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
                      error.toString(),
                      style: AppTypography.bodySmall.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Selected stop display
          if (selectedStop != null) ...[
            _buildSelectedStopHeader(selectedStop),
            const SizedBox(height: AppSpacing.md),
          ],

          // Content area: either stop search results or schedule list
          Expanded(
            child: _buildContent(
              isLoading: isLoading,
              selectedStop: selectedStop,
              searchQuery: searchQuery,
              matchingStops: matchingStops,
              scheduleEntries: scheduleEntries,
              gtfsIsLoaded: gtfsIsLoaded,
              allStops: allStops,
            ),
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
        color: Theme.of(context).cardColor,
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
                  style: AppTypography.heading3.copyWith(
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                ),
                if (stop.code != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Code: ${stop.code}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Reset all schedule flow state when user taps X to return to initial state
              // This will show all stops list again
              
              // Clear the search text field
              _searchController.clear();
              
              // Reset local cache with setState to trigger rebuild
              setState(() {
                _cachedGroupedEntries = null;
                _cachedEntriesList = null;
                _cachedPeriodOrder = null;
                _lastSelectedStopId = null;
              });
              
              // Reset the entire schedule state to initial (empty search, no selection)
              ref.read(scheduleProvider.notifier).resetToInitialState();
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
  /// or showing search results. When no search query exists, shows all stops.
  /// 
  /// [isLoading] - Whether schedule data is currently loading
  /// [selectedStop] - The currently selected stop, if any
  /// [searchQuery] - The current search query string
  /// [matchingStops] - List of stops matching the search query
  /// [scheduleEntries] - List of schedule entries for the selected stop
  /// [gtfsIsLoaded] - Whether GTFS static data is loaded
  /// [allStops] - All available stops from GTFS static data
  /// 
  /// Returns: Widget displaying appropriate content for current state
  Widget _buildContent({
    required bool isLoading,
    required StopEntity? selectedStop,
    required String searchQuery,
    required List<StopEntity> matchingStops,
    required List<ScheduleEntryEntity> scheduleEntries,
    required bool gtfsIsLoaded,
    required List<StopEntity> allStops,
  }) {
    // Show loading indicator if loading schedule data
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    // If stop is selected, show schedule list
    if (selectedStop != null) {
      return _buildScheduleList(scheduleEntries);
    }

    // If search query exists, show matching stops
    if (searchQuery.isNotEmpty) {
      return _buildStopSearchResults(matchingStops);
    }

    // Default: show all stops if GTFS data is loaded
    if (gtfsIsLoaded && allStops.isNotEmpty) {
      return _buildStopSearchResults(allStops);
    }

    // Show empty state only if GTFS data is not loaded or no stops available
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
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No stops found',
              style: AppTypography.body.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different search term',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      // Performance optimizations for ListView
      cacheExtent: 500, // Cache 500 pixels worth of items for smoother scrolling
      addAutomaticKeepAlives: false, // Items don't need to maintain state
      addRepaintBoundaries: true, // Isolate repaints to individual items
      itemCount: stops.length,
      itemBuilder: (BuildContext context, int index) {
        final StopEntity stop = stops[index];
        return StopListItem(
          key: ValueKey<String>(stop.id),
          stop: stop,
          onTap: () {
            // Select stop and load schedule
            ref.read(scheduleProvider.notifier).selectStop(stop);
          },
        );
      },
    );
  }


  /// Builds the schedule list for the selected stop
  /// 
  /// Displays a chronological list of all schedule entries (arrival/departure times)
  /// for the selected stop. Each entry shows time, route, and destination.
  /// Uses cached grouping to avoid recalculating on every build.
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
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No schedule available',
              style: AppTypography.body.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This stop has no scheduled trips',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    // Reset cache if selected stop changed or entries list changed
    // Check if entries list has changed by comparing identity and length
    final StopEntity? currentSelectedStop = ref.read(scheduleProvider.select((ScheduleState s) => s.selectedStop));
    final String? currentStopId = currentSelectedStop?.id;
    final bool stopChanged = _lastSelectedStopId != currentStopId;
    
    if (stopChanged) {
      // Reset cache when stop changes (including when cleared to null)
      _cachedGroupedEntries = null;
      _cachedEntriesList = null;
      _cachedPeriodOrder = null;
      _lastSelectedStopId = currentStopId;
    }
    
    // Use cached grouped entries if entries haven't changed
    // Check if entries list has changed by comparing identity
    if (_cachedGroupedEntries == null || 
        _cachedEntriesList != entries ||
        _cachedEntriesList?.length != entries.length) {
      // Recalculate grouped entries only when entries change
      _cachedEntriesList = entries;
      _cachedGroupedEntries = _groupEntriesByPeriod(entries);
      _cachedPeriodOrder = _cachedGroupedEntries!.keys.toList()
        ..sort((String a, String b) {
          // Extract start hour from period name for sorting
          final int hourA = int.tryParse(a.split('(')[1].split(':')[0]) ?? 0;
          final int hourB = int.tryParse(b.split('(')[1].split(':')[0]) ?? 0;
          return hourA.compareTo(hourB);
        });
    }

    final Map<String, List<ScheduleEntryEntity>> groupedEntries = _cachedGroupedEntries!;
    final List<String> periodOrder = _cachedPeriodOrder!;

    return ListView.builder(
      // Performance optimizations for ListView
      cacheExtent: 500, // Cache 500 pixels worth of items for smoother scrolling
      addAutomaticKeepAlives: false, // Items don't need to maintain state
      addRepaintBoundaries: true, // Isolate repaints to individual items
      itemCount: periodOrder.length,
      itemBuilder: (BuildContext context, int index) {
        final String period = periodOrder[index];
        final List<ScheduleEntryEntity> periodEntries = groupedEntries[period]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          key: ValueKey<String>('period_$period'),
          children: [
            // Period header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              child: Text(
                period,
                style: AppTypography.heading3.copyWith(
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
              ),
            ),
            // Schedule entries for this period
            ...periodEntries.map((ScheduleEntryEntity entry) {
              // Create unique key from trip ID, stop ID, and stop sequence
              final String entryKey = '${entry.trip.id}_${entry.stopTime.stopId}_${entry.stopTime.stopSequence}';
              return ScheduleEntryItem(
                key: ValueKey<String>(entryKey),
                entry: entry,
              );
            }),
          ],
        );
      },
    );
  }

  /// Groups schedule entries by time period (Morning, Afternoon, Evening, Night)
  /// 
  /// This helps organize the schedule display for better readability.
  /// Optimized to parse time strings only once per entry.
  /// 
  /// [entries] - List of schedule entries to group
  /// 
  /// Returns: Map of period names to lists of entries in that period
  Map<String, List<ScheduleEntryEntity>> _groupEntriesByPeriod(
      List<ScheduleEntryEntity> entries) {
    final Map<String, List<ScheduleEntryEntity>> grouped = <String, List<ScheduleEntryEntity>>{};

    // Pre-define period constants to avoid string creation on every iteration
    const String morningPeriod = 'Morning (5:00 - 11:59)';
    const String afternoonPeriod = 'Afternoon (12:00 - 16:59)';
    const String eveningPeriod = 'Evening (17:00 - 21:59)';
    const String nightPeriod = 'Night (22:00 - 4:59)';

    for (final ScheduleEntryEntity entry in entries) {
      // Get time string once and cache it
      final String? timeString = entry.getDisplayTime();
      if (timeString == null) continue;

      // Extract hour from time string (HH:MM format) - parse only once
      final List<String> timeParts = timeString.split(':');
      if (timeParts.isEmpty) continue;
      
      final int? hour = int.tryParse(timeParts[0]);
      if (hour == null) continue;

      // Determine period based on hour - use pre-defined constants
      final String period;
      if (hour >= 5 && hour < 12) {
        period = morningPeriod;
      } else if (hour >= 12 && hour < 17) {
        period = afternoonPeriod;
      } else if (hour >= 17 && hour < 22) {
        period = eveningPeriod;
      } else {
        period = nightPeriod;
      }

      // Add entry to appropriate period group
      grouped.putIfAbsent(period, () => <ScheduleEntryEntity>[]).add(entry);
    }

    return grouped;
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
            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Search for a stop',
            style: AppTypography.body.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter a stop name or code above to view schedules',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Extracted widget for stop list items to improve performance
/// 
/// This widget is extracted to allow Flutter to better optimize rebuilds.
/// It uses const constructors where possible and caches computed values.
class StopListItem extends StatelessWidget {
  /// The stop entity to display
  final StopEntity stop;
  
  /// Callback when the stop is tapped
  final VoidCallback onTap;

  const StopListItem({
    super.key,
    required this.stop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Cache computed values to avoid recalculating on every build
    final String stopName = stop.name ?? 'Unknown Stop';
    final String? stopCode = stop.code;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const Icon(
          Icons.location_on,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          stopName,
          style: AppTypography.body.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: stopCode != null
            ? Text(
                'Code: $stopCode',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Extracted widget for schedule entry items to improve performance
/// 
/// This widget is extracted to allow Flutter to better optimize rebuilds.
/// It pre-computes display values to avoid repeated string operations.
class ScheduleEntryItem extends StatelessWidget {
  /// The schedule entry entity to display
  final ScheduleEntryEntity entry;

  const ScheduleEntryItem({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    // Pre-compute display values once to avoid repeated calls
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
          style: AppTypography.body.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: headsign != null
            ? Text(
                headsign,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              )
            : null,
        trailing: const Icon(Icons.directions_transit),
        onTap: () {
          // Navigate to schedule detail screen with entry data
          context.push(
            '/schedule/detail',
            extra: entry,
          );
        },
      ),
    );
  }
}

