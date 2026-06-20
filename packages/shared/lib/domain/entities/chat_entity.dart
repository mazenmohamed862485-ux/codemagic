// packages/shared/lib/domain/entities/chat_entity.dart

/// رسالة شات واحدة
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.sentAt,
    this.messageType = MessageType.text,
    this.mediaUrl,
    this.replyToId,
    this.replyToContent,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    this.readAt,
    this.reactions = const [],
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole;
  final String content;
  final DateTime sentAt;
  final MessageType messageType;

  /// رابط الصورة أو الصوت
  final String? mediaUrl;

  /// معرف الرسالة التي يرد عليها
  final String? replyToId;
  final String? replyToContent;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime? readAt;
  final List<MessageReaction> reactions;

  bool get isRead => readAt != null;

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderRole,
    String? content,
    DateTime? sentAt,
    MessageType? messageType,
    String? mediaUrl,
    String? replyToId,
    String? replyToContent,
    bool? isDeleted,
    bool? isEdited,
    DateTime? editedAt,
    DateTime? readAt,
    List<MessageReaction>? reactions,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        senderId: senderId ?? this.senderId,
        senderRole: senderRole ?? this.senderRole,
        content: content ?? this.content,
        sentAt: sentAt ?? this.sentAt,
        messageType: messageType ?? this.messageType,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        replyToId: replyToId ?? this.replyToId,
        replyToContent: replyToContent ?? this.replyToContent,
        isDeleted: isDeleted ?? this.isDeleted,
        isEdited: isEdited ?? this.isEdited,
        editedAt: editedAt ?? this.editedAt,
        readAt: readAt ?? this.readAt,
        reactions: reactions ?? this.reactions,
      );

  /// تحويل إلى Map لحفظه في قاعدة البيانات المحلية (drift)
  Map<String, dynamic> toDbMap() => {
        'id':             id,
        'conversationId': conversationId,
        'senderId':       senderId,
        'senderRole':     senderRole,
        'content':        content,
        'sentAt':         sentAt.toIso8601String(),
        'messageType':    messageType.name,
        'mediaUrl':       mediaUrl,
        'replyToId':      replyToId,
        'replyToContent': replyToContent,
        'isDeleted':      isDeleted,
        'isEdited':       isEdited,
      };

  /// بناء Entity من صف قاعدة بيانات (drift row كـ Map)
  factory ChatMessage.fromDbRow(Map<String, dynamic> row) => ChatMessage(
        id:             row['id'] as String,
        conversationId: row['conversationId'] as String,
        senderId:       row['senderId'] as String,
        senderRole:     row['senderRole'] as String,
        content:        row['content'] as String,
        sentAt:         row['sentAt'] as DateTime,
        messageType: MessageType.values.firstWhere(
          (t) => t.name == row['messageType'],
          orElse: () => MessageType.text,
        ),
        mediaUrl:       row['mediaUrl'] as String?,
        replyToId:      row['replyToId'] as String?,
        replyToContent: row['replyToContent'] as String?,
        isDeleted:      row['isDeleted'] as bool? ?? false,
        isEdited:       row['isEdited'] as bool? ?? false,
        editedAt:       row['editedAt'] as DateTime?,
        readAt:         row['readAt'] as DateTime?,
      );
}

enum MessageType { text, image, voice }

/// تفاعل على رسالة
class MessageReaction {
  const MessageReaction({
    required this.userId,
    required this.reactionType,
    required this.createdAt,
  });

  final String userId;

  /// نوع التفاعل: 'like' | 'love' | 'wow' | 'haha' | 'sad' | 'angry'
  final String reactionType;
  final DateTime createdAt;
}

/// محادثة بين طرفين
class Conversation {
  const Conversation({
    required this.id,
    required this.participantIds,
    required this.participantRoles,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final List<String> participantRoles;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime? updatedAt;
}
