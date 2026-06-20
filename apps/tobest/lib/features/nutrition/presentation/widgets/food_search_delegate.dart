// apps/tobest/lib/features/nutrition/presentation/widgets/food_search_delegate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/nutrition_entity.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/utils/evaluator.dart';

/// مفوّض البحث في قاعدة الأطعمة
class FoodSearchDelegate extends SearchDelegate<FoodItem?> {
  FoodSearchDelegate({required this.ref, required this.isRtl});

  final WidgetRef ref;
  final bool isRtl;

  @override
  String get searchFieldLabel =>
      isRtl ? 'ابحث عن طعام...' : 'Search food...';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon:      const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon:      const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.trim().length < 2) {
      return Center(
        child: Text(
          isRtl ? 'اكتب كلمتين على الأقل' : 'Type at least 2 characters',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return FutureBuilder<List<FoodItem>>(
      future: _search(query.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Text(isRtl ? 'لا نتائج' : 'No results found'),
          );
        }
        return ListView.separated(
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount:        results.length,
          itemBuilder: (context, i) {
            final food = results[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Text(
                  food.name.isNotEmpty ? food.name[0] : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(food.name),
              subtitle: Text(
                isRtl
                    ? '${food.calories.toInt()} كال / ${food.amount.toInt()}${food.unit}'
                    : '${food.calories.toInt()} kcal / ${food.amount.toInt()}${food.unit}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'P: ${food.protein.toInt()}g',
                    style: const TextStyle(
                      color:      AppColors.info,
                      fontWeight: FontWeight.w600,
                      fontSize:   AppTypography.labelSm,
                    ),
                  ),
                  Text(
                    'C: ${food.carbs.toInt()}g / F: ${food.fat.toInt()}g',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              onTap: () {
                close(context, food);
                _showAmountDialog(context, food);
              },
            );
          },
        );
      },
    );
  }

  Future<List<FoodItem>> _search(String query) async {
    final isar = await ref.read(isarServiceProvider.future);
    final rows = await isar.searchFoods(query, limit: 20);
    return rows.map(FoodItem.fromDbRow).toList();
  }

  Future<void> _showAmountDialog(BuildContext context, FoodItem food) async {
    final ctrl    = TextEditingController(text: food.amount.toInt().toString());
    final theme   = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(food.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller:   ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isRtl ? 'الكمية (جرام)' : 'Amount (g)',
                suffixText: food.unit,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text) ?? food.amount;
              final adjusted = Evaluator.adjustByAmount(food, amount);
              Navigator.of(ctx).pop();
              // يُرسَل للـ Provider
            },
            child: Text(isRtl ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }
}
