import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest/router.dart';

class ResetPasswordScreen extends HookConsumerWidget {
  const ResetPasswordScreen({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newPassCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final isLoading   = useState(false);
    final isRtl       = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(title: Text(isRtl ? 'كلمة مرور جديدة' : 'New Password')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: newPassCtrl,
            obscureText: true,
            decoration: InputDecoration(labelText: isRtl ? 'كلمة المرور الجديدة' : 'New Password'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: confirmCtrl,
            obscureText: true,
            decoration: InputDecoration(labelText: isRtl ? 'تأكيد كلمة المرور' : 'Confirm Password'),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: isLoading.value ? null : () async {
              if (newPassCtrl.text != confirmCtrl.text) return;
              isLoading.value = true;
              try {
                final gas = await ref.read(gasClientProvider.future);
                await gas.post('/auth/reset-password', data: {'email': email, 'newPassword': newPassCtrl.text});
                if (context.mounted) context.go(AppRoutes.login);
              } finally { isLoading.value = false; }
            },
            child: Text(isRtl ? 'تغيير كلمة المرور' : 'Reset Password'),
          ),
        ]),
      ),
    );
  }
}
