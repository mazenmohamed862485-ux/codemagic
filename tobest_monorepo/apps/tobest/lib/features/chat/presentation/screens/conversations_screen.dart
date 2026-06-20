// apps/tobest/lib/features/chat/presentation/screens/conversations_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/chat_entity.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:intl/intl.dart';

part 'conversations_screen.g.dart';

@riverpod
Future<List<Conversation>> conversations(Ref ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  final gas  = await ref.read(gasClientProvider.future);
  final resp = await gas.get<Map<String, dynamic>>(
    '/chat/conversations',
    queryParameters: {'userId': user.id, 'role': user.role},
  );

  final list = resp.data?['conversations'] as List<dynamic>? ?? [];
  return list.map((c) => _parseConversation(c as Map<String, dynamic>)).toList();
}

Conversation _parseConversation(Map<String, dynamic> data) => Conversation(
      id:               data['id'] as String,
      participantIds:   List<String>.from(data['participantIds'] as List? ?? []),
      participantRoles: List<String>.from(data['participantRoles'] as List? ?? []),
      lastMessageAt: data['lastMessageAt'] != null
          ? DateTime.tryParse(data['lastMessageAt'] as String)
          : null,
      unreadCount: data['unreadCount'] as int? ?? 0,
    );

/// شاشة قائمة المحادثات
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(conversationsProvider);
    final isRtl      = Directionality.of(context) == TextDirection.rtl;
    final theme      = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'المحادثات' : 'Chats'),
      ),
      body: convsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data: (convs) {
          if (convs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size:  72,
                      color: theme.colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isRtl ? 'لا محادثات حتى الآن' : 'No conversations yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding:          const EdgeInsets.all(AppSpacing.base),
            itemCount:        convs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (ctx, i) {
              final conv     = convs[i];
              final lastTime = conv.lastMessageAt != null
                  ? DateFormat('h:mm a').format(conv.lastMessageAt!)
                  : '';

              return Card(
                child: ListTile(
                  onTap: () => context.push('/conversations/chat/${conv.id}'),
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    isRtl ? 'المدرب' : 'Coach',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    '...',
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lastTime,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Container(
                          margin:     const EdgeInsets.only(top: AppSpacing.xs),
                          padding:    const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:        theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull),
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(
                              color:    Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
