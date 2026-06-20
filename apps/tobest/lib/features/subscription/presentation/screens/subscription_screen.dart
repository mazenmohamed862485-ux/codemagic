// apps/tobest/lib/features/subscription/presentation/screens/subscription_screen.dart
// إصلاح: import 'dart:convert' كان بالخطأ داخل دالة — نُقل للأعلى

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/subscription_entity.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';

part 'subscription_screen.g.dart';

@riverpod
Future<List<SubscriptionPlan>> subscriptionPlans(Ref ref) async {
  final gas  = await ref.read(gasClientProvider.future);
  final resp = await gas.get<Map<String, dynamic>>('/subscription/plans');
  final list = resp.data?['plans'] as List<dynamic>? ?? [];
  return list
      .map((p) => SubscriptionPlan(
            id:         p['id'] as String,
            nameAr:     p['nameAr'] as String,
            nameEn:     p['nameEn'] as String? ?? '',
            price:      (p['price'] as num).toDouble(),
            features:   List<String>.from(p['features'] as List? ?? []),
            isActive:   p['isActive'] as bool? ?? true,
            durationDays: p['durationDays'] as int?,
          ))
      .where((p) => p.isActive)
      .toList();
}

@riverpod
Future<SubscriptionRequest?> mySubscriptionRequest(Ref ref) async {
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return null;
  try {
    final gas  = await ref.read(gasClientProvider.future);
    final resp = await gas.get<Map<String, dynamic>>(
      '/subscription/my-request/$userId',
    );
    final data = resp.data?['request'] as Map<String, dynamic>?;
    if (data == null) return null;
    return SubscriptionRequest(
      id:             data['id'] as String,
      userId:         data['userId'] as String,
      userName:       data['userName'] as String? ?? '',
      planId:         data['planId'] as String,
      requestType:    data['requestType'] as String? ?? 'new',
      paymentImageUrl: data['paymentImageUrl'] as String? ?? '',
      status: SubscriptionRequestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => SubscriptionRequestStatus.pending,
      ),
      createdAt: DateTime.parse(data['createdAt'] as String),
      rejectionReason: data['rejectionReason'] as String?,
    );
  } catch (_) {
    return null;
  }
}

/// شاشة الاشتراك
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync   = ref.watch(subscriptionPlansProvider);
    final requestAsync = ref.watch(mySubscriptionRequestProvider);
    final theme        = Theme.of(context);
    final isRtl        = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'الاشتراك' : 'Subscription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── حالة الطلب الحالي ─────────────────────────
            requestAsync.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
              data: (request) {
                if (request == null) return const SizedBox.shrink();
                return _RequestStatusCard(
                  request: request,
                  isRtl:   isRtl,
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── الخطط المتاحة ──────────────────────────────
            Text(
              isRtl ? 'الخطط المتاحة' : 'Available Plans',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            plansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('$e')),
              data: (plans) => Column(
                children: plans
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _PlanCard(
                            plan:    p,
                            isRtl:   isRtl,
                            ref:     ref,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestStatusCard extends StatelessWidget {
  const _RequestStatusCard({required this.request, required this.isRtl});
  final SubscriptionRequest request;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final status = request.status;
    final (bgColor, icon, label) = switch (status) {
      SubscriptionRequestStatus.pending  => (
          AppColors.warning.withOpacity(0.1),
          Icons.hourglass_empty,
          isRtl ? 'قيد المراجعة' : 'Under Review',
        ),
      SubscriptionRequestStatus.approved => (
          AppColors.success.withOpacity(0.1),
          Icons.check_circle_outline,
          isRtl ? 'تمت الموافقة' : 'Approved',
        ),
      SubscriptionRequestStatus.rejected => (
          theme.colorScheme.error.withOpacity(0.1),
          Icons.cancel_outlined,
          isRtl ? 'مرفوض' : 'Rejected',
        ),
    };

    return Container(
      padding:    const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRtl ? 'حالة طلبك' : 'Request Status',
                style: theme.textTheme.labelMedium,
              ),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (request.rejectionReason != null)
                Text(
                  request.rejectionReason!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.plan,
    required this.isRtl,
    required this.ref,
  });
  final SubscriptionPlan plan;
  final bool isRtl;
  final WidgetRef ref;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _isLoading = false;
  File? _paymentImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan  = widget.plan;
    final isRtl = widget.isRtl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── اسم الخطة والسعر ──────────────────────────
            Row(children: [
              Expanded(
                child: Text(
                  isRtl ? plan.nameAr : plan.nameEn,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical:   AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color:        theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${plan.price.toInt()} ${isRtl ? 'ريال' : 'SAR'}',
                  style: const TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ]),

            if (plan.durationDays != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                isRtl
                    ? '${plan.durationDays} يوم'
                    : '${plan.durationDays} days',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // ── المميزات ──────────────────────────────────
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(children: [
                    Icon(Icons.check,
                        size:  16,
                        color: AppColors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(f, style: theme.textTheme.bodySmall)),
                  ]),
                )),

            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // ── رفع إيصال الدفع ──────────────────────────
            if (_paymentImage != null)
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.file(
                    _paymentImage!,
                    width:  double.infinity,
                    height: 120,
                    fit:    BoxFit.cover,
                  ),
                ),
                Positioned(
                  top:   AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: IconButton.filled(
                    icon:      const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _paymentImage = null),
                    style:     IconButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize:     const Size(28, 28),
                    ),
                  ),
                ),
              ])
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon:      const Icon(Icons.upload),
                label:     Text(
                  isRtl ? 'رفع إيصال الدفع' : 'Upload Payment Receipt',
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            FilledButton(
              onPressed: (_isLoading || _paymentImage == null)
                  ? null
                  : _subscribe,
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,
                      ),
                    )
                  : Text(isRtl ? 'إرسال طلب الاشتراك' : 'Submit Subscription Request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(
      source:         ImageSource.gallery,
      imageQuality:   80,
      maxWidth:       1200,
    );
    if (file != null) setState(() => _paymentImage = File(file.path));
  }

  Future<void> _subscribe() async {
    if (_paymentImage == null) return;
    setState(() => _isLoading = true);

    try {
      final user = widget.ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final gas = await widget.ref.read(gasClientProvider.future);

      // رفع الصورة أولاً
      final uploadResp = await gas.post<Map<String, dynamic>>(
        '/upload/payment',
        data: {
          'userId':   user.id,
          'imageB64': await _imageToBase64(_paymentImage!),
        },
      );
      final imageUrl = uploadResp.data?['url'] as String? ?? '';

      // إرسال الطلب
      await gas.post('/subscription/request', data: {
        'userId':          user.id,
        'userName':        user.name,
        'planId':          widget.plan.id,
        'requestType':     'new',
        'paymentImageUrl': imageUrl,
      });

      widget.ref.invalidate(mySubscriptionRequestProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            widget.isRtl
                ? 'تم إرسال طلبك بنجاح ✓'
                : 'Request submitted successfully ✓',
          ),
          backgroundColor: AppColors.success,
        ));
        setState(() => _paymentImage = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _imageToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }
}
