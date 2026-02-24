import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iris_chat/features/chat/presentation/widgets/typing_dots.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const Key('golden'),
            child: SizedBox(
              width: 220,
              height: 120,
              child: Align(alignment: Alignment.centerLeft, child: child),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('golden: TypingDots pulsing indicator', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(wrap(const TypingDots()));
    // Capture a deterministic animation frame.
    await tester.pump(const Duration(milliseconds: 220));

    await expectLater(
      find.byKey(const Key('golden')),
      matchesGoldenFile('goldens/typing_dots.png'),
    );
  });
}
