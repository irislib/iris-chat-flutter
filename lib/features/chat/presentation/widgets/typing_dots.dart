import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated three-dot typing indicator.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotIntensity(double t, double offset) {
    final phase = (t + offset) % 1.0;
    // Pulse each dot in sequence with smooth fade/scale.
    return (math.sin(phase * math.pi * 2 - math.pi / 2) + 1) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(intensity: _dotIntensity(t, 0.00)),
                const SizedBox(width: 4),
                _Dot(intensity: _dotIntensity(t, 0.18)),
                const SizedBox(width: 4),
                _Dot(intensity: _dotIntensity(t, 0.36)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = 0.72 + (0.40 * intensity);
    final color = theme.colorScheme.onSurfaceVariant.withAlpha(
      102 + (intensity * 153).round(),
    );

    return Transform.scale(
      scale: scale,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const SizedBox(width: 8, height: 8),
      ),
    );
  }
}
