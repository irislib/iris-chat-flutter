import 'app_focus_service.dart';

/// Central policy for incoming chat activity handling.
///
/// Keeps cross-cutting rules in one place:
/// 1) when seen state is allowed to advance
/// 2) whether desktop notifications should be emitted for an incoming event
class InboundActivityPolicy {
  InboundActivityPolicy({
    required AppFocusState appFocusState,
    required DateTime appOpenedAt,
  }) : _appFocusState = appFocusState,
       _appOpenedAt = appOpenedAt;

  final AppFocusState _appFocusState;
  final DateTime _appOpenedAt;

  bool canMarkSeen() => _appFocusState.isAppFocused;

  bool shouldNotifyDesktopForTimestamp(DateTime timestamp) {
    return !timestamp.isBefore(_appOpenedAt);
  }
}
