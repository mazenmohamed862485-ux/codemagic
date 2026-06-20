// apps/tobest/lib/features/chat/presentation/widgets/chat_input_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared/design/tokens.dart';

/// شريط إدخال الشات — نص + صورة
class ChatInputBar extends HookWidget {
  const ChatInputBar({
    super.key,
    required this.isRtl,
    required this.onSend,
    this.onImage,
  });

  final bool isRtl;
  final void Function(String text) onSend;
  final VoidCallback? onImage;

  @override
  Widget build(BuildContext context) {
    final ctrl     = useTextEditingController();
    final hasText  = useState(false);
    final theme    = Theme.of(context);

    ctrl.addListener(() => hasText.value = ctrl.text.trim().isNotEmpty);

    void handleSend() {
      final text = ctrl.text.trim();
      if (text.isEmpty) return;
      ctrl.clear();
      hasText.value = false;
      onSend(text);
    }

    return Container(
      padding: EdgeInsets.only(
        left:   AppSpacing.sm,
        right:  AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sm,
        top:    AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset:     const Offset(0, -2),
          ),
        ],
      ),
      child: Row(children: [
        // ── زر الصورة ──────────────────────────────────
        if (onImage != null)
          IconButton(
            icon:      const Icon(Icons.image_outlined),
            onPressed: onImage,
          ),

        // ── حقل النص ───────────────────────────────────
        Expanded(
          child: TextField(
            controller:    ctrl,
            maxLines:      5,
            minLines:      1,
            keyboardType:  TextInputType.multiline,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText:         isRtl ? 'اكتب رسالة...' : 'Type a message...',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical:   AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                borderSide:   BorderSide.none,
              ),
              filled:    true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // ── زر الإرسال ─────────────────────────────────
        AnimatedSwitcher(
          duration: AppDurations.fast,
          child: hasText.value
              ? IconButton.filled(
                  key:       const ValueKey('send'),
                  icon:      Icon(isRtl ? Icons.send : Icons.send),
                  onPressed: handleSend,
                )
              : Icon(
                  Icons.mic_none,
                  key:   const ValueKey('mic'),
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
        ),
      ]),
    );
  }
}
