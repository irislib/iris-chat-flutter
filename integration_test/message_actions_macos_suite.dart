import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iris_chat/features/chat/domain/models/message.dart';
import 'package:iris_chat/features/chat/presentation/widgets/chat_message_bubble.dart';

Future<String> _capturePngFromFinder(
  WidgetTester tester, {
  required Finder finder,
  required String fileName,
}) async {
  final renderObject = tester.firstRenderObject(finder);
  if (renderObject is! RenderRepaintBoundary) {
    throw StateError('Finder must resolve to a RepaintBoundary');
  }

  final image = await renderObject.toImage(pixelRatio: 2.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Failed to encode screenshot PNG');
  }
  final bytes = byteData.buffer.asUint8List();
  final dir = Directory('integration_test/artifacts');
  await dir.create(recursive: true);
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.absolute.path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('message action dock reply/react/more works on desktop', (
    tester,
  ) async {
    var replyCount = 0;
    var reacted = '';
    var deleteCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 640,
                child: RepaintBoundary(
                  key: const Key('message_actions_capture'),
                  child: ChatMessageBubble(
                    message: ChatMessage(
                      id: 'm1',
                      sessionId: 's1',
                      text: 'integration action test',
                      timestamp: DateTime(2026, 2, 24, 12, 0),
                      direction: MessageDirection.outgoing,
                      status: MessageStatus.sent,
                    ),
                    onReact: (emoji) async => reacted = emoji,
                    onDeleteLocal: () async => deleteCount++,
                    onReply: () => replyCount++,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(ChatMessageBubble)));
    await tester.pump(const Duration(milliseconds: 80));

    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('chat_message_bubble_body_m1')),
    );
    final replyRect = tester.getRect(find.byTooltip('Reply'));
    expect(
      replyRect.right <= bubbleRect.left,
      isTrue,
      reason:
          'Outgoing hover actions must be docked beside, not on top of, the bubble.',
    );
    final screenshotPath = await _capturePngFromFinder(
      tester,
      finder: find.byKey(const Key('message_actions_capture')),
      fileName: 'message_actions_side_dock.png',
    );
    expect(File(screenshotPath).existsSync(), isTrue);

    await tester.tap(find.byTooltip('Reply'));
    await tester.pump();
    expect(replyCount, 1);

    await tester.tap(find.byTooltip('React'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('❤️').first);
    await tester.pumpAndSettle();
    expect(reacted, '❤️');

    await mouse.moveTo(tester.getCenter(find.byType(ChatMessageBubble)));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete locally'));
    await tester.pump(const Duration(milliseconds: 900));
    expect(deleteCount, 1);
  });
}
