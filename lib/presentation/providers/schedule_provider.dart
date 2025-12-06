import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/stop_entity.dart';
import '../../domain/entities/schedule_entry_entity.dart';
import '../../domain/entities/stop_time_entity.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/gtfs_static_repository.dart';
import 'gtfs_static_provider.dart';

/// Provider for the GTFS static repository
/// 
/// This provides access to the GTFS static repository for fetching
/// schedule-related data like stop_times, trips, and routes.
final scheduleRepositoryProvider = Provider<GtfsStaticRepository>((ref) {
  return ref.read(gtfsStaticRepositoryProvider);
});

/// Provider for schedule state management
/// 
/// This provider manages the state for the schedule feature, including
/// stop search, stop selection, and schedule data loading.
final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>(
  (ref) {
    return ScheduleNotifier(
      repository: ref.read(scheduleRepositoryProvider),
      gtfsStaticState: ref.watch(gtfsStaticProvider),
    );
  },
);

/// State class representing the schedule feature state
/// 
/// This state tracks the search query, matching stops, selected stop,
/// schedule entries, loading state, and any errors that occur.
class ScheduleState {
  /// The current search query for filtering stops by name
  final String searchQuery;
  
  /// The currently selected stop for viewing schedules
  final StopEntity? selectedStop;
  
  /// List of stops matching the current search query
  final List<StopEntity> matchingStops;
  
  /// List of schedule entries for the selected stop
  /// 
  /// Each entry combines stop_time, trip, route, and stop information
  /// and is sorted chronologically by arrival/departure time.
  final List<ScheduleEntryEntity> scheduleEntries;
  
  /// Whether schedule data is currently being loaded
  final bool isLoading;
  
  /// Any error that occurred during schedule loading
  final Failure? error;

  const ScheduleState({
    this.searchQuery = '',
    this.selectedStop,
    this.matchingStops = const [],
    this.scheduleEntries = const [],
    this.isLoading = false,
    this.error,
  });

  /// Creates a copy of this state with the given fields replaced with new values
  /// 
  /// [searchQuery] - Optional new search query
  /// [selectedStop] - Optional new selected stop (use null to clear)
  /// [matchingStops] - Optional new list of matching stops
  /// [scheduleEntries] - Optional new list of schedule entries
  /// [isLoading] - Optional new loading state
  /// [error] - Optional new error (use null to clear)
  /// 
  /// Returns: A new ScheduleState with updated values
  ScheduleState copyWith({
    String? searchQuery,
    StopEntity? selectedStop,
    List<StopEntity>? matchingStops,
    List<ScheduleEntryEntity>? scheduleEntries,
    bool? isLoading,
    Failure? error,
  }) {
    return ScheduleState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStop: selectedStop ?? this.selectedStop,
      matchingStops: matchingStops ?? this.matchingStops,
      scheduleEntries: scheduleEntries ?? this.scheduleEntries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier class for managing schedule state
/// 
/// This notifier handles stop search, stop selection, and schedule data loading.
/// It combines data from stop_times, trips, and routes to build complete schedule entries.
class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final GtfsStaticRepository _repository;
  final GtfsStaticState _gtfsStaticState;

  ScheduleNotifier({
    required GtfsStaticRepository repository,
    required GtfsStaticState gtfsStaticState,
  })  : _repository = repository,
        _gtfsStaticState = gtfsStaticState,
        super(const ScheduleState());

  /// Searches for stops matching the given query
  /// 
  /// Filters stops from the GTFS static data by name. The search is case-insensitive
  /// and matches stops whose name contains the query string.
  /// 
  /// [query] - The search query string to match against stop names
  /// 
  /// This method updates the state with matching stops and clears the selected stop
  /// if the query changes. If GTFS static data is not loaded yet, it will show an error.
  void searchStops(String query) {
    // Update search query
    state = state.copyWith(searchQuery: query);

    // If query is empty, clear matching stops
    if (query.isEmpty) {
      state = state.copyWith(matchingStops: []);
      return;
    }

    // Check if GTFS static data is loaded
    if (!_gtfsStaticState.isLoaded) {
      state = state.copyWith(
        matchingStops: [],
        error: ServerFailure('GTFS static data is still loading. Please wait...'),
      );
      return;
    }

    // Check if there's an error loading GTFS static data
    if (_gtfsStaticState.error != null) {
      state = state.copyWith(
        matchingStops: [],
        error: ServerFailure('Failed to load GTFS static data: ${_gtfsStaticState.error}'),
      );
      return;
    }

    // Get stops from GTFS static state
    final List<StopEntity> allStops = _gtfsStaticState.stops;

    // Filter stops by name (case-insensitive partial match)
    final String lowerQuery = query.toLowerCase();
    final List<StopEntity> matches = allStops.where((StopEntity stop) {
      // Match against stop name or code if available
      final String? name = stop.name?.toLowerCase();
      final String? code = stop.code?.toLowerCase();
      return (name != null && name.contains(lowerQuery)) ||
          (code != null && code.contains(lowerQuery));
    }).toList();

    // Update state with matching stops
    state = state.copyWith(matchingStops: matches, error: null);
  }

  /// Selects a stop and loads its schedule data
  /// 
  /// When a stop is selected, this method fetches all stop_times for that stop,
  /// then retrieves the corresponding trips and routes to build complete schedule entries.
  /// The entries are sorted chronologically by arrival/departure time.
  /// 
  /// [stop] - The stop entity to load schedule data for
  /// 
  /// This method sets loading state, fetches data, and updates state with schedule entries.
  Future<void> selectStop(StopEntity stop) async {
    // Set loading state and clear previous error
    state = state.copyWith(
      selectedStop: stop,
      isLoading: true,
      error: null,
      scheduleEntries: [],
    );

    try {
      // Load schedule data for the selected stop
      await _loadScheduleForStop(stop);
    } catch (e) {
      // Handle errors
      state = state.copyWith(
        isLoading: false,
        error: ServerFailure('Failed to load schedule: ${e.toString()}'),
      );
    }
  }

  /// Clears the selected stop and schedule data
  /// 
  /// This method resets the schedule view by clearing the selected stop
  /// and all schedule entries. This also effectively clears any cached
  /// schedule data since scheduleEntries is reset.
  void clearSelection() {
    state = state.copyWith(
      selectedStop: null,
      scheduleEntries: [],
      error: null,
    );
  }

  /// Resets the entire schedule view to initial state
  /// 
  /// This clears all state including search query, selected stop,
  /// matching stops, and schedule entries. Use this to return to
  /// the initial view showing all available stops.
  void resetToInitialState() {
    state = const ScheduleState(
      searchQuery: '',
      selectedStop: null,
      matchingStops: [],
      scheduleEntries: [],
      isLoading: false,
      error: null,
    );
  }


  /// Loads schedule data for a specific stop
  /// 
  /// This private method fetches all stop_times for the given stop, then retrieves
  /// the corresponding trips and routes. It combines this data into ScheduleEntryEntity
  /// objects and sorts them chronologically by arrival/departure time.
  /// 
  /// Optimized to use batch trip fetching and pre-computed time values for better performance.
  /// 
  /// [stop] - The stop entity to load schedule data for
  /// 
  /// This method handles GTFS time format (HH:MM:SS, can be >24:00:00 for trips
  /// spanning midnight) and properly sorts times across day boundaries.
  Future<void> _loadScheduleForStop(StopEntity stop) async {
    // Fetch stop_times for this stop
    final stopTimesResult = await _repository.getStopTimesByStopId(stop.id);

    if (!stopTimesResult.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        error: stopTimesResult.failure ?? ServerFailure('Failed to fetch stop times for stop ${stop.id}'),
      );
      return;
    }

    final List<StopTimeEntity> stopTimes = stopTimesResult.data ?? [];
    if (stopTimes.isEmpty) {
      // No schedule data available for this stop
      state = state.copyWith(
        isLoading: false,
        scheduleEntries: [],
        error: null, // Clear any previous errors
      );
      return;
    }

    // Build routes map for efficient O(1) lookups
    final Map<String, RouteEntity> routesMap = <String, RouteEntity>{};
    for (final RouteEntity route in _gtfsStaticState.routes) {
      routesMap[route.id] = route;
    }

    // Get unique trip IDs to fetch in batch (much more efficient than individual calls)
    final Set<String> uniqueTripIds = stopTimes.map((StopTimeEntity st) => st.tripId).toSet();
    
    // Fetch all trips in a single batch call instead of individual calls
    // This reduces from O(n*m) to O(n) complexity
    final tripsResult = await _repository.getTripsByIds(uniqueTripIds.toList());
    
    if (!tripsResult.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        error: tripsResult.failure ?? ServerFailure('Failed to fetch trips for stop ${stop.id}'),
      );
      return;
    }

    final Map<String, TripEntity> tripsMap = tripsResult.data ?? {};

    // Build schedule entries with pre-computed time values for efficient sorting
    // This avoids parsing time strings multiple times during sorting
    final List<ScheduleEntryWithTime> entriesWithTime = <ScheduleEntryWithTime>[];
    
    for (final StopTimeEntity stopTime in stopTimes) {
      final TripEntity? trip = tripsMap[stopTime.tripId];
      if (trip == null) continue; // Skip if trip not found

      final RouteEntity? route = routesMap[trip.routeId];
      if (route == null) continue; // Skip if route not found

      // Pre-compute time value for sorting (parse once, use multiple times)
      final String? timeString = stopTime.departureTime ?? stopTime.arrivalTime;
      final int timeInSeconds = timeString != null ? _parseTimeToSeconds(timeString) : 0;

      // Create schedule entry with pre-computed time
      entriesWithTime.add(ScheduleEntryWithTime(
        entry: ScheduleEntryEntity(
          stopTime: stopTime,
          trip: trip,
          route: route,
          stop: stop,
        ),
        timeInSeconds: timeInSeconds,
      ));
    }

    // If we found stop_times but couldn't build any entries, it indicates missing trip/route data
    if (entriesWithTime.isEmpty && stopTimes.isNotEmpty) {
      state = state.copyWith(
        isLoading: false,
        scheduleEntries: [],
        error: ServerFailure(
          'Found ${stopTimes.length} stop times but could not load trip/route data. '
          'This may indicate incomplete GTFS data.',
        ),
      );
      return;
    }

    // Sort entries chronologically using pre-computed time values
    // For large datasets (>1000 entries), use compute isolate to avoid blocking UI
    final List<ScheduleEntryEntity> entries;
    if (entriesWithTime.length > 1000) {
      // Use compute isolate for large datasets to keep UI responsive
      entries = await compute(_sortScheduleEntries, entriesWithTime);
    } else {
      // For smaller datasets, sort directly (faster due to no isolate overhead)
      entriesWithTime.sort((ScheduleEntryWithTime a, ScheduleEntryWithTime b) {
        return a.timeInSeconds.compareTo(b.timeInSeconds);
      });
      entries = entriesWithTime.map((ScheduleEntryWithTime e) => e.entry).toList();
    }

    // Update state with schedule entries
    state = state.copyWith(
      isLoading: false,
      scheduleEntries: entries,
    );
  }

  /// Parses a GTFS time string to seconds since midnight
  /// 
  /// GTFS times are in HH:MM:SS format and can exceed 24:00:00 for trips
  /// that span midnight. This method converts the time string to total seconds
  /// since midnight for proper sorting.
  /// 
  /// [timeString] - Time string in HH:MM:SS format (can be >24:00:00)
  /// 
  /// Returns: Total seconds since midnight
  int _parseTimeToSeconds(String timeString) {
    final List<String> parts = timeString.split(':');
    if (parts.length < 3) return 0;

    final int hours = int.tryParse(parts[0]) ?? 0;
    final int minutes = int.tryParse(parts[1]) ?? 0;
    final int seconds = int.tryParse(parts[2]) ?? 0;

    // Handle times >24:00:00 (e.g., 25:30:00 = 1:30:00 next day)
    // Convert to total seconds since midnight
    return (hours * 3600) + (minutes * 60) + seconds;
  }
}

/// Helper class to store schedule entry with pre-computed time value
/// 
/// This allows efficient sorting without repeatedly parsing time strings.
/// The time value is computed once when creating the entry and reused during sorting.
/// Made public for compute isolate serialization.
class ScheduleEntryWithTime {
  /// The schedule entry entity
  final ScheduleEntryEntity entry;
  
  /// Pre-computed time value in seconds since midnight for efficient sorting
  final int timeInSeconds;

  const ScheduleEntryWithTime({
    required this.entry,
    required this.timeInSeconds,
  });
}

/// Top-level function for compute isolate to sort schedule entries
/// 
/// This function is used in a compute isolate to sort large datasets
/// without blocking the main UI thread. Must be top-level for compute to work.
/// 
/// [entriesWithTime] - List of schedule entries with pre-computed time values
/// 
/// Returns: Sorted list of schedule entries
List<ScheduleEntryEntity> _sortScheduleEntries(List<ScheduleEntryWithTime> entriesWithTime) {
  // Sort entries by pre-computed time values
  entriesWithTime.sort((ScheduleEntryWithTime a, ScheduleEntryWithTime b) {
    return a.timeInSeconds.compareTo(b.timeInSeconds);
  });
  
  // Extract schedule entries from sorted list
  return entriesWithTime.map((ScheduleEntryWithTime e) => e.entry).toList();
}

