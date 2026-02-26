import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers/hashtree_attachment_provider.dart';
import '../../../../core/utils/hashtree_attachments.dart';

class GroupAvatar extends ConsumerStatefulWidget {
  const GroupAvatar({
    super.key,
    required this.groupName,
    this.picture,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
  });

  final String groupName;
  final String? picture;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  ConsumerState<GroupAvatar> createState() => _GroupAvatarState();
}

class _GroupAvatarState extends ConsumerState<GroupAvatar> {
  static final Map<String, Uint8List> _nhashImageCache = <String, Uint8List>{};

  Future<Uint8List?>? _pictureFuture;
  String? _futureKey;

  @override
  void initState() {
    super.initState();
    _refreshPictureFuture();
  }

  @override
  void didUpdateWidget(covariant GroupAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.picture != widget.picture) {
      _refreshPictureFuture();
    }
  }

  void _refreshPictureFuture() {
    final picture = widget.picture?.trim();
    final parsed = picture == null || picture.isEmpty
        ? null
        : parseHashtreeFileLink(picture);
    if (parsed == null || !isImageFilename(parsed.filename)) {
      _futureKey = null;
      _pictureFuture = null;
      return;
    }

    final key = parsed.rawLink;
    _futureKey = key;
    final cached = _nhashImageCache[key];
    if (cached != null) {
      _pictureFuture = Future<Uint8List?>.value(cached);
      return;
    }

    _pictureFuture = () async {
      try {
        final bytes = await ref
            .read(hashtreeAttachmentServiceProvider)
            .downloadFile(link: parsed);
        _nhashImageCache[key] = bytes;
        return bytes;
      } catch (_) {
        return null;
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picture = widget.picture?.trim();
    final networkPicture =
        picture != null &&
            picture.isNotEmpty &&
            (picture.startsWith('https://') || picture.startsWith('http://'))
        ? picture
        : null;
    final fallbackIcon = Icon(
      Icons.groups,
      size: widget.radius,
      color: widget.iconColor ?? theme.colorScheme.onSecondaryContainer,
    );

    if (_pictureFuture != null && _futureKey != null) {
      return FutureBuilder<Uint8List?>(
        future: _pictureFuture,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          return CircleAvatar(
            radius: widget.radius,
            backgroundColor:
                widget.backgroundColor ?? theme.colorScheme.secondaryContainer,
            foregroundImage: bytes != null && bytes.isNotEmpty
                ? MemoryImage(bytes)
                : null,
            child: bytes != null && bytes.isNotEmpty ? null : fallbackIcon,
          );
        },
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor:
          widget.backgroundColor ?? theme.colorScheme.secondaryContainer,
      foregroundImage: networkPicture != null
          ? NetworkImage(networkPicture)
          : null,
      onForegroundImageError: networkPicture == null
          ? null
          : (Object error, StackTrace? stackTrace) {},
      child: networkPicture == null ? fallbackIcon : null,
    );
  }
}
