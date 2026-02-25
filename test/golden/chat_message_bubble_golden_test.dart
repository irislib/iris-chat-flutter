import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iris_chat/features/chat/domain/models/message.dart';
import 'package:iris_chat/features/chat/presentation/widgets/chat_message_bubble.dart';

import '../test_helpers.dart';

void main() {
  ChatMessage buildMessage({
    required MessageDirection direction,
    String text = 'hello world',
  }) {
    return ChatMessage(
      id: '${direction.name}_$text',
      sessionId: 's1',
      text: text,
      timestamp: DateTime(2026, 2, 1, 12, 0, 0),
      direction: direction,
      status: MessageStatus.delivered,
    );
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: createTestTheme(),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('golden'),
              child: SizedBox(
                width: 420,
                height: 260,
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Align(alignment: Alignment.topCenter, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('golden: ChatMessageBubble idle', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 260));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ChatMessageBubble(
                message: buildMessage(
                  direction: MessageDirection.incoming,
                  text: 'incoming',
                ),
                onReact: (_) async {},
                onDeleteLocal: () async {},
                onReply: () {},
              ),
              ChatMessageBubble(
                message: buildMessage(
                  direction: MessageDirection.outgoing,
                  text: 'yo',
                ),
                onReact: (_) async {},
                onDeleteLocal: () async {},
                onReply: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('golden')),
      matchesGoldenFile('goldens/chat_message_bubble_idle.png'),
    );
  });

  testWidgets('golden: ChatMessageBubble hover actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 260));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        ChatMessageBubble(
          message: buildMessage(
            direction: MessageDirection.outgoing,
            text: 'hover',
          ),
          onReact: (_) async {},
          onDeleteLocal: () async {},
          onReply: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(ChatMessageBubble)));
    await tester.pump();

    await expectLater(
      find.byKey(const Key('golden')),
      matchesGoldenFile('goldens/chat_message_bubble_hover.png'),
    );
  });
}
