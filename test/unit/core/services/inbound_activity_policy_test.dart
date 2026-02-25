import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/services/app_focus_service.dart';
import 'package:iris_chat/core/services/inbound_activity_policy.dart';

class _FakeAppFocusState implements AppFocusState {
  _FakeAppFocusState(this.isAppFocused);

  @override
  bool isAppFocused;
}

void main() {
  group('InboundActivityPolicy', () {
    test('canMarkSeen follows app focus state', () {
      final focusedPolicy = InboundActivityPolicy(
        appFocusState: _FakeAppFocusState(true),
        appOpenedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final unfocusedPolicy = InboundActivityPolicy(
        appFocusState: _FakeAppFocusState(false),
        appOpenedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      expect(focusedPolicy.canMarkSeen(), isTrue);
      expect(unfocusedPolicy.canMarkSeen(), isFalse);
    });

    test('shouldNotifyDesktopForTimestamp only allows activity after open', () {
      final policy = InboundActivityPolicy(
        appFocusState: _FakeAppFocusState(false),
        appOpenedAt: DateTime.fromMillisecondsSinceEpoch(2000),
      );

      expect(
        policy.shouldNotifyDesktopForTimestamp(
          DateTime.fromMillisecondsSinceEpoch(1999),
        ),
        isFalse,
      );
      expect(
        policy.shouldNotifyDesktopForTimestamp(
          DateTime.fromMillisecondsSinceEpoch(2000),
        ),
        isTrue,
      );
      expect(
        policy.shouldNotifyDesktopForTimestamp(
          DateTime.fromMillisecondsSinceEpoch(2001),
        ),
        isTrue,
      );
    });
  });
}
