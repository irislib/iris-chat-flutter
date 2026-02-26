import 'package:flutter/material.dart';

String formatUnseenCount(int count) {
  if (count <= 0) return '0';
  if (count > 99) return '99+';
  return count.toString();
}

class UnseenBadge extends StatelessWidget {
  const UnseenBadge({
    super.key,
    required this.count,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.minHeight = 18,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
  });

  final int count;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double minHeight;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primary;
    final fg = foregroundColor ?? theme.colorScheme.onPrimary;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      decoration: BoxDecoration(color: bg, borderRadius: borderRadius),
      child: Text(
        formatUnseenCount(count),
        style:
            textStyle ??
            theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
