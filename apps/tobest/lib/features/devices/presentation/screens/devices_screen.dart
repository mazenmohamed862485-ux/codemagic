import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(authStateProvider).valueOrNull;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(isRtl ? 'الأجهزة المسجلة' : 'Registered Devices')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isRtl ? 'الأجهزة النشطة' : 'Active Devices',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('${user.registeredDevices.length} / ${user.maxDevices}'),
                    ]),
                  ),
                ),
                ...user.registeredDevices.map((d) => ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: Text(d),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    onPressed: () async {
                      final gas = await ref.read(gasClientProvider.future);
                      await gas.post('/auth/device/remove', data: {'userId': user.id, 'deviceId': d});
                      ref.invalidate(authStateProvider);
                    },
                  ),
                )),
              ],
            ),
    );
  }
}
