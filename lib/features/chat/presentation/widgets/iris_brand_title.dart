import 'package:flutter/material.dart';

class IrisBrandTitle extends StatelessWidget {
  const IrisBrandTitle({super.key});

  static const _logoSize = 22.0;
  static const _logoBorderRadius = BorderRadius.all(Radius.circular(4));

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: _logoBorderRadius,
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: _logoSize,
            height: _logoSize,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return const Icon(Icons.chat_bubble_outline, size: _logoSize);
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text('iris chat'),
      ],
    );
  }
}
