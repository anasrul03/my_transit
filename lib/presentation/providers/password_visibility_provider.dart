import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class representing password visibility state
/// 
/// This state manages whether password fields should show or hide
/// their text content. Used in login and signup screens to toggle
/// password visibility for better user experience.
class PasswordVisibilityState {
  /// Whether the password is currently visible (not obscured)
  final bool isVisible;

  const PasswordVisibilityState({
    this.isVisible = false,
  });

  /// Creates a copy of this state with the given fields replaced with new values
  PasswordVisibilityState copyWith({
    bool? isVisible,
  }) {
    return PasswordVisibilityState(
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

/// Provider for managing password visibility state
/// 
/// This provider uses a StateNotifier to manage password visibility
/// toggles, replacing setState usage in auth screens for consistency
/// with project coding standards.
final passwordVisibilityProvider =
    StateNotifierProvider<PasswordVisibilityNotifier, PasswordVisibilityState>((ref) {
  return PasswordVisibilityNotifier();
});

/// Notifier class for managing PasswordVisibilityState
/// 
/// Provides methods to toggle password visibility on/off.
class PasswordVisibilityNotifier extends StateNotifier<PasswordVisibilityState> {
  /// Initializes the notifier with default state (password hidden)
  PasswordVisibilityNotifier() : super(const PasswordVisibilityState());

  /// Toggles the password visibility state
  /// 
  /// Switches between visible and hidden states each time it's called.
  void toggle() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  /// Sets the password visibility to a specific value
  /// 
  /// [isVisible] - Whether the password should be visible
  void setVisible(bool isVisible) {
    state = state.copyWith(isVisible: isVisible);
  }
}

