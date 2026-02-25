import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class MessageInputAttachment {
  const MessageInputAttachment({required this.label, this.thumbnailBytes});

  final String label;
  final Uint8List? thumbnailBytes;
}

/// Chat composer input.
///
/// Desktop behavior:
/// - `Enter` sends
/// - `Shift/Ctrl/Alt/Meta + Enter` inserts a newline
class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onChanged,
    this.onPickAttachment,
    this.attachments = const <MessageInputAttachment>[],
    this.attachmentNames = const <String>[],
    this.onRemoveAttachment,
    this.isUploadingAttachment = false,
    this.attachmentUploadProgress,
    this.autofocus = false,
    this.focusNode,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onPickAttachment;
  final List<MessageInputAttachment> attachments;
  @Deprecated('Use attachments instead.')
  final List<String> attachmentNames;
  final ValueChanged<int>? onRemoveAttachment;
  final bool isUploadingAttachment;
  final double? attachmentUploadProgress;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  static const _inputBorderRadius = BorderRadius.all(Radius.circular(24));
  static const _contentPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  );
  static const _attachmentSpacing = SizedBox(height: 8);
  static const _spacing = SizedBox(width: 8);
  static const _attachIcon = Icon(Icons.attach_file);
  static const _sendIcon = Icon(Icons.send);
  static const _uploadProgressKey = ValueKey(
    'message_input_upload_progress_bar',
  );

  @override
  void initState() {
    super.initState();
    _ownedFocusNode = widget.focusNode == null ? FocusNode() : null;
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(
        _handleFocusChanged,
      );
    }
    if (oldWidget.focusNode == null && widget.focusNode != null) {
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
    } else if (oldWidget.focusNode != null && widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) return;
    unawaited(HardwareKeyboard.instance.syncKeyboardState());
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return KeyEventResult.ignored;

    final hk = HardwareKeyboard.instance;
    final hasModifier =
        hk.isShiftPressed ||
        hk.isControlPressed ||
        hk.isAltPressed ||
        hk.isMetaPressed;
    if (hasModifier) {
      _insertNewline();
      return KeyEventResult.handled;
    }

    widget.onSend();
    return KeyEventResult.handled;
  }

  void _insertNewline() {
    final value = widget.controller.value;
    final selection = value.selection;
    final text = value.text;

    if (!selection.isValid) {
      final next = '$text\n';
      widget.controller.value = value.copyWith(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
        composing: TextRange.empty,
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final nextText = text.replaceRange(start, end, '\n');
    widget.controller.value = value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + 1),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachments = widget.attachments.isNotEmpty
        ? widget.attachments
        // ignore: deprecated_member_use_from_same_package
        : widget.attachmentNames
              .map((name) => MessageInputAttachment(label: name))
              .toList(growable: false);
    final uploadProgress = widget.attachmentUploadProgress
        ?.clamp(0.0, 1.0)
        .toDouble();
    final uploadLabel = switch (uploadProgress) {
      null => 'Uploading attachment…',
      final progress =>
        'Uploading ${attachments.length <= 1 ? 'attachment' : 'attachments'}… ${(progress * 100).round()}%',
    };

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 8,
      ),
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (attachments.isNotEmpty || widget.isUploadingAttachment) ...[
            if (attachments.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < attachments.length; i++)
                      InputChip(
                        avatar: attachments[i].thumbnailBytes == null
                            ? null
                            : ClipRRect(
                                key: ValueKey(
                                  'message_input_attachment_thumbnail_$i',
                                ),
                                borderRadius: BorderRadius.circular(4),
                                child: Image.memory(
                                  attachments[i].thumbnailBytes!,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.low,
                                  gaplessPlayback: true,
                                ),
                              ),
                        label: Text(attachments[i].label),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: widget.onRemoveAttachment == null
                            ? null
                            : () => widget.onRemoveAttachment!(i),
                      ),
                  ],
                ),
              ),
            if (widget.isUploadingAttachment) ...[
              if (attachments.isNotEmpty) const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  uploadLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                key: _uploadProgressKey,
                value: uploadProgress,
                minHeight: 4,
              ),
            ],
            _attachmentSpacing,
          ],
          Row(
            children: [
              IconButton(
                onPressed: widget.onPickAttachment,
                icon: _attachIcon,
                tooltip: 'Attach file',
              ),
              Expanded(
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  onKeyEvent: _handleKeyEvent,
                  child: TextField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    autofocus: widget.autofocus,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      border: const OutlineInputBorder(
                        borderRadius: _inputBorderRadius,
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: _contentPadding,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                    onChanged: widget.onChanged,
                    // For platforms/IME where "submit" exists.
                    onSubmitted: (_) => widget.onSend(),
                  ),
                ),
              ),
              _spacing,
              IconButton.filled(onPressed: widget.onSend, icon: _sendIcon),
            ],
          ),
        ],
      ),
    );
  }
}
