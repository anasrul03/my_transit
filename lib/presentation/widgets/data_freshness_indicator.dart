import 'package:flutter/material.dart';

/// Widget for displaying data freshness information
/// 
/// Shows when the data was last updated and warns if data is stale.
/// Displays as "Updated X seconds ago" or "Last updated at HH:MM:SS".
class DataFreshnessIndicator extends StatelessWidget {
  /// Timestamp of the last update
  final DateTime? lastUpdate;
  
  /// Threshold in seconds for considering data stale (default: 60 seconds)
  final int staleThresholdSeconds;
  
  /// Whether to show in compact mode
  final bool compact;

  /// Creates a DataFreshnessIndicator
  /// 
  /// [lastUpdate] - Timestamp when data was last updated
  /// [staleThresholdSeconds] - Seconds after which data is considered stale (default: 60)
  /// [compact] - Whether to show in compact mode (default: false)
  const DataFreshnessIndicator({
    super.key,
    this.lastUpdate,
    this.staleThresholdSeconds = 60,
    this.compact = false,
  });

  /// Calculates the age of the data in seconds
  /// 
  /// Returns: Number of seconds since last update, or null if no update timestamp
  int? _getDataAgeSeconds() {
    if (lastUpdate == null) {
      return null;
    }
    return DateTime.now().difference(lastUpdate!).inSeconds;
  }

  /// Checks if the data is stale
  /// 
  /// Returns: true if data is older than staleThresholdSeconds, false otherwise
  bool _isStale() {
    final int? ageSeconds = _getDataAgeSeconds();
    if (ageSeconds == null) {
      return true; // Consider stale if no timestamp
    }
    return ageSeconds > staleThresholdSeconds;
  }

  /// Formats the data age as a human-readable string
  /// 
  /// Returns: Formatted string like "5 seconds ago" or "2 minutes ago"
  String _formatDataAge() {
    final int? ageSeconds = _getDataAgeSeconds();
    if (ageSeconds == null) {
      return 'No data';
    }

    if (ageSeconds < 60) {
      return '$ageSeconds ${ageSeconds == 1 ? 'second' : 'seconds'} ago';
    } else if (ageSeconds < 3600) {
      final int minutes = ageSeconds ~/ 60;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      final int hours = ageSeconds ~/ 3600;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
  }

  /// Formats the timestamp as a time string
  /// 
  /// Returns: Formatted string like "14:30:25"
  String _formatTimestamp() {
    if (lastUpdate == null) {
      return 'N/A';
    }
    // Format time as HH:mm:ss without using intl package
    final int hour = lastUpdate!.hour;
    final int minute = lastUpdate!.minute;
    final int second = lastUpdate!.second;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isStale = _isStale();
    final String ageText = _formatDataAge();
    final String timeText = _formatTimestamp();

    // If compact mode, show minimal indicator
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isStale
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isStale ? Icons.schedule : Icons.check_circle,
              size: 14,
              color: isStale
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              ageText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isStale
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      );
    }

    // Full mode - show detailed information
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStale
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isStale
              ? Theme.of(context).colorScheme.error.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStale ? Icons.schedule : Icons.check_circle,
            color: isStale
                ? Theme.of(context).colorScheme.onErrorContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isStale ? 'Data may be stale' : 'Data is current',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isStale
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Updated $ageText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isStale
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  'Last updated at $timeText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isStale
                            ? Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.7)
                            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

