import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class representing confirm password visibility state
/// 
/// This state manages whether the confirm password field should show or hide
/// its text content. Used in signup screens to toggle confirm password
/// visibility for better user experience.
class ConfirmPasswordVisibilityState {
  /// Whether the confirm password is currently visible (not obscured)
  final bool isVisible;

  const ConfirmPasswordVisibilityState({
    this.isVisible = false,
  });

  /// Creates a copy of this state with the given fields replaced with new values
  ConfirmPasswordVisibilityState copyWith({
    bool? isVisible,
  }) {
    return ConfirmPasswordVisibilityState(
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

/// Provider for managing confirm password visibility state
/// 
/// This provider uses a StateNotifier to manage confirm password visibility
/// toggles, replacing setState usage in signup screens for consistency
/// with project coding standards.
final confirmPasswordVisibilityProvider =
    StateNotifierProvider<ConfirmPasswordVisibilityNotifier, ConfirmPasswordVisibilityState>((ref) {
  return ConfirmPasswordVisibilityNotifier();
});

/// Notifier class for managing ConfirmPasswordVisibilityState
/// 
/// Provides methods to toggle confirm password visibility on/off.
class ConfirmPasswordVisibilityNotifier extends StateNotifier<ConfirmPasswordVisibilityState> {
  /// Initializes the notifier with default state (password hidden)
  ConfirmPasswordVisibilityNotifier() : super(const ConfirmPasswordVisibilityState());

  /// Toggles the confirm password visibility state
  /// 
  /// Switches between visible and hidden states each time it's called.
  void toggle() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  /// Sets the confirm password visibility to a specific value
  /// 
  /// [isVisible] - Whether the confirm password should be visible
  void setVisible(bool isVisible) {
    state = state.copyWith(isVisible: isVisible);
  }
}

