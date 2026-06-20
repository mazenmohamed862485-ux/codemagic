// apps/tobest/lib/features/ai/presentation/screens/ai_coach_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';

/// رسالة في شات الذكاء الاصطناعي
class _AiMessage {
  const _AiMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

/// شاشة مدرب الذكاء الاصطناعي — Gemini 1.5 Flash
///
/// يأخذ context من بيانات المستخدم لتخصيص الإجابات
class AiCoachScreen extends HookConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages   = useState<List<_AiMessage>>([]);
    final ctrl       = useTextEditingController();
    final isLoading  = useState(false);
    final scrollCtrl = useScrollController();
    final theme      = Theme.of(context);
    final isRtl      = Directionality.of(context) == TextDirection.rtl;
    final user       = ref.watch(authStateProvider).valueOrNull;

    // تهيئة Gemini مع System Prompt مخصص
    final geminiModel = useMemoized(() async {
      final gas       = await ref.read(gasClientProvider.future);
      final apiKey    = await gas.getGeminiKey();
      return GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: 1024,
          temperature:     0.7,
        ),
        systemInstruction: Content.system(
          _buildSystemPrompt(user, isRtl),
        ),
      );
    }, [user?.id]);

    Future<void> onSend() async {
      final text = ctrl.text.trim();
      if (text.isEmpty || isLoading.value) return;

      ctrl.clear();
      messages.value = [
        ...messages.value,
        _AiMessage(text: text, isUser: true),
      ];
      isLoading.value = true;

      // تمرير لأسفل
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollCtrl.hasClients) {
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent,
            duration: AppDurations.normal,
            curve:    Curves.easeOut,
          );
        }
      });

      try {
        final model    = await geminiModel;
        final history  = messages.value
            .where((m) => !m.isUser || m.text != text)
            .map((m) => Content(
                  m.isUser ? 'user' : 'model',
                  [TextPart(m.text)],
                ))
            .toList();

        final chat = model.startChat(history: history);
        final resp = await chat.sendMessage(Content.text(text));
        final reply = resp.text ?? (isRtl ? 'لا يمكنني الرد الآن' : 'Unable to respond');

        messages.value = [...messages.value, _AiMessage(text: reply, isUser: false)];
      } catch (e) {
        messages.value = [
          ...messages.value,
          _AiMessage(
            text: isRtl
                ? 'عذراً، حدث خطأ. حاول مجدداً.'
                : 'Sorry, an error occurred. Please try again.',
            isUser: false,
          ),
        ];
      } finally {
        isLoading.value = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollCtrl.hasClients) {
            scrollCtrl.animateTo(
              scrollCtrl.position.maxScrollExtent,
              duration: AppDurations.normal,
              curve:    Curves.easeOut,
            );
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width:  32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.psychology,
              size:  18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(isRtl ? 'مدرب AI' : 'AI Coach'),
        ]),
      ),

      body: Column(children: [
        // ── Welcome Banner ──────────────────────────────
        if (messages.value.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology,
                      size:  80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      isRtl
                          ? 'مرحباً! أنا مدربك الرقمي 🤖\nاسألني أي شيء عن التمارين والتغذية'
                          : 'Hi! I\'m your AI coach 🤖\nAsk me anything about fitness & nutrition',
                      style:     theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── اقتراحات أسئلة ─────────────────────
                    Wrap(
                      spacing:    AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment:  WrapAlignment.center,
                      children: [
                        isRtl ? 'كيف أزيد الكتلة العضلية؟' : 'How to build muscle?',
                        isRtl ? 'ما هو أفضل وقت للتمرين؟' : 'Best time to workout?',
                        isRtl ? 'كم بروتين أحتاج يومياً؟' : 'How much protein do I need?',
                        isRtl ? 'تمارين للمبتدئين' : 'Beginner exercises',
                      ].map((q) => ActionChip(
                        label:     Text(q, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          ctrl.text = q;
                          onSend();
                        },
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller:  scrollCtrl,
              padding:     const EdgeInsets.all(AppSpacing.md),
              itemCount:   messages.value.length + (isLoading.value ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == messages.value.length) {
                  return const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.sm),
                    child: _TypingIndicator(),
                  );
                }
                final msg = messages.value[i];
                return _AiBubble(message: msg, isRtl: isRtl, theme: theme);
              },
            ),
          ),

        // ── شريط الإدخال ──────────────────────────────
        Container(
          padding: EdgeInsets.only(
            left:   AppSpacing.sm,
            right:  AppSpacing.sm,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sm,
            top:    AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color:     theme.colorScheme.surface,
            boxShadow: AppShadows.sm,
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller:   ctrl,
                maxLines:     4,
                minLines:     1,
                keyboardType: TextInputType.multiline,
                onSubmitted:  (_) => onSend(),
                decoration: InputDecoration(
                  hintText: isRtl ? 'اسأل مدربك...' : 'Ask your coach...',
                  border:   OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    borderSide:   BorderSide.none,
                  ),
                  filled:    true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical:   AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: isLoading.value ? null : onSend,
              icon:      const Icon(Icons.send),
            ),
          ]),
        ),
      ]),
    );
  }

  String _buildSystemPrompt(user, bool isRtl) {
    final lang    = isRtl ? 'Arabic' : 'English';
    final gender  = user?.gender == 'male' ? (isRtl ? 'ذكر' : 'Male') : (isRtl ? 'أنثى' : 'Female');
    final weight  = user?.weight != null ? '${user!.weight} kg' : 'unknown';
    final height  = user?.height != null ? '${user!.height} cm' : 'unknown';
    final age     = user?.age != null ? '${user!.age} years' : 'unknown';

    return '''
You are an expert fitness and nutrition coach for the TO Best app.
Always respond in $lang.
Be concise, practical, and encouraging.
User profile: Gender=$gender, Weight=$weight, Height=$height, Age=$age.
Focus on evidence-based advice. Never recommend supplements or medications.
Keep responses under 200 words unless a detailed explanation is requested.
''';
  }
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({
    required this.message,
    required this.isRtl,
    required this.theme,
  });
  final _AiMessage message;
  final bool isRtl;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser
          ? (isRtl ? Alignment.centerLeft  : Alignment.centerRight)
          : (isRtl ? Alignment.centerRight : Alignment.centerLeft),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical:   AppSpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color:        message.isUser
              ? AppColors.chatBubbleSelf
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color:  message.isUser ? Colors.white : null,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical:   AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _Dot(delay: Duration(milliseconds: i * 200)),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});
  final Duration delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width:  6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
