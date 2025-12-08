import 'dart:async';

/// A utility class for debouncing function calls
/// 
/// Debouncing delays the execution of a function until after a specified
/// duration has passed since the last time it was invoked. This is useful
/// for limiting the rate of function calls, such as search input handlers
/// or API requests triggered by user input.
/// 
/// Example usage:
/// ```dart
/// final debouncer = Debouncer(delay: Duration(milliseconds: 300));
/// debouncer(() => performSearch(query));
/// ```
class Debouncer {
  /// The delay duration before the function is executed
  final Duration delay;
  
  /// Internal timer that manages the debounce delay
  Timer? _timer;

  /// Creates a Debouncer with the specified delay
  /// 
  /// [delay] - The duration to wait before executing the function.
  ///           Defaults to 500 milliseconds if not specified.
  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Schedules a function to be called after the delay period
  /// 
  /// If called multiple times before the delay expires, the previous
  /// call is cancelled and the timer is reset. This ensures the function
  /// only executes after the user has stopped calling it for the delay duration.
  /// 
  /// [action] - The function to execute after the delay
  void call(void Function() action) {
    // Cancel any existing timer to reset the delay
    _timer?.cancel();
    // Create a new timer with the specified delay
    _timer = Timer(delay, action);
  }

  /// Cancels any pending function calls and cleans up resources
  /// 
  /// This should be called when the Debouncer is no longer needed,
  /// such as in a dispose method, to prevent memory leaks.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Static utility class for debouncing function calls without creating an instance
/// 
/// This class provides a simpler API for one-off debouncing operations
/// where you don't need to maintain a Debouncer instance. However, note that
/// this uses a single static timer, so multiple calls will cancel each other.
/// 
/// For multiple independent debounce operations, use the Debouncer class instead.
class Debounce {
  /// Internal static timer for managing debounce delays
  static Timer? _timer;
  
  /// Executes a function after the specified delay, cancelling any previous calls
  /// 
  /// [delay] - The duration to wait before executing the function
  /// [action] - The function to execute after the delay
  /// 
  /// Note: If called multiple times, only the last call will execute after
  /// the delay, as previous calls are cancelled.
  static void run(Duration delay, void Function() action) {
    // Cancel any existing timer to reset the delay
    _timer?.cancel();
    // Create a new timer with the specified delay
    _timer = Timer(delay, action);
  }
  
  /// Cancels any pending debounced function calls
  /// 
  /// This can be used to cancel a pending debounced operation if needed.
  static void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

