import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/expense_model.dart';
import '../../../../providers/expenses_provider.dart';
import '../../../../providers/vehicles_provider.dart';
import 'add_expense_dialog.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final currencyFormat = NumberFormat('#,##0', 'th_TH');

    final vehicleMap = vehiclesAsync.valueOrNull != null
        ? {for (final v in vehiclesAsync.valueOrNull!) v.id: v}
        : <String, dynamic>{};

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('ค่าใช้จ่าย',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.invalidate(expensesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddExpenseDialog(),
        ),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มค่าใช้จ่าย',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(expensesProvider),
        child: expensesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text('เกิดข้อผิดพลาด: $e',
                style: const TextStyle(color: AppColors.danger)),
          ),
          data: (expenses) {
            if (expenses.isEmpty) {
              return _EmptyExpenseState(
                onAdd: () => showDialog(
                  context: context,
                  builder: (_) => const AddExpenseDialog(),
                ),
              );
            }

            // Summary bar
            final totalAll = expenses.fold<double>(0, (s, e) => s + e.amount);
            final now = DateTime.now();
            final monthExpenses = expenses.where(
              (e) => e.expenseDate.year == now.year && e.expenseDate.month == now.month,
            ).toList();
            final monthTotal = monthExpenses.fold<double>(0, (s, e) => s + e.amount);

            // Group by date
            final grouped = <String, List<ExpenseModel>>{};
            for (final e in expenses) {
              final key = DateFormat('yyyy-MM-dd').format(e.expenseDate);
              grouped.putIfAbsent(key, () => []).add(e);
            }
            final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _SummaryBanner(
                      totalAll: totalAll,
                      monthTotal: monthTotal,
                      count: expenses.length,
                      currencyFormat: currencyFormat,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final dateKey = sortedKeys[i];
                        final dayExpenses = grouped[dateKey]!;
                        final dayDate = DateTime.parse(dateKey);
                        final dayTotal = dayExpenses.fold<double>(0, (s, e) => s + e.amount);

                        return _DateGroup(
                          date: dayDate,
                          expenses: dayExpenses,
                          dayTotal: dayTotal,
                          vehicleMap: vehicleMap,
                          currencyFormat: currencyFormat,
                        );
                      },
                      childCount: sortedKeys.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final double totalAll;
  final double monthTotal;
  final int count;
  final NumberFormat currencyFormat;

  const _SummaryBanner({
    required this.totalAll, required this.monthTotal,
    required this.count, required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.2),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _BannerStat(
              label: 'เดือนนี้',
              value: '฿${currencyFormat.format(monthTotal)}',
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
          Expanded(
            child: _BannerStat(
              label: 'ทั้งหมด',
              value: '฿${currencyFormat.format(totalAll)}',
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
          Expanded(
            child: _BannerStat(
              label: 'รายการ',
              value: '$count รายการ',
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  const _BannerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<ExpenseModel> expenses;
  final double dayTotal;
  final Map vehicleMap;
  final NumberFormat currencyFormat;

  const _DateGroup({
    required this.date, required this.expenses, required this.dayTotal,
    required this.vehicleMap, required this.currencyFormat,
  });

  static const _typeIcon = {
    'น้ำมัน': (Icons.local_gas_station_rounded, Color(0xFFD97706)),
    'ซ่อม': (Icons.build_rounded, Color(0xFFDC2626)),
    'ยาง': (Icons.tire_repair_rounded, Color(0xFF059669)),
    'ค่าเที่ยว': (Icons.route_rounded, Color(0xFF2563EB)),
    'ประกัน': (Icons.shield_rounded, Color(0xFF7C3AED)),
    'อื่นๆ': (Icons.more_horiz_rounded, Color(0xFF64748B)),
  };

  @override
  Widget build(BuildContext context) {
    final currencyFormat = this.currencyFormat;
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final dateLabel = isToday ? 'วันนี้' : DateFormat('d MMM yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(dateLabel,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const Spacer(),
                Text('฿${currencyFormat.format(dayTotal)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),

          // Expense cards
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: expenses.asMap().entries.map((entry) {
                final i = entry.key;
                final expense = entry.value;
                final (icon, color) = _typeIcon[expense.type] ??
                    (Icons.receipt_rounded, AppColors.textSecondary);
                final vehicle = vehicleMap[expense.vehicleId];
                final plateName = vehicle != null ? vehicle.plateNumber as String : '–';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(expense.type,
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                Row(
                                  children: [
                                    const Icon(Icons.directions_car_rounded,
                                        size: 11, color: AppColors.textHint),
                                    const SizedBox(width: 3),
                                    Text(plateName,
                                        style: const TextStyle(
                                            fontSize: 11, color: AppColors.textSecondary)),
                                    if (expense.note != null && expense.note!.isNotEmpty) ...[
                                      const Text(' · ',
                                          style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                                      Flexible(
                                        child: Text(expense.note!,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 11, color: AppColors.textSecondary)),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text('฿${currencyFormat.format(expense.amount)}',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    if (i < expenses.length - 1)
                      const Divider(height: 1, indent: 68, endIndent: 0),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExpenseState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyExpenseState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            const Text('ยังไม่มีค่าใช้จ่าย',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('เริ่มบันทึกค่าใช้จ่ายรถของคุณ\nเพื่อติดตามต้นทุนได้ง่ายขึ้น',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('เพิ่มค่าใช้จ่าย',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
