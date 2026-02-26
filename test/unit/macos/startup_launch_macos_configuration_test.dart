import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('macOS startup launch configuration', () {
    test('MainFlutterWindow wires launch_at_startup method channel', () {
      final mainWindowFile = File('macos/Runner/MainFlutterWindow.swift');
      expect(mainWindowFile.existsSync(), isTrue);

      final content = mainWindowFile.readAsStringSync();
      expect(content, contains('import LaunchAtLogin'));
      expect(content, contains('name: "launch_at_startup"'));
      expect(content, contains('launchAtStartupIsEnabled'));
      expect(content, contains('launchAtStartupSetEnabled'));
    });

    test('Xcode project includes LaunchAtLogin package and helper script', () {
      final projectFile = File('macos/Runner.xcodeproj/project.pbxproj');
      expect(projectFile.existsSync(), isTrue);

      final content = projectFile.readAsStringSync();
      expect(
        content,
        contains('https://github.com/sindresorhus/LaunchAtLogin'),
      );
      expect(content, contains('LaunchAtLogin in Frameworks'));
      expect(content, contains('Copy "Launch at Login Helper"'));
      expect(content, contains('copy-helper-swiftpm.sh'));
    });
  });
}
