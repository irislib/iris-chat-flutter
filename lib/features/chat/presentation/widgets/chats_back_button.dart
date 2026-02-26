import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/providers/chat_provider.dart';
import 'unseen_badge.dart';

class ChatsBackButton extends ConsumerWidget {
  const ChatsBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  void _handlePressed(BuildContext context) {
    final callback = onPressed;
    if (callback != null) {
      callback();
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go('/chats');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionUnseen = ref.exists(sessionStateProvider)
        ? ref.watch(
            sessionStateProvider.select((state) {
              var total = 0;
              for (final session in state.sessions) {
                if (session.unreadCount > 0) {
                  total += session.unreadCount;
                }
              }
              return total;
            }),
          )
        : 0;
    final groupUnseen = ref.exists(groupStateProvider)
        ? ref.watch(
            groupStateProvider.select((state) {
              var total = 0;
              for (final group in state.groups) {
                if (group.unreadCount > 0) {
                  total += group.unreadCount;
                }
              }
              return total;
            }),
          )
        : 0;
    final unseenCount = sessionUnseen + groupUnseen;

    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => _handlePressed(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.arrow_back),
          if (unseenCount > 0)
            Positioned(
              top: -8,
              right: -12,
              child: UnseenBadge(
                key: const Key('chats-back-unseen-badge'),
                count: unseenCount,
                minHeight: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(9)),
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
