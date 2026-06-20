// apps/tobest/lib/features/home/presentation/screens/main_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:tobest/router.dart';

/// Shell الرئيسي مع Bottom Navigation Bar
///
/// 5 تبويبات: الرئيسية، التمارين، التغذية، التقدم، الشات
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isRtl     = Directionality.of(context) == TextDirection.rtl;
    final location  = GoRouterState.of(context).matchedLocation;
    final currentIdx = _locationToIndex(location);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIdx,
          onDestinationSelected: (i) => _navigate(context, i),
          destinations: [
            NavigationDestination(
              icon:           const Icon(Icons.home_outlined),
              selectedIcon:   const Icon(Icons.home),
              label:          isRtl ? 'الرئيسية' : 'Home',
            ),
            NavigationDestination(
              icon:           const Icon(Icons.fitness_center_outlined),
              selectedIcon:   const Icon(Icons.fitness_center),
              label:          isRtl ? 'التمارين' : 'Workout',
            ),
            NavigationDestination(
              icon:           const Icon(Icons.restaurant_outlined),
              selectedIcon:   const Icon(Icons.restaurant),
              label:          isRtl ? 'التغذية' : 'Nutrition',
            ),
            NavigationDestination(
              icon:           const Icon(Icons.bar_chart_outlined),
              selectedIcon:   const Icon(Icons.bar_chart),
              label:          isRtl ? 'التقدم' : 'Progress',
            ),
            NavigationDestination(
              icon:           const Icon(Icons.chat_outlined),
              selectedIcon:   const Icon(Icons.chat),
              label:          isRtl ? 'الشات' : 'Chat',
            ),
          ],
        ),
      ),
    );
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/workout'))  return 1;
    if (location.startsWith('/nutrition')) return 2;
    if (location.startsWith('/progress')) return 3;
    if (location.startsWith('/conversations')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go(AppRoutes.home);
      case 1: context.go(AppRoutes.workout);
      case 2: context.go(AppRoutes.nutrition);
      case 3: context.go(AppRoutes.progress);
      case 4: context.go(AppRoutes.conversations);
    }
  }
}
