import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iris_chat/features/chat/presentation/widgets/message_input.dart';

void main() {
  testWidgets('MessageInput: Enter sends, Shift+Enter inserts newline', (
    tester,
  ) async {
    var sendCount = 0;
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MessageInput(
            controller: controller,
            onSend: () => sendCount++,
          ),
        ),
      ),
    );

    final field = find.byType(TextField);
    expect(field, findsOneWidget);

    await tester.tap(field);
    await tester.pump();

    await tester.enterText(field, 'hi');
    await tester.pump();

    // Enter sends (no newline).
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(sendCount, 1);
    expect(controller.text, 'hi');

    // Shift+Enter inserts newline, does not send.
    sendCount = 0;
    controller.text = 'hi';
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(sendCount, 0);
    expect(controller.text, contains('\n'));
  });

  testWidgets('MessageInput shows attachment controls when enabled', (
    tester,
  ) async {
    var pickCount = 0;
    var removedIndex = -1;
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MessageInput(
            controller: controller,
            onSend: () {},
            onPickAttachment: () => pickCount++,
            attachmentNames: const ['photo.png'],
            onRemoveAttachment: (index) => removedIndex = index,
            isUploadingAttachment: true,
            attachmentUploadProgress: 0.25,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.attach_file), findsOneWidget);
    expect(find.text('photo.png'), findsOneWidget);
    expect(find.text('Uploading attachment… 25%'), findsOneWidget);
    final uploadIndicator = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('message_input_upload_progress_bar')),
    );
    expect(uploadIndicator.value, closeTo(0.25, 0.0001));

    await tester.tap(find.byIcon(Icons.attach_file));
    await tester.pump();
    expect(pickCount, 1);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(removedIndex, 0);
  });

  testWidgets('MessageInput shows indeterminate upload indicator by default', (
    tester,
  ) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MessageInput(
            controller: controller,
            onSend: () {},
            isUploadingAttachment: true,
          ),
        ),
      ),
    );

    expect(find.text('Uploading attachment…'), findsOneWidget);
    final uploadIndicator = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('message_input_upload_progress_bar')),
    );
    expect(uploadIndicator.value, isNull);
  });

  testWidgets(
    'MessageInput shows thumbnail preview and still accepts typing with attachment selected',
    (tester) async {
      final controller = TextEditingController();
      final onePixelPng = Uint8List.fromList(const <int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x44,
        0x41,
        0x54,
        0x08,
        0x99,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MessageInput(
              controller: controller,
              onSend: () {},
              attachments: [
                MessageInputAttachment(
                  label: 'photo.png',
                  thumbnailBytes: onePixelPng,
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('message_input_attachment_thumbnail_0')),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'typed while attached');
      await tester.pump();
      expect(controller.text, 'typed while attached');
    },
  );
}
