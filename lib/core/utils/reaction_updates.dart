import '../../features/chat/domain/models/message.dart';

class ReactionApplyResult {
  const ReactionApplyResult({
    required this.updatedMessages,
    required this.updatedMessage,
  });

  final List<ChatMessage> updatedMessages;
  final ChatMessage updatedMessage;
}

ReactionApplyResult? applyReactionToMessages(
  List<ChatMessage> messages, {
  required String messageId,
  required String emoji,
  required String actorPubkeyHex,
  bool matchEventId = false,
}) {
  var targetIndex = messages.indexWhere((m) => m.id == messageId);
  if (targetIndex == -1 && matchEventId) {
    targetIndex = messages.indexWhere((m) => m.eventId == messageId);
  }
  if (targetIndex == -1) {
    targetIndex = messages.indexWhere((m) => m.rumorId == messageId);
  }
  if (targetIndex == -1) return null;

  final message = messages[targetIndex];
  final nextReactions = <String, List<String>>{};

  for (final entry in message.reactions.entries) {
    final filtered = entry.value.where((u) => u != actorPubkeyHex).toList();
    if (filtered.isNotEmpty) {
      nextReactions[entry.key] = filtered;
    }
  }

  nextReactions[emoji] = [...(nextReactions[emoji] ?? []), actorPubkeyHex];

  final updatedMessage = message.copyWith(reactions: nextReactions);
  final updatedMessages = [...messages];
  updatedMessages[targetIndex] = updatedMessage;

  return ReactionApplyResult(
    updatedMessages: updatedMessages,
    updatedMessage: updatedMessage,
  );
}
