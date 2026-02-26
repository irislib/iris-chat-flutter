import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/config/providers/chat_provider.dart';
import 'package:iris_chat/config/providers/nostr_provider.dart';
import 'package:iris_chat/core/services/profile_service.dart';
import 'package:iris_chat/features/chat/data/datasources/session_local_datasource.dart';
import 'package:iris_chat/features/chat/domain/models/session.dart';
import 'package:iris_chat/features/chat/presentation/screens/create_group_screen.dart';
import 'package:iris_chat/shared/utils/formatters.dart';
import 'package:mocktail/mocktail.dart';

import '../test_helpers.dart';

class _MockSessionLocalDatasource extends Mock
    implements SessionLocalDatasource {}

class _MockProfileService extends Mock implements ProfileService {}

void main() {
  testWidgets('shows profile names and hides pubkeys in member list', (
    tester,
  ) async {
    final mockSessions = _MockSessionLocalDatasource();
    final mockProfiles = _MockProfileService();
    const memberPubkeyHex =
        'b1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b3';

    when(
      () => mockProfiles.profileUpdates,
    ).thenAnswer((_) => const Stream<String>.empty());
    when(() => mockProfiles.getCachedProfile(any())).thenReturn(null);
    when(() => mockProfiles.getCachedProfile(memberPubkeyHex)).thenReturn(
      NostrProfile(
        pubkey: memberPubkeyHex,
        displayName: 'Alice',
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    final sessionNotifier = SessionNotifier(mockSessions, mockProfiles)
      ..state = SessionState(
        sessions: [
          ChatSession(
            id: 's1',
            recipientPubkeyHex: memberPubkeyHex,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );

    await tester.pumpWidget(
      createTestApp(
        const CreateGroupScreen(),
        overrides: [
          sessionStateProvider.overrideWith((ref) => sessionNotifier),
          profileServiceProvider.overrideWithValue(mockProfiles),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text(formatPubkeyForDisplay(memberPubkeyHex)), findsNothing);
  });
}
