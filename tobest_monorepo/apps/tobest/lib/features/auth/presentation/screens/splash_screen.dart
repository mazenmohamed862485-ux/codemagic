// apps/tobest/lib/features/auth/presentation/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/design/widgets/breathing_animation.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:tobest/router.dart';

/// شاشة البداية — Splash Screen
///
/// تعرض الشعار مع Breathing Animation لمدة ثانيتين
/// ثم تنتقل تلقائياً للشاشة المناسبة بناءً على حالة المصادقة
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _delayedNavigate();
  }

  Future<void> _delayedNavigate() async {
    // انتظار ثانيتين
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && !_navigated) {
      _navigate();
    }
  }

  void _navigate() {
    if (_navigated) return;
    _navigated = true;

    final authState = ref.read(authStateProvider);

    authState.when(
      loading: () => context.go(AppRoutes.login),
      error:   (_, __) => context.go(AppRoutes.login),
      data:    (user) {
        if (user == null) {
          context.go(AppRoutes.login);
        } else {
          // Router Guard سيتولى التوجيه الصحيح
          context.go(AppRoutes.home);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لتغيرات المصادقة
    ref.listen(authStateProvider, (prev, next) {
      if (!next.isLoading) _navigate();
    });

    final theme  = Theme.of(context);
    final isRtl  = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── الشعار ────────────────────────────────────────
            SizedBox(
              width:  120,
              height: 120,
              child: Image.asset('assets/images/tb_icon_light.png'),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── اسم التطبيق ───────────────────────────────────
            Text(
              'TO Best',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── Breathing Animation ───────────────────────────
            BreathingAnimation(
              size:          80,
              showText:      false,
              isRtl:         isRtl,
            ),
          ],
        ),
      ),
    );
  }
}
