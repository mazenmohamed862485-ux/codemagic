// apps/tobest_management/lib/features/auth/presentation/screens/mgmt_splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/design/widgets/breathing_animation.dart';
import 'package:tobest_management/features/auth/presentation/providers/mgmt_auth_provider.dart';
import 'package:tobest_management/router.dart';

class MgmtSplashScreen extends ConsumerStatefulWidget {
  const MgmtSplashScreen({super.key});

  @override
  ConsumerState<MgmtSplashScreen> createState() => _MgmtSplashScreenState();
}

class _MgmtSplashScreenState extends ConsumerState<MgmtSplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  void _navigate() {
    if (_navigated) return;
    _navigated = true;
    final authState = ref.read(mgmtAuthStateProvider);
    authState.when(
      loading: () => context.go(MgmtRoutes.login),
      error:   (_, __) => context.go(MgmtRoutes.login),
      data: (user) => context.go(
        user != null ? MgmtRoutes.dashboard : MgmtRoutes.login,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mgmtAuthStateProvider, (_, next) {
      if (!next.isLoading) _navigate();
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100, height: 100,
              child: Image.asset('assets/images/tom_icon_light.png'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'TO Best\nManagement',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color:      Theme.of(context).colorScheme.primary,
                height:     1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            const BreathingAnimation(size: 60, showText: false),
          ],
        ),
      ),
    );
  }
}
