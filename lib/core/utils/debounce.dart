import 'dart:async';

/// A utility class for debouncing function calls
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Debounces a function call by the specified duration
class Debounce {
  static Timer? _timer;
  
  static void run(Duration delay, void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  
  static void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

