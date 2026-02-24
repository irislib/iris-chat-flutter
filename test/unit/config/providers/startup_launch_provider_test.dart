import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/config/providers/startup_launch_provider.dart';
import 'package:iris_chat/core/services/startup_launch_service.dart';

class FakeStartupLaunchService implements StartupLaunchService {
  FakeStartupLaunchService({
    required this.initialSupported,
    required this.initialEnabled,
    this.throwOnLoad = false,
    this.throwOnSetEnabled = false,
  });

  final bool initialSupported;
  bool initialEnabled;
  final bool throwOnLoad;
  final bool throwOnSetEnabled;
  int setEnabledCalls = 0;

  @override
  Future<StartupLaunchSnapshot> load() async {
    if (throwOnLoad) {
      throw Exception('load failed');
    }
    return StartupLaunchSnapshot(
      isSupported: initialSupported,
      enabled: initialEnabled,
    );
  }

  @override
  Future<StartupLaunchSnapshot> setEnabled(bool value) async {
    if (throwOnSetEnabled) {
      throw Exception('set failed');
    }
    setEnabledCalls += 1;
    initialEnabled = value;
    return StartupLaunchSnapshot(
      isSupported: initialSupported,
      enabled: initialEnabled,
    );
  }
}

void main() {
  group('StartupLaunchNotifier', () {
    test('load sets supported + enabled state from service', () async {
      final notifier = StartupLaunchNotifier(
        FakeStartupLaunchService(initialSupported: true, initialEnabled: true),
        autoLoad: false,
      );

      await notifier.load();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isSupported, isTrue);
      expect(notifier.state.enabled, isTrue);
      expect(notifier.state.error, isNull);
    });

    test('load sets unsupported when service reports not supported', () async {
      final notifier = StartupLaunchNotifier(
        FakeStartupLaunchService(
          initialSupported: false,
          initialEnabled: false,
        ),
        autoLoad: false,
      );

      await notifier.load();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isSupported, isFalse);
      expect(notifier.state.enabled, isFalse);
    });

    test('setEnabled updates state via service', () async {
      final service = FakeStartupLaunchService(
        initialSupported: true,
        initialEnabled: true,
      );
      final notifier = StartupLaunchNotifier(service, autoLoad: false);
      await notifier.load();

      await notifier.setEnabled(false);

      expect(service.setEnabledCalls, 1);
      expect(notifier.state.enabled, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('setEnabled stores error when service throws', () async {
      final notifier = StartupLaunchNotifier(
        FakeStartupLaunchService(
          initialSupported: true,
          initialEnabled: true,
          throwOnSetEnabled: true,
        ),
        autoLoad: false,
      );
      await notifier.load();

      await notifier.setEnabled(false);

      expect(notifier.state.enabled, isTrue);
      expect(notifier.state.error, isNotNull);
    });
  });
}
