// apps/tobest_management/lib/features/settings/presentation/screens/mgmt_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest_management/app.dart';
import 'package:tobest_management/features/auth/presentation/providers/mgmt_auth_provider.dart';
import 'package:tobest_management/router.dart';

/// شاشة إعدادات الإدارة
///
/// MANAGER: تعديل GAS URL + Gemini Key + خطط الاشتراك
/// الجميع: الثيم، اللغة، تسجيل الخروج
class MgmtSettingsScreen extends ConsumerWidget {
  const MgmtSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me     = ref.watch(mgmtAuthStateProvider).valueOrNull;
    final theme  = Theme.of(context);
    final isRtl  = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'الإعدادات' : 'Settings'),
      ),
      body: ListView(
        children: [
          // ── معلومات الحساب ─────────────────────────────
          _SectionHeader(isRtl ? 'الحساب' : 'Account'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                me?.name.isNotEmpty == true ? me!.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color:      theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title:    Text(me?.name ?? ''),
            subtitle: Text('${me?.email ?? ''} • ${me?.role ?? ''}'),
          ),

          const Divider(),

          // ── الثيم ──────────────────────────────────────
          _SectionHeader(isRtl ? 'المظهر' : 'Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['auto', 'light', 'dark', 'blue', 'pink']
                    .map((t) {
                  final current =
                      ref.watch(mgmtThemeProvider);
                  final labels = {
                    'auto':  isRtl ? 'تلقائي' : 'Auto',
                    'light': isRtl ? 'فاتح'   : 'Light',
                    'dark':  isRtl ? 'داكن'   : 'Dark',
                    'blue':  isRtl ? 'أزرق'   : 'Blue',
                    'pink':  isRtl ? 'وردي'   : 'Pink',
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label:      Text(labels[t]!),
                      selected:   current == t,
                      onSelected: (_) =>
                          ref.read(mgmtThemeProvider.notifier).state = t,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── اللغة ──────────────────────────────────────
          _SectionHeader(isRtl ? 'اللغة' : 'Language'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Row(children: [
              ChoiceChip(
                label:      const Text('العربية'),
                selected:   ref.watch(mgmtLocaleProvider)?.languageCode == 'ar',
                onSelected: (_) => ref
                    .read(mgmtLocaleProvider.notifier)
                    .state = const Locale('ar'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label:      const Text('English'),
                selected:   ref.watch(mgmtLocaleProvider)?.languageCode == 'en',
                onSelected: (_) => ref
                    .read(mgmtLocaleProvider.notifier)
                    .state = const Locale('en'),
              ),
            ]),
          ),

          const Divider(),

          // ── إعدادات الاتصال (MANAGER فقط) ──────────────
          if (me?.isManager ?? false) ...[
            _SectionHeader(isRtl ? 'إعدادات الاتصال' : 'Connection Settings'),

            ListTile(
              leading:  const Icon(Icons.cloud_outlined),
              title:    Text(isRtl ? 'GAS Base URL' : 'GAS Base URL'),
              subtitle: Text(isRtl ? 'اضغط للتعديل' : 'Tap to edit'),
              trailing: const Icon(Icons.chevron_right),
              onTap:    () => _showConnectionSettings(context, ref, isRtl),
            ),

            ListTile(
              leading:  const Icon(Icons.psychology_outlined),
              title:    Text(isRtl ? 'Gemini API Key' : 'Gemini API Key'),
              subtitle: Text(isRtl ? 'مفتاح الذكاء الاصطناعي' : 'AI Coach key'),
              trailing: const Icon(Icons.chevron_right),
              onTap:    () => _showConnectionSettings(context, ref, isRtl),
            ),

            const Divider(),

            // ── إدارة خطط الاشتراك ──────────────────────
            _SectionHeader(isRtl ? 'خطط الاشتراك' : 'Subscription Plans'),
            ListTile(
              leading:  const Icon(Icons.price_change_outlined),
              title:    Text(isRtl ? 'إدارة الخطط' : 'Manage Plans'),
              trailing: const Icon(Icons.chevron_right),
              onTap:    () => _showPlansManager(context, ref, isRtl),
            ),

            const Divider(),
          ],

          // ── تسجيل الخروج ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side:            BorderSide(color: theme.colorScheme.error),
              ),
              onPressed: () => _confirmLogout(context, ref, isRtl),
              icon:      const Icon(Icons.logout),
              label:     Text(isRtl ? 'تسجيل الخروج' : 'Logout'),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, WidgetRef ref, bool isRtl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRtl ? 'تسجيل الخروج' : 'Logout'),
        content: Text(isRtl ? 'هل أنت متأكد؟' : 'Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child:     Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            style:     FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => ctx.pop(true),
            child:     Text(isRtl ? 'خروج' : 'Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(mgmtAuthStateProvider.notifier).logout();
      context.go(MgmtRoutes.login);
    }
  }

  void _showConnectionSettings(
      BuildContext context, WidgetRef ref, bool isRtl) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      builder:            (_) => _ConnectionSettingsSheet(isRtl: isRtl, ref: ref),
    );
  }

  void _showPlansManager(BuildContext context, WidgetRef ref, bool isRtl) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      builder:            (_) => _PlansManagerSheet(isRtl: isRtl, ref: ref),
    );
  }
}

// ── إعدادات الاتصال (GAS + Gemini) ──────────────────────────

class _ConnectionSettingsSheet extends StatefulWidget {
  const _ConnectionSettingsSheet({required this.isRtl, required this.ref});
  final bool isRtl;
  final WidgetRef ref;

  @override
  State<_ConnectionSettingsSheet> createState() =>
      _ConnectionSettingsSheetState();
}

class _ConnectionSettingsSheetState
    extends State<_ConnectionSettingsSheet> {
  final _gasUrlCtrl    = TextEditingController();
  final _gasKeyCtrl    = TextEditingController();
  final _geminiKeyCtrl = TextEditingController();
  bool _loading        = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.base,
        left:   AppSpacing.base,
        right:  AppSpacing.base,
        top:    AppSpacing.base,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isRtl ? 'إعدادات الاتصال' : 'Connection Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          TextFormField(
            controller: _gasUrlCtrl,
            decoration: InputDecoration(
              labelText: 'GAS Base URL',
              hintText:  'https://script.google.com/macros/s/...',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          TextFormField(
            controller: _gasKeyCtrl,
            decoration: const InputDecoration(
              labelText: 'GAS Secret Key',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          TextFormField(
            controller: _geminiKeyCtrl,
            decoration: const InputDecoration(
              labelText: 'Gemini API Key',
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white,
                    ),
                  )
                : Text(widget.isRtl ? 'حفظ الإعدادات' : 'Save Settings'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_gasUrlCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final gas = await widget.ref.read(gasClientProvider.future);
      await gas.updateConnectionSettings(
        gasUrl:    _gasUrlCtrl.text.trim(),
        secretKey: _gasKeyCtrl.text.trim(),
        geminiKey: _geminiKeyCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            widget.isRtl ? 'تم حفظ الإعدادات ✓' : 'Settings saved ✓',
          ),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _gasUrlCtrl.dispose();
    _gasKeyCtrl.dispose();
    _geminiKeyCtrl.dispose();
    super.dispose();
  }
}

// ── مدير خطط الاشتراك ────────────────────────────────────────

class _PlansManagerSheet extends StatelessWidget {
  const _PlansManagerSheet({required this.isRtl, required this.ref});
  final bool isRtl;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand:           false,
      initialChildSize: 0.7,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color:        Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Text(
              isRtl ? 'إدارة خطط الاشتراك' : 'Manage Subscription Plans',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              children: [
                Text(
                  isRtl
                      ? 'يتم تعديل الخطط عبر GAS مباشرة.\nالتغييرات تنعكس فوراً على جميع المستخدمين.'
                      : 'Plans are managed directly via GAS.\nChanges reflect immediately to all users.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.sm),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color:      Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}
