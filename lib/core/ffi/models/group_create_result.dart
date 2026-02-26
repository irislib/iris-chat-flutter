import 'ffi_group_data.dart';
import 'group_create_fanout.dart';

class GroupCreateResult {
  const GroupCreateResult({
    required this.group,
    this.metadataRumorJson,
    required this.fanout,
  });

  factory GroupCreateResult.fromMap(Map<String, dynamic> map) {
    final rawGroup = map['group'];
    return GroupCreateResult(
      group: rawGroup is Map
          ? FfiGroupData.fromMap(Map<String, dynamic>.from(rawGroup))
          : const FfiGroupData.empty(),
      metadataRumorJson: map['metadataRumorJson'] as String?,
      fanout: map['fanout'] is Map
          ? GroupCreateFanout.fromMap(
              Map<String, dynamic>.from(map['fanout'] as Map),
            )
          : const GroupCreateFanout(
              enabled: false,
              attempted: 0,
              succeeded: <String>[],
              failed: <String>[],
            ),
    );
  }

  final FfiGroupData group;
  final String? metadataRumorJson;
  final GroupCreateFanout fanout;
}
