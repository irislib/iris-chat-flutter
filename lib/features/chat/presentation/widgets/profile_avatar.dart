import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers/imgproxy_settings_provider.dart';
import '../../../../core/services/imgproxy_service.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.pubkeyHex,
    required this.displayName,
    this.pictureUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundTextColor,
  });

  final String pubkeyHex;
  final String displayName;
  final String? pictureUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundTextColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imgproxyState = ref.watch(imgproxySettingsProvider);
    final imgproxyService = ImgproxyService(imgproxyState.config);

    final trimmedPicture = pictureUrl?.trim();
    final imageUrl = (trimmedPicture != null && trimmedPicture.isNotEmpty)
        ? imgproxyService.proxiedUrl(
            trimmedPicture,
            width: (radius * 2).round(),
            height: (radius * 2).round(),
            square: true,
          )
        : null;

    final fallbackLetter = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';
    final foregroundImage = imageUrl != null ? NetworkImage(imageUrl) : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.colorScheme.primaryContainer,
      foregroundImage: foregroundImage,
      onForegroundImageError: foregroundImage == null
          ? null
          : (Object error, StackTrace? stackTrace) {},
      child: Text(
        fallbackLetter,
        style: theme.textTheme.titleMedium?.copyWith(
          color: foregroundTextColor ?? theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
