import 'package:flutter/widgets.dart';

/// App visibility abstraction for foreground/background state.
abstract class AppFocusState {
  bool get isAppFocused;
}

/// Tracks whether the Flutter app is currently focused/foregrounded.
class AppFocusService with WidgetsBindingObserver implements AppFocusState {
  AppFocusService() {
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _isAppFocused = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  bool _isAppFocused = true;

  @override
  bool get isAppFocused => _isAppFocused;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppFocused = state == AppLifecycleState.resumed;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
