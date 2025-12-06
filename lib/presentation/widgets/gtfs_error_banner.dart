import 'package:flutter/material.dart';

/// Widget for displaying GTFS data quality warnings
/// 
/// This widget displays user-friendly messages for GTFS data quality issues
/// such as E028 (GPS outside service area), E003/E004 (legacy system issues).
/// It can be displayed as a dismissible banner or inline warning.
class GtfsErrorBanner extends StatelessWidget {
  /// List of error codes to display (e.g., ['E028', 'E003'])
  final List<String> errorCodes;
  
  /// Whether the banner can be dismissed
  final bool dismissible;
  
  /// Callback when banner is dismissed
  final VoidCallback? onDismissed;
  
  /// Whether to display as a compact inline warning
  final bool compact;

  /// Creates a GtfsErrorBanner
  /// 
  /// [errorCodes] - List of GTFS error codes to display
  /// [dismissible] - Whether the banner can be dismissed (default: true)
  /// [onDismissed] - Callback when banner is dismissed
  /// [compact] - Whether to display as compact inline warning (default: false)
  const GtfsErrorBanner({
    super.key,
    required this.errorCodes,
    this.dismissible = true,
    this.onDismissed,
    this.compact = false,
  });

  /// Gets user-friendly error message for an error code
  /// 
  /// [errorCode] - The GTFS error code (e.g., 'E028', 'E003', 'E004')
  /// 
  /// Returns: Human-readable error message
  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'E028':
        return 'GPS coordinates outside service area. Vehicle position may be inaccurate.';
      case 'E003':
        return 'Legacy system issue detected. Some data may be incomplete.';
      case 'E004':
        return 'Legacy system issue detected. Some data may be incomplete.';
      default:
        return 'Data quality warning: $errorCode';
    }
  }

  /// Gets icon for an error code
  /// 
  /// [errorCode] - The GTFS error code
  /// 
  /// Returns: IconData for the error code
  static IconData getErrorIcon(String errorCode) {
    switch (errorCode) {
      case 'E028':
        return Icons.location_off;
      case 'E003':
      case 'E004':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  /// Gets color for an error code
  /// 
  /// [errorCode] - The GTFS error code
  /// [context] - Build context for theme access
  /// 
  /// Returns: Color for the error code
  static Color getErrorColor(String errorCode, BuildContext context) {
    switch (errorCode) {
      case 'E028':
        return Theme.of(context).colorScheme.error;
      case 'E003':
      case 'E004':
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show banner if no error codes
    if (errorCodes.isEmpty) {
      return const SizedBox.shrink();
    }

    // If compact mode, show inline warning
    if (compact) {
      return _buildCompactWarning(context);
    }

    // Otherwise show full banner
    return _buildBanner(context);
  }

  /// Builds a compact inline warning
  Widget _buildCompactWarning(BuildContext context) {
    // Show first error code in compact mode
    final String firstError = errorCodes.first;
    final String message = getErrorMessage(firstError);
    final IconData icon = getErrorIcon(firstError);
    final Color color = getErrorColor(firstError, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a full banner
  Widget _buildBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with dismiss button
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data Quality Warning',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
              ),
              if (dismissible)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    onDismissed?.call();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Error messages
          ...errorCodes.map((String errorCode) {
            final String message = getErrorMessage(errorCode);
            final IconData icon = getErrorIcon(errorCode);
            final Color color = getErrorColor(errorCode, context);

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '[$errorCode] $message',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

