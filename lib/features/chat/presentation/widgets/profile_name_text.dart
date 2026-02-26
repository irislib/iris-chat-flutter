import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers/nostr_provider.dart';

/// Displays the best available profile name for a pubkey:
/// Nostr profile name first, then local fallback (animal/name).
class ProfileNameText extends ConsumerWidget {
  const ProfileNameText({
    super.key,
    required this.pubkeyHex,
    required this.fallbackName,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  });

  final String pubkeyHex;
  final String fallbackName;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(profileUpdatesProvider);
    final profileService = ref.watch(profileServiceProvider);
    final profile = profileService.getCachedProfile(pubkeyHex);
    final name = profile?.bestName ?? fallbackName;

    return Text(
      name,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
