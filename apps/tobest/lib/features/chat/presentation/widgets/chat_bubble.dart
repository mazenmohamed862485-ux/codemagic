// apps/tobest/lib/features/chat/presentation/widgets/chat_bubble.dart

import 'package:flutter/material.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/chat_entity.dart';
import 'package:intl/intl.dart';

/// فقاعة رسالة في الشات
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.isRtl,
    this.onDelete,
    this.onReply,
  });

  final ChatMessage message;
  final bool isMine;
  final bool isRtl;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final timeStr = DateFormat('h:mm a').format(message.sentAt);

    return Align(
      alignment: isMine
          ? (isRtl ? Alignment.centerLeft  : Alignment.centerRight)
          : (isRtl ? Alignment.centerRight : Alignment.centerLeft),
      child: GestureDetector(
        onLongPress: () => _showOptions(context),
        child: Container(
          margin:      const EdgeInsets.only(bottom: AppSpacing.sm),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? (isRtl ? CrossAxisAlignment.start : CrossAxisAlignment.end)
                : (isRtl ? CrossAxisAlignment.end   : CrossAxisAlignment.start),
            children: [
              // ── Reply Quote ──────────────────────────────
              if (message.replyToContent != null)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color:  theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    message.replyToContent!,
                    maxLines:  2,
                    overflow:  TextOverflow.ellipsis,
                    style:     theme.textTheme.bodySmall,
                  ),
                ),

              // ── الفقاعة ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical:   AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isMine
                      ? AppColors.chatBubbleSelf
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(AppSpacing.radiusMd),
                    topRight:    const Radius.circular(AppSpacing.radiusMd),
                    bottomLeft:  isMine
                        ? const Radius.circular(AppSpacing.radiusMd)
                        : Radius.zero,
                    bottomRight: isMine
                        ? Radius.zero
                        : const Radius.circular(AppSpacing.radiusMd),
                  ),
                  boxShadow: AppShadows.sm,
                ),
                child: message.isDeleted
                    ? Text(
                        isRtl ? '🗑️ تم حذف هذه الرسالة' : '🗑️ This message was deleted',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isMine
                              ? Colors.white.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isMine ? Colors.white : null,
                          height: 1.4,
                        ),
                      ),
              ),

              // ── الوقت + حالة القراءة ──────────────────────
              Padding(
                padding: const EdgeInsets.only(
                  top:   AppSpacing.xs,
                  left:  AppSpacing.xs,
                  right: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isEdited)
                      Text(
                        isRtl ? '(معدّل) ' : '(edited) ',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    Text(
                      timeStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        message.isRead
                            ? Icons.done_all
                            : Icons.done,
                        size:  12,
                        color: message.isRead
                            ? AppColors.info
                            : theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    if (message.isDeleted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(isRtl ? 'رد' : 'Reply'),
                onTap: () {
                  ctx.pop();
                  onReply!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade400),
                title: Text(
                  isRtl ? 'حذف' : 'Delete',
                  style: TextStyle(color: Colors.red.shade400),
                ),
                onTap: () {
                  ctx.pop();
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

extension on BuildContext {
  void pop() => Navigator.of(this).pop();
}
