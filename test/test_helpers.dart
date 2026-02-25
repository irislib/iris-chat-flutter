import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

ThemeData createTestTheme() {
  // Avoid InkSparkle shader compilation in widget tests.
  return ThemeData(useMaterial3: true, splashFactory: InkRipple.splashFactory);
}

/// Creates a test app wrapper with necessary providers and configuration
Widget createTestApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(theme: createTestTheme(), home: child);
      },
    ),
  );
}

/// Creates a test app wrapper using a [GoRouter] (for widgets that use
/// `context.go(...)`).
Widget createTestRouterApp(
  GoRouter router, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp.router(
          theme: createTestTheme(),
          routerConfig: router,
        );
      },
    ),
  );
}

// Test fixtures
const testPubkeyHex =
    'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';
const testPrivkeyHex =
    'f1e2d3c4b5a6f1e2d3c4b5a6f1e2d3c4b5a6f1e2d3c4b5a6f1e2d3c4b5a6f1e2';
