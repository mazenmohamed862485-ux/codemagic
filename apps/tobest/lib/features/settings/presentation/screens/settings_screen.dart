// apps/tobest/lib/features/settings/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/themes.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest/app.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:tobest/router.dart';

/// شاشة الإعدادات
///
/// تشمل: الثيم، اللغة، الأجهزة، تغيير كلمة المرور، تسجيل الخروج
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user       = ref.watch(authStateProvider).valueOrNull;
    final themeKey   = ref.watch(userThemeProvider);
    final locale     = ref.watch(userLocaleProvider);
    final theme      = Theme.of(context);
    final isRtl      = Directionality.of(context) == TextDirection.rtl;
    final gasClient  = ref.watch(gasClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'الإعدادات' : 'Settings'),
      ),
      body: ListView(
        children: [
          // ── بيانات المستخدم ─────────────────────────────
          _SectionHeader(isRtl ? 'الحساب' : 'Account'),
          _UserTile(user: user, isRtl: isRtl),

          const Divider(),

          // ── المظهر ──────────────────────────────────────
          _SectionHeader(isRtl ? 'المظهر' : 'Appearance'),
          _ThemeSelector(
            current: themeKey,
            isRtl:   isRtl,
            onChanged: (t) =>
                ref.read(userThemeProvider.notifier).state = t,
          ),

          const Divider(),

          // ── اللغة ───────────────────────────────────────
          _SectionHeader(isRtl ? 'اللغة' : 'Language'),
          _LanguageSelector(
            currentLocale: locale,
            isRtl:         isRtl,
            onChanged: (l) =>
                ref.read(userLocaleProvider.notifier).state = l,
          ),

          const Divider(),

          // ── الأجهزة ─────────────────────────────────────
          _SectionHeader(isRtl ? 'الأجهزة المسجلة' : 'Registered Devices'),
          ListTile(
            leading:  const Icon(Icons.devices),
            title:    Text(isRtl ? 'إدارة الأجهزة' : 'Manage Devices'),
            trailing: const Icon(Icons.chevron_right),
            onTap:    () => context.push('/devices'),
          ),

          const Divider(),

          // ── الأمان ──────────────────────────────────────
          _SectionHeader(isRtl ? 'الأمان' : 'Security'),
          ListTile(
            leading:  const Icon(Icons.lock_outline),
            title:    Text(isRtl ? 'تغيير كلمة المرور' : 'Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap:    () => _showChangePasswordSheet(context, ref, isRtl),
          ),

          const Divider(),

          // ── الاشتراك ─────────────────────────────────────
          _SectionHeader(isRtl ? 'الاشتراك' : 'Subscription'),
          ListTile(
            leading:  const Icon(Icons.card_membership),
            title:    Text(isRtl ? 'تفاصيل الاشتراك' : 'Subscription Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap:    () => context.push(AppRoutes.subscription),
          ),

          const Divider(),

          // ── الطلبات ─────────────────────────────────────
          _SectionHeader(isRtl ? 'البرنامج' : 'Program'),
          ListTile(
            leading:  const Icon(Icons.swap_horiz),
            title:    Text(isRtl ? 'طلب تغيير البرنامج' : 'Request Program Change'),
            trailing: const Icon(Icons.chevron_right),
            onTap:    () => _showProgramChangeSheet(context, ref, isRtl),
          ),

          const Divider(),

          // ── حول التطبيق ──────────────────────────────────
          _SectionHeader(isRtl ? 'حول' : 'About'),
          ListTile(
            leading:  const Icon(Icons.info_outline),
            title:    Text(isRtl ? 'الإصدار 1.0.0' : 'Version 1.0.0'),
            subtitle: const Text('TO Best'),
          ),

          const Divider(),

          // ── تسجيل الخروج ─────────────────────────────────
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
        content: Text(
          isRtl ? 'هل أنت متأكد من تسجيل الخروج؟' : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child:     Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            style:     FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(isRtl ? 'خروج' : 'Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(authStateProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  void _showChangePasswordSheet(
      BuildContext context, WidgetRef ref, bool isRtl) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      builder:            (_) => _ChangePasswordSheet(isRtl: isRtl, ref: ref),
    );
  }

  void _showProgramChangeSheet(
      BuildContext context, WidgetRef ref, bool isRtl) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      builder:            (_) => _ProgramChangeSheet(isRtl: isRtl, ref: ref),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────

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
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.isRtl});
  final dynamic user;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        radius:          24,
        child: Text(
          (user?.name as String? ?? '?').isNotEmpty
              ? (user!.name as String)[0].toUpperCase()
              : '?',
          style: TextStyle(
            color:      theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize:   AppTypography.titleSm,
          ),
        ),
      ),
      title:    Text(user?.name as String? ?? ''),
      subtitle: Text(user?.email as String? ?? ''),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.current,
    required this.isRtl,
    required this.onChanged,
  });
  final String current;
  final bool isRtl;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final themes = {
      'auto':  isRtl ? 'تلقائي' : 'Auto',
      'light': isRtl ? 'فاتح'   : 'Light',
      'dark':  isRtl ? 'داكن'   : 'Dark',
      'blue':  isRtl ? 'أزرق'   : 'Blue',
      'pink':  isRtl ? 'وردي'   : 'Pink',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: themes.entries.map((e) {
            final selected = current == e.key;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label:      Text(e.value),
                selected:   selected,
                onSelected: (_) => onChanged(e.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.currentLocale,
    required this.isRtl,
    required this.onChanged,
  });
  final Locale? currentLocale;
  final bool isRtl;
  final void Function(Locale?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          ChoiceChip(
            label:      const Text('العربية'),
            selected:   currentLocale?.languageCode == 'ar',
            onSelected: (_) => onChanged(const Locale('ar')),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label:      const Text('English'),
            selected:   currentLocale?.languageCode == 'en',
            onSelected: (_) => onChanged(const Locale('en')),
          ),
        ],
      ),
    );
  }
}

// ── تغيير كلمة المرور ─────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.isRtl, required this.ref});
  final bool isRtl;
  final WidgetRef ref;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey  = GlobalKey<FormState>();
  final _current  = TextEditingController();
  final _newPass  = TextEditingController();
  final _confirm  = TextEditingController();
  bool _loading   = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.base,
        left:   AppSpacing.base,
        right:  AppSpacing.base,
        top:    AppSpacing.base,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isRtl ? 'تغيير كلمة المرور' : 'Change Password',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            TextFormField(
              controller:  _current,
              obscureText: true,
              decoration: InputDecoration(
                labelText: widget.isRtl ? 'كلمة المرور الحالية' : 'Current Password',
              ),
              validator: (v) => v == null || v.isEmpty
                  ? (widget.isRtl ? 'مطلوب' : 'Required')
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller:  _newPass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: widget.isRtl ? 'كلمة المرور الجديدة' : 'New Password',
              ),
              validator: (v) => (v?.length ?? 0) < 8
                  ? (widget.isRtl ? '8 أحرف على الأقل' : 'Min 8 characters')
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller:  _confirm,
              obscureText: true,
              decoration: InputDecoration(
                labelText: widget.isRtl ? 'تأكيد كلمة المرور' : 'Confirm Password',
              ),
              validator: (v) => v != _newPass.text
                  ? (widget.isRtl ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match')
                  : null,
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
                  : Text(widget.isRtl ? 'حفظ' : 'Save'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = widget.ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final gas = await widget.ref.read(gasClientProvider.future);
      await gas.post('/auth/change-password', data: {
        'userId':      user.id,
        'currentPass': _current.text,
        'newPass':     _newPass.text,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            widget.isRtl ? 'تم تغيير كلمة المرور ✓' : 'Password changed ✓',
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
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }
}

// ── طلب تغيير البرنامج ────────────────────────────────────────

class _ProgramChangeSheet extends StatefulWidget {
  const _ProgramChangeSheet({required this.isRtl, required this.ref});
  final bool isRtl;
  final WidgetRef ref;

  @override
  State<_ProgramChangeSheet> createState() => _ProgramChangeSheetState();
}

class _ProgramChangeSheetState extends State<_ProgramChangeSheet> {
  final _reason  = TextEditingController();
  String? _selectedProgram;
  bool _loading  = false;

  static const _programs = [
    'Upper / Lower',
    'Anterior / Posterior',
    'Full Body',
    'Arnold',
    'Push / Pull / Legs',
    'Custom',
  ];

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
            widget.isRtl ? 'طلب تغيير البرنامج' : 'Request Program Change',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          DropdownButtonFormField<String>(
            value:       _selectedProgram,
            hint:        Text(widget.isRtl ? 'اختر البرنامج' : 'Select Program'),
            items:       _programs.map((p) => DropdownMenuItem(
              value: p,
              child: Text(p),
            )).toList(),
            onChanged:   (v) => setState(() => _selectedProgram = v),
            decoration: InputDecoration(
              labelText: widget.isRtl ? 'البرنامج المطلوب' : 'Requested Program',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          TextFormField(
            controller: _reason,
            maxLines:   3,
            decoration: InputDecoration(
              labelText: widget.isRtl ? 'سبب الطلب' : 'Reason',
              hintText:  widget.isRtl
                  ? 'اشرح سبب رغبتك في تغيير البرنامج...'
                  : 'Explain why you want to change the program...',
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          FilledButton(
            onPressed: _loading || _selectedProgram == null ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white,
                    ),
                  )
                : Text(widget.isRtl ? 'إرسال الطلب' : 'Submit Request'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedProgram == null) return;
    setState(() => _loading = true);
    try {
      final user = widget.ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final gas = await widget.ref.read(gasClientProvider.future);
      await gas.post('/workout/program-change', data: {
        'userId':            user.id,
        'userName':          user.name,
        'requestedProgram':  _selectedProgram,
        'reason':            _reason.text.trim(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            widget.isRtl ? 'تم إرسال طلبك ✓' : 'Request sent ✓',
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
    _reason.dispose();
    super.dispose();
  }
}
