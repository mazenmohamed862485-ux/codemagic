// apps/tobest_management/lib/features/subscriptions/presentation/screens/subscriptions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/subscription_entity.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest_management/features/auth/presentation/providers/mgmt_auth_provider.dart';
import 'package:intl/intl.dart';

part 'subscriptions_screen.g.dart';

@riverpod
Future<List<SubscriptionRequest>> subscriptionRequests(
  Ref ref, {
  SubscriptionRequestStatus? status,
}) async {
  final gas  = await ref.read(gasClientProvider.future);
  final resp = await gas.get<Map<String, dynamic>>(
    '/admin/subscription-requests',
    queryParameters: {
      if (status != null) 'status': status.name,
    },
  );
  final list = resp.data?['requests'] as List<dynamic>? ?? [];
  return list
      .map((r) => _parseRequest(r as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

SubscriptionRequest _parseRequest(Map<String, dynamic> data) =>
    SubscriptionRequest(
      id:              data['id'] as String,
      userId:          data['userId'] as String,
      userName:        data['userName'] as String? ?? '',
      planId:          data['planId'] as String? ?? '',
      requestType:     data['requestType'] as String? ?? 'new',
      paymentImageUrl: data['paymentImageUrl'] as String? ?? '',
      status:          SubscriptionRequestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => SubscriptionRequestStatus.pending,
      ),
      createdAt: DateTime.parse(data['createdAt'] as String),
      reviewedBy:      data['reviewedBy'] as String?,
      reviewedAt:      data['reviewedAt'] != null
          ? DateTime.tryParse(data['reviewedAt'] as String)
          : null,
      rejectionReason: data['rejectionReason'] as String?,
      approvedDurationDays: data['approvedDurationDays'] as int?,
    );

/// شاشة إدارة طلبات الاشتراك — SUBSCRIPTIONS + MANAGER
class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'الاشتراكات' : 'Subscriptions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.hourglass_empty, size: 16),
                const SizedBox(width: 4),
                Text(isRtl ? 'معلقة' : 'Pending'),
                _PendingBadge(ref: ref),
              ]),
            ),
            Tab(text: isRtl ? 'موافَق عليها' : 'Approved'),
            Tab(text: isRtl ? 'مرفوضة' : 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestList(
            status: SubscriptionRequestStatus.pending,
            isRtl:  isRtl,
          ),
          _RequestList(
            status: SubscriptionRequestStatus.approved,
            isRtl:  isRtl,
          ),
          _RequestList(
            status: SubscriptionRequestStatus.rejected,
            isRtl:  isRtl,
          ),
        ],
      ),
    );
  }
}

/// قائمة الطلبات حسب الحالة
class _RequestList extends ConsumerWidget {
  const _RequestList({required this.status, required this.isRtl});
  final SubscriptionRequestStatus status;
  final bool isRtl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync =
        ref.watch(subscriptionRequestsProvider(status: status));
    final me   = ref.watch(mgmtAuthStateProvider).valueOrNull;

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('$e')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Text(
              isRtl ? 'لا طلبات في هذه الفئة' : 'No requests in this category',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(subscriptionRequestsProvider(status: status)),
          child: ListView.separated(
            padding:          const EdgeInsets.all(AppSpacing.base),
            itemCount:        requests.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (ctx, i) => _RequestCard(
              request:  requests[i],
              isRtl:    isRtl,
              canReview: status == SubscriptionRequestStatus.pending &&
                  (me?.isManager == true ||
                      me?.isSubscriptions == true),
              ref: ref,
            ),
          ),
        );
      },
    );
  }
}

/// بطاقة طلب اشتراك
class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isRtl,
    required this.canReview,
    required this.ref,
  });
  final SubscriptionRequest request;
  final bool isRtl;
  final bool canReview;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final dateStr = DateFormat('d MMM yyyy', isRtl ? 'ar' : 'en')
        .format(request.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${request.planId} • $dateStr',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: request.status, isRtl: isRtl),
            ]),

            // ── نوع الطلب ────────────────────────────────
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${isRtl ? 'النوع:' : 'Type:'} ${_requestTypeLabel(request.requestType, isRtl)}',
              style: theme.textTheme.bodySmall,
            ),

            // ── إيصال الدفع ──────────────────────────────
            if (request.paymentImageUrl.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () =>
                    _showPaymentImage(context, request.paymentImageUrl),
                icon:  const Icon(Icons.receipt_long, size: 16),
                label: Text(
                  isRtl ? 'عرض إيصال الدفع' : 'View Payment Receipt',
                  style: const TextStyle(fontSize: AppTypography.labelMd),
                ),
              ),
            ],

            // ── سبب الرفض ────────────────────────────────
            if (request.rejectionReason != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color:        theme.colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  '${isRtl ? 'السبب:' : 'Reason:'} ${request.rejectionReason}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],

            // ── أزرار الموافقة/الرفض ─────────────────────
            if (canReview) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showRejectDialog(context, request, isRtl),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    icon:  const Icon(Icons.close, size: 16),
                    label: Text(isRtl ? 'رفض' : 'Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _showApproveDialog(context, request, isRtl),
                    icon:  const Icon(Icons.check, size: 16),
                    label: Text(isRtl ? 'موافقة' : 'Approve'),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  String _requestTypeLabel(String type, bool isRtl) {
    return switch (type) {
      'new'     => isRtl ? 'اشتراك جديد' : 'New Subscription',
      'renewal' => isRtl ? 'تجديد'        : 'Renewal',
      'upgrade' => isRtl ? 'ترقية'        : 'Upgrade',
      _         => type,
    };
  }

  void _showPaymentImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              imageUrl,
              fit:    BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(AppSpacing.base),
                child:   Icon(Icons.broken_image, size: 48),
              ),
            ),
            TextButton(
              onPressed: () => ctx.pop(),
              child:     Text(isRtl ? 'إغلاق' : 'Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApproveDialog(
      BuildContext context, SubscriptionRequest req, bool isRtl) async {
    final daysCtrl = TextEditingController(text: '30');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRtl ? 'موافقة على الاشتراك' : 'Approve Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${req.userName} — ${req.planId}'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller:   daysCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isRtl ? 'مدة الاشتراك (أيام)' : 'Duration (days)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child:     Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child:     Text(isRtl ? 'موافقة' : 'Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final days = int.tryParse(daysCtrl.text) ?? 30;
    await _processApproval(context, req.id, days, isRtl);
  }

  Future<void> _showRejectDialog(
      BuildContext context, SubscriptionRequest req, bool isRtl) async {
    final reasonCtrl = TextEditingController();
    final confirmed  = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRtl ? 'رفض الطلب' : 'Reject Request'),
        content: TextField(
          controller: reasonCtrl,
          maxLines:   3,
          decoration: InputDecoration(
            hintText: isRtl ? 'سبب الرفض...' : 'Reason for rejection...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child:     Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            style:     FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => ctx.pop(true),
            child:     Text(isRtl ? 'رفض' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await _processRejection(context, req.id, reasonCtrl.text, isRtl);
  }

  Future<void> _processApproval(
    BuildContext context, String reqId, int days, bool isRtl,
  ) async {
    try {
      final me  = ref.read(mgmtAuthStateProvider).valueOrNull;
      final gas = await ref.read(gasClientProvider.future);

      await gas.post('/admin/subscription-requests/$reqId/approve', data: {
        'durationDays': days,
        'reviewedBy':   me?.id ?? '',
      });

      ref.invalidate(subscriptionRequestsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(isRtl ? 'تمت الموافقة ✓' : 'Approved ✓'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _processRejection(
    BuildContext context, String reqId, String reason, bool isRtl,
  ) async {
    try {
      final me  = ref.read(mgmtAuthStateProvider).valueOrNull;
      final gas = await ref.read(gasClientProvider.future);

      await gas.post('/admin/subscription-requests/$reqId/reject', data: {
        'reason':     reason,
        'reviewedBy': me?.id ?? '',
      });

      ref.invalidate(subscriptionRequestsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(isRtl ? 'تم الرفض' : 'Rejected'),
          backgroundColor: AppColors.warning,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isRtl});
  final SubscriptionRequestStatus status;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      SubscriptionRequestStatus.pending  => (AppColors.warning, isRtl ? 'معلق'    : 'Pending'),
      SubscriptionRequestStatus.approved => (AppColors.success, isRtl ? 'موافَق'  : 'Approved'),
      SubscriptionRequestStatus.rejected => (AppColors.error,   isRtl ? 'مرفوض'   : 'Rejected'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      color,
          fontWeight: FontWeight.w700,
          fontSize:   AppTypography.labelSm,
        ),
      ),
    );
  }
}

class _PendingBadge extends ConsumerWidget {
  const _PendingBadge({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    final count = innerRef
        .watch(subscriptionRequestsProvider(
            status: SubscriptionRequestStatus.pending))
        .valueOrNull
        ?.length ?? 0;

    if (count == 0) return const SizedBox.shrink();

    return Container(
      margin:     const EdgeInsets.only(left: 4),
      padding:    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color:        AppColors.warning,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color:     Colors.white,
          fontSize:  10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
