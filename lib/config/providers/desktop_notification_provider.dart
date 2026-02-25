import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/app_focus_service.dart';
import '../../core/services/desktop_notification_service.dart';
import '../../core/services/inbound_activity_policy.dart';

final appFocusServiceProvider = Provider<AppFocusService>((ref) {
  final service = AppFocusService();
  ref.onDispose(service.dispose);
  return service;
});

final desktopNotificationServiceProvider = Provider<DesktopNotificationService>(
  (ref) {
    final appFocusState = ref.watch(appFocusServiceProvider);
    return DesktopNotificationServiceImpl(appFocusState: appFocusState);
  },
);

final appOpenedAtProvider = Provider<DateTime>((_) => DateTime.now());

final inboundActivityPolicyProvider = Provider<InboundActivityPolicy>((ref) {
  final appFocusState = ref.watch(appFocusServiceProvider);
  final appOpenedAt = ref.watch(appOpenedAtProvider);
  return InboundActivityPolicy(
    appFocusState: appFocusState,
    appOpenedAt: appOpenedAt,
  );
});

final desktopNotificationsSupportedProvider = Provider<bool>((ref) {
  return ref.watch(desktopNotificationServiceProvider).isSupported;
});
