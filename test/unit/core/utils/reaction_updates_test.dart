import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/utils/reaction_updates.dart';
import 'package:iris_chat/features/chat/domain/models/message.dart';

void main() {
  ChatMessage message({
    required String id,
    String? eventId,
    String? rumorId,
    Map<String, List<String>> reactions = const {},
  }) {
    return ChatMessage(
      id: id,
      sessionId: 'session-1',
      text: 'hello',
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      direction: MessageDirection.incoming,
      status: MessageStatus.delivered,
      eventId: eventId,
      rumorId: rumorId,
      reactions: reactions,
    );
  }

  test('applies reaction by internal id and moves actor between emojis', () {
    final current = [
      message(
        id: 'm1',
        reactions: {
          '❤️': ['alice', 'bob'],
          '👍': ['carol'],
        },
      ),
    ];

    final applied = applyReactionToMessages(
      current,
      messageId: 'm1',
      emoji: '👍',
      actorPubkeyHex: 'alice',
    );

    expect(applied, isNotNull);
    expect(applied!.updatedMessage.reactions['❤️'], ['bob']);
    expect(applied.updatedMessage.reactions['👍'], ['carol', 'alice']);
  });

  test('matches event id only when enabled', () {
    final current = [message(id: 'm1', eventId: 'evt-1', rumorId: 'rumor-1')];

    final noEventMatch = applyReactionToMessages(
      current,
      messageId: 'evt-1',
      emoji: '🔥',
      actorPubkeyHex: 'alice',
      matchEventId: false,
    );
    expect(noEventMatch, isNull);

    final withEventMatch = applyReactionToMessages(
      current,
      messageId: 'evt-1',
      emoji: '🔥',
      actorPubkeyHex: 'alice',
      matchEventId: true,
    );
    expect(withEventMatch, isNotNull);
    expect(withEventMatch!.updatedMessage.reactions['🔥'], ['alice']);
  });

  test('falls back to rumor id match', () {
    final current = [message(id: 'm1', rumorId: 'rumor-42')];

    final applied = applyReactionToMessages(
      current,
      messageId: 'rumor-42',
      emoji: '✅',
      actorPubkeyHex: 'alice',
    );

    expect(applied, isNotNull);
    expect(applied!.updatedMessage.reactions['✅'], ['alice']);
  });
}
