import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_exporter.dart';
import '../../../../models/expense_model.dart';
import '../../../../providers/expenses_provider.dart';
import '../../../../providers/vehicles_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../settings/company_profile_screen.dart';
import 'add_expense_dialog.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String? _selectedCategory;
  String? _selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    ref.watch(strProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final currencyFormat = NumberFormat('#,##0', 'th_TH');

    final vehicleMap = vehiclesAsync.valueOrNull != null
        ? {for (final v in vehiclesAsync.valueOrNull!) v.id: v}
        : <String, dynamic>{};

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 54,
        titleSpacing: 4,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
          child: Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ค่าใช้จ่าย & รายงาน',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                ),
                Text(
                  'Expense Log & Financial Export',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Export Report Button in AppBar
          expensesAsync.when(
            data: (expenses) => Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: expenses.isEmpty
                    ? null
                    : () => _showExportDialog(context, expenses, vehicleMap, currencyFormat),
                icon: const Icon(Icons.file_download_rounded, size: 16),
                label: const Text('Export รายงาน'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
            onPressed: () => ref.invalidate(expensesProvider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddExpenseDialog(),
        ),
        backgroundColor: const Color(0xFFE11D48),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          '+ บันทึกค่าใช้จ่าย',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE11D48),
        onRefresh: () async => ref.invalidate(expensesProvider),
        child: expensesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFE11D48)),
          ),
          error: (e, _) => Center(
            child: Text('เกิดข้อผิดพลาด: $e', style: const TextStyle(color: AppColors.danger)),
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

            // Filtered records
            final filtered = expenses.where((e) {
              if (_selectedCategory != null && e.type != _selectedCategory) return false;
              if (_selectedVehicleId != null && e.vehicleId != _selectedVehicleId) return false;
              return true;
            }).toList();

            // Summary calculations
            final totalAll = expenses.fold<double>(0, (s, e) => s + e.amount);
            final now = DateTime.now();
            final monthExpenses = expenses.where(
              (e) => e.expenseDate.year == now.year && e.expenseDate.month == now.month,
            ).toList();
            final monthTotal = monthExpenses.fold<double>(0, (s, e) => s + e.amount);

            // Group filtered by date
            final grouped = <String, List<ExpenseModel>>{};
            for (final e in filtered) {
              final key = DateFormat('yyyy-MM-dd').format(e.expenseDate);
              grouped.putIfAbsent(key, () => []).add(e);
            }
            final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. KPI Summary Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _ModernSummaryBanner(
                      totalAll: totalAll,
                      monthTotal: monthTotal,
                      count: expenses.length,
                      currencyFormat: currencyFormat,
                    ),
                  ),
                ),

                // 2. Category Filter Pills Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFFE11D48)),
                                SizedBox(width: 6),
                                Text(
                                  'กรองตามหมวดหมู่',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedCategory != null || _selectedVehicleId != null)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _selectedCategory = null;
                                  _selectedVehicleId = null;
                                }),
                                child: const Text(
                                  'ล้างตัวกรอง',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FilterChip(
                                label: 'ทั้งหมด (${expenses.length})',
                                isSelected: _selectedCategory == null,
                                onTap: () => setState(() => _selectedCategory = null),
                              ),
                              _FilterChip(
                                label: 'น้ำมัน',
                                icon: Icons.local_gas_station_rounded,
                                color: const Color(0xFFE11D48),
                                isSelected: _selectedCategory == 'น้ำมัน',
                                onTap: () => setState(() =>
                                    _selectedCategory = _selectedCategory == 'น้ำมัน' ? null : 'น้ำมัน'),
                              ),
                              _FilterChip(
                                label: 'ซ่อมบำรุง',
                                icon: Icons.build_circle_rounded,
                                color: const Color(0xFFD97706),
                                isSelected: _selectedCategory == 'ซ่อมบำรุง',
                                onTap: () => setState(() =>
                                    _selectedCategory = _selectedCategory == 'ซ่อมบำรุง' ? null : 'ซ่อมบำรุง'),
                              ),
                              _FilterChip(
                                label: 'ยาง / ล้อ',
                                icon: Icons.tire_repair_rounded,
                                color: const Color(0xFF059669),
                                isSelected: _selectedCategory == 'ยาง',
                                onTap: () => setState(() =>
                                    _selectedCategory = _selectedCategory == 'ยาง' ? null : 'ยาง'),
                              ),
                              _FilterChip(
                                label: 'ค่าเที่ยว / ทางด่วน',
                                icon: Icons.toll_rounded,
                                color: const Color(0xFF4F46E5),
                                isSelected: _selectedCategory == 'ค่าเที่ยว',
                                onTap: () => setState(() =>
                                    _selectedCategory = _selectedCategory == 'ค่าเที่ยว' ? null : 'ค่าเที่ยว'),
                              ),
                              _FilterChip(
                                label: 'ประกัน / พ.ร.บ.',
                                icon: Icons.shield_rounded,
                                color: const Color(0xFF7C3AED),
                                isSelected: _selectedCategory == 'ประกัน',
                                onTap: () => setState(() =>
                                    _selectedCategory = _selectedCategory == 'ประกัน' ? null : 'ประกัน'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Vehicle Filter Selector (If multiple vehicles)
                if (vehicleMap.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _VehicleChip(
                              label: 'รถทุกคัน',
                              isSelected: _selectedVehicleId == null,
                              onTap: () => setState(() => _selectedVehicleId = null),
                            ),
                            ...vehicleMap.values.map((v) {
                              final isSel = _selectedVehicleId == v.id;
                              return _VehicleChip(
                                label: '${v.plateNumber}',
                                isSelected: isSel,
                                onTap: () => setState(() =>
                                    _selectedVehicleId = isSel ? null : v.id),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 4. Expenses List Grouped by Date
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'ไม่พบรายการค่าใช้จ่ายในเงื่อนไขที่เลือก',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final dateKey = sortedKeys[i];
                          final dayExpenses = grouped[dateKey]!;
                          final dayTotal = dayExpenses.fold<double>(0, (s, e) => s + e.amount);
                          final date = DateTime.parse(dateKey);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DateGroupHeader(
                                date: date,
                                dayTotal: dayTotal,
                                currencyFormat: currencyFormat,
                              ),
                              const SizedBox(height: 6),
                              ...dayExpenses.map((expense) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _ExpenseCard(
                                      expense: expense,
                                      vehicleLabel: vehicleMap[expense.vehicleId]?.plateNumber ?? '–',
                                      currencyFormat: currencyFormat,
                                    ),
                                  )),
                              const SizedBox(height: 10),
                            ],
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

  void _showExportDialog(
    BuildContext context,
    List<ExpenseModel> expenses,
    Map<String, dynamic> vehicleMap,
    NumberFormat currencyFormat,
  ) {
    showDialog(
      context: context,
      builder: (_) => _ExportReportDialog(
        expenses: expenses,
        vehicleMap: vehicleMap,
        currencyFormat: currencyFormat,
      ),
    );
  }
}

// ─── 1. Modern KPI Summary Banner ───────────────────────────────────────────
class _ModernSummaryBanner extends StatelessWidget {
  final double totalAll;
  final double monthTotal;
  final int count;
  final NumberFormat currencyFormat;

  const _ModernSummaryBanner({
    required this.totalAll,
    required this.monthTotal,
    required this.count,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _KpiStatCol(
              label: 'เดือนนี้',
              value: '฿${currencyFormat.format(monthTotal)}',
              color: const Color(0xFF10B981),
              icon: Icons.calendar_month_rounded,
            ),
          ),
          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
          Expanded(
            flex: 4,
            child: _KpiStatCol(
              label: 'ยอดรวมทั้งหมด',
              value: '฿${currencyFormat.format(totalAll)}',
              color: const Color(0xFF38BDF8),
              icon: Icons.payments_rounded,
            ),
          ),
          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
          Expanded(
            flex: 2,
            child: _KpiStatCol(
              label: 'บันทึก',
              value: '$count รายการ',
              color: const Color(0xFFA78BFA),
              icon: Icons.receipt_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiStatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _KpiStatCol({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── 2. Filter & Vehicle Chips ──────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFFE11D48);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: isSelected ? Colors.white : activeColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_car_rounded,
                size: 12,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 3. Date Group Header ───────────────────────────────────────────────────
class _DateGroupHeader extends StatelessWidget {
  final DateTime date;
  final double dayTotal;
  final NumberFormat currencyFormat;

  const _DateGroupHeader({
    required this.date,
    required this.dayTotal,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy', 'th_TH').format(date);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          Text(
            '฿${currencyFormat.format(dayTotal)}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 4. Expense Card ────────────────────────────────────────────────────────
class _ExpenseCard extends ConsumerWidget {
  final ExpenseModel expense;
  final String vehicleLabel;
  final NumberFormat currencyFormat;

  const _ExpenseCard({
    required this.expense,
    required this.vehicleLabel,
    required this.currencyFormat,
  });

  Color _typeColor(String type) {
    switch (type) {
      case 'น้ำมัน':
        return const Color(0xFFE11D48);
      case 'ซ่อมบำรุง':
        return const Color(0xFFD97706);
      case 'ยาง':
        return const Color(0xFF059669);
      case 'ค่าเที่ยว':
        return const Color(0xFF4F46E5);
      case 'ประกัน':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'น้ำมัน':
        return Icons.local_gas_station_rounded;
      case 'ซ่อมบำรุง':
        return Icons.build_circle_rounded;
      case 'ยาง':
        return Icons.tire_repair_rounded;
      case 'ค่าเที่ยว':
        return Icons.toll_rounded;
      case 'ประกัน':
        return Icons.shield_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _typeColor(expense.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon
            _TypeIconBox(color: color, icon: _typeIcon(expense.type)),

            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        expense.type,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_car_rounded, size: 10, color: Color(0xFF64748B)),
                            const SizedBox(width: 2),
                            Text(
                              vehicleLabel,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      expense.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ],
              ),
            ),

            // Amount & Delete
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '฿${currencyFormat.format(expense.amount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('ยืนยันลบรายการ'),
                        content: const Text('คุณต้องการลบรายการค่าใช้จ่ายนี้ใช่หรือไม่?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('ยกเลิก'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('ลบ', style: TextStyle(color: Color(0xFFEF4444))),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'ลบ',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeIconBox extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _TypeIconBox({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─── 5. Export Report Modal Dialog ──────────────────────────────────────────
class _ExportReportDialog extends StatefulWidget {
  final List<ExpenseModel> expenses;
  final Map<String, dynamic> vehicleMap;
  final NumberFormat currencyFormat;

  const _ExportReportDialog({
    required this.expenses,
    required this.vehicleMap,
    required this.currencyFormat,
  });

  @override
  State<_ExportReportDialog> createState() => _ExportReportDialogState();
}

class _ExportReportDialogState extends State<_ExportReportDialog> {
  bool _isSendingLine = false;
  String _companyName = 'บริษัท ตัวอย่าง จำกัด (มหาชน)';
  String _companyTaxId = '–';

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  Future<void> _loadCompanyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final savedName = prefs.getString('company_name');
        _companyName = (savedName != null && savedName.trim().isNotEmpty)
            ? savedName.trim()
            : 'บริษัท ตัวอย่าง จำกัด (มหาชน)';
        _companyTaxId = prefs.getString('company_tax_id') ?? '–';
      });
    }
  }

  String _generateCsvContent() {
    final sb = StringBuffer();
    // Add UTF-8 BOM for Excel Thai language support
    sb.write('\uFEFF');
    sb.writeln('วันที่,ทะเบียนรถ,หมวดหมู่ค่าใช้จ่าย,รายละเอียด,จำนวนเงิน (บาท)');

    final sorted = List<ExpenseModel>.from(widget.expenses)
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    for (final e in sorted) {
      final dateStr = DateFormat('yyyy-MM-dd').format(e.expenseDate);
      final plate = widget.vehicleMap[e.vehicleId]?.plateNumber ?? 'ไม่ระบุ';
      final type = e.type.replaceAll(',', ' ');
      final desc = (e.note ?? '').replaceAll(',', ' ').replaceAll('\n', ' ');
      final amount = e.amount.toStringAsFixed(2);
      sb.writeln('$dateStr,$plate,$type,$desc,$amount');
    }

    return sb.toString();
  }

  String _generateTextSummary() {
    final total = widget.expenses.fold<double>(0, (s, e) => s + e.amount);
    final byType = <String, double>{};
    for (final e in widget.expenses) {
      byType[e.type] = (byType[e.type] ?? 0) + e.amount;
    }

    final sb = StringBuffer();
    sb.writeln('📊 รายงานสรุปค่าใช้จ่าย H2HFleet Telematics');
    sb.writeln('📅 วันที่ออกรายงาน: ${DateFormat('d MMMM yyyy, HH:mm', 'th_TH').format(DateTime.now())}');
    sb.writeln('-----------------------------------');
    sb.writeln('💰 ยอดรวมทั้งหมด: ฿${widget.currencyFormat.format(total)} (${widget.expenses.length} รายการ)');
    sb.writeln('-----------------------------------');
    sb.writeln('📋 แยกตามหมวดหมู่:');
    byType.forEach((type, amount) {
      final pct = (amount / total * 100).toStringAsFixed(1);
      sb.writeln('• $type: ฿${widget.currencyFormat.format(amount)} ($pct%)');
    });
    sb.writeln('-----------------------------------');
    sb.writeln('🚛 H2HFleet Fleet Intelligence System');

    return sb.toString();
  }

  Future<void> _exportCsv() async {
    final csvData = _generateCsvContent();
    final filename = 'h2hfleet_expenses_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

    if (kIsWeb) {
      downloadFile(filename, csvData, 'text/csv;charset=utf-8');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ดาวน์โหลดไฟล์ $filename สำเร็จ! ✅'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } else {
      await Clipboard.setData(ClipboardData(text: csvData));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คัดลอกข้อมูล CSV ลงคลิปบอร์ดแล้ว! สามารถนำไปเปิดใน Excel ได้'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Future<void> _copyTextSummary() async {
    final text = _generateTextSummary();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('คัดลอกรายงานสรุปแล้ว พร้อมส่งเข้า LINE / Email ✅'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _sendSummaryToLine() async {
    setState(() => _isSendingLine = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('line_user_id') ?? '';

    if (userId.isEmpty) {
      if (mounted) {
        setState(() => _isSendingLine = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยังไม่ได้ตั้งค่า LINE User ID กรุณาไปที่เมนู LINE Notify'),
            backgroundColor: Color(0xFFEA580C),
          ),
        );
      }
      return;
    }

    try {
      const supabaseUrl = 'https://rdobhvuiadmsqdfugrlp.supabase.co';
      const anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkb2JodnVpYWRtc3FkZnVncmxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNjU4MzMsImV4cCI6MjA5NDc0MTgzM30.7pvs8B38unEmBkPmP14lfgDrr59wjd-WroMiqpkIzvY';

      final dio = Dio(BaseOptions(validateStatus: (status) => true));
      final summary = _generateTextSummary();

      final res = await dio.post(
        '$supabaseUrl/functions/v1/line-push-message',
        data: jsonEncode({
          'userId': userId,
          'message': summary,
        }),
        options: Options(headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        }),
      );

      if (mounted) {
        Navigator.pop(context);
        final ok = res.statusCode == 200;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'ส่งสรุปรายงานเข้า LINE สำเร็จ! ✅' : 'LINE Error: ${res.data}'),
            backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingLine = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _exportPdfAndPrint() async {
    final prefs = await SharedPreferences.getInstance();
    final companyName = prefs.getString('company_name') ?? 'บริษัท ตัวอย่าง จำกัด (มหาชน)';
    final companyAddress = prefs.getString('company_address') ?? '–';
    final companyTaxId = prefs.getString('company_tax_id') ?? '–';
    final companyPhone = prefs.getString('company_phone') ?? '–';

    final total = widget.expenses.fold<double>(0, (s, e) => s + e.amount);
    final fuelTotal = widget.expenses
        .where((e) => e.type == 'น้ำมัน')
        .fold<double>(0, (s, e) => s + e.amount);
    final maintTotal = widget.expenses
        .where((e) => e.type == 'ซ่อมบำรุง' || e.type == 'ซ่อม' || e.type == 'ยาง')
        .fold<double>(0, (s, e) => s + e.amount);
    final otherTotal = total - (fuelTotal + maintTotal);

    final sorted = List<ExpenseModel>.from(widget.expenses)
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    final rowsHtml = StringBuffer();
    for (int i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      final dateStr = DateFormat('dd/MM/yyyy').format(e.expenseDate);
      final plate = widget.vehicleMap[e.vehicleId]?.plateNumber ?? '–';
      final type = e.type;
      final note = e.note ?? '–';
      final amt = widget.currencyFormat.format(e.amount);

      rowsHtml.writeln('''
        <tr style="background-color: ${i % 2 == 0 ? '#ffffff' : '#f8fafc'};">
          <td style="padding: 8px 10px; border-bottom: 1px solid #e2e8f0; text-align: center;">${i + 1}</td>
          <td style="padding: 8px 10px; border-bottom: 1px solid #e2e8f0;">$dateStr</td>
          <td style="padding: 8px 10px; border-bottom: 1px solid #e2e8f0; font-weight: 600;">$plate</td>
          <td style="padding: 8px 10px; border-bottom: 1px solid #e2e8f0;"><span style="background: #f1f5f9; padding: 2px 6px; border-radius: 4px; font-size: 12px;">$type</span></td>
          <td style="padding: 8px 10px; border-bottom: 1px solid #e2e8f0; color: #475569;">$note</td>
          <td style="padding: 8px 10px; border-bottom: 1px solid #e2e8f0; text-align: right; font-weight: 700;">฿$amt</td>
        </tr>
      ''');
    }

    final printHtml = '''
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <title>รายงานค่าใช้จ่าย H2HFleet - $companyName</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Sarabun:wght@400;600;700;800&display=swap');
    body {
      font-family: 'Sarabun', -apple-system, sans-serif;
      margin: 0;
      padding: 24px;
      color: #0f172a;
      background: #ffffff;
      font-size: 13px;
      line-height: 1.4;
    }
    .header-table {
      width: 100%;
      margin-bottom: 20px;
      border-bottom: 2px solid #0f172a;
      padding-bottom: 14px;
    }
    .company-title {
      font-size: 20px;
      font-weight: 800;
      color: #0f172a;
      margin-bottom: 4px;
    }
    .doc-title {
      font-size: 18px;
      font-weight: 800;
      color: #1e3a8a;
      text-align: right;
    }
    .kpi-grid {
      display: flex;
      gap: 12px;
      margin-bottom: 20px;
    }
    .kpi-box {
      flex: 1;
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 10px 14px;
    }
    .kpi-label {
      font-size: 11px;
      color: #64748b;
      font-weight: 600;
      text-transform: uppercase;
    }
    .kpi-value {
      font-size: 17px;
      font-weight: 800;
      color: #0f172a;
      margin-top: 2px;
    }
    table.data-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 28px;
    }
    table.data-table th {
      background: #0f172a;
      color: #ffffff;
      font-weight: 700;
      padding: 8px 10px;
      text-align: left;
      font-size: 12px;
    }
    .signatures {
      display: flex;
      justify-content: space-between;
      margin-top: 40px;
      page-break-inside: avoid;
    }
    .sig-col {
      width: 45%;
      text-align: center;
    }
    .sig-line {
      border-bottom: 1px dotted #94a3b8;
      margin-bottom: 8px;
      height: 40px;
    }
    @media print {
      body { padding: 0; }
      @page { size: A4; margin: 15mm; }
    }
  </style>
</head>
<body>
  <table class="header-table">
    <tr>
      <td style="vertical-align: top;">
        <div class="company-title">$companyName</div>
        <div style="color: #475569; font-size: 12px;">$companyAddress</div>
        <div style="color: #475569; font-size: 12px;">เลขประจำตัวผู้เสียภาษี: <strong>$companyTaxId</strong> | โทร: $companyPhone</div>
      </td>
      <td style="vertical-align: top; text-align: right;">
        <div class="doc-title">ใบสรุปรายงานค่าใช้จ่ายกองรถ</div>
        <div style="font-size: 12px; color: #64748b; margin-top: 4px;">Fleet Telematics Expense Report</div>
        <div style="font-size: 12px; color: #0f172a; font-weight: 700; margin-top: 6px;">วันที่พิมพ์: ${DateFormat('d MMMM yyyy, HH:mm', 'th_TH').format(DateTime.now())}</div>
      </td>
    </tr>
  </table>

  <div class="kpi-grid">
    <div class="kpi-box" style="border-left: 4px solid #10b981;">
      <div class="kpi-label">ยอดรวมค่าใช้จ่ายทั้งหมด</div>
      <div class="kpi-value" style="color: #059669;">฿${widget.currencyFormat.format(total)}</div>
    </div>
    <div class="kpi-box" style="border-left: 4px solid #e11d48;">
      <div class="kpi-label">ค่าน้ำมัน (Fuel)</div>
      <div class="kpi-value" style="color: #e11d48;">฿${widget.currencyFormat.format(fuelTotal)}</div>
    </div>
    <div class="kpi-box" style="border-left: 4px solid #d97706;">
      <div class="kpi-label">ค่าซ่อมบำรุง & ยาง</div>
      <div class="kpi-value" style="color: #d97706;">฿${widget.currencyFormat.format(maintTotal)}</div>
    </div>
    <div class="kpi-box" style="border-left: 4px solid #4f46e5;">
      <div class="kpi-label">ค่าเที่ยว & อื่นๆ</div>
      <div class="kpi-value" style="color: #4f46e5;">฿${widget.currencyFormat.format(otherTotal)}</div>
    </div>
  </div>

  <table class="data-table">
    <thead>
      <tr>
        <th style="width: 40px; text-align: center;">#</th>
        <th style="width: 90px;">วันที่</th>
        <th style="width: 110px;">ทะเบียนรถ</th>
        <th style="width: 130px;">หมวดหมู่</th>
        <th>รายละเอียด / หมายเหตุ</th>
        <th style="width: 120px; text-align: right;">จำนวนเงิน</th>
      </tr>
    </thead>
    <tbody>
      ${rowsHtml.toString()}
    </tbody>
    <tfoot>
      <tr style="background: #f1f5f9; font-weight: 800;">
        <td colspan="5" style="padding: 10px; text-align: right; border-top: 2px solid #cbd5e1;">ยอดรวมสุทธิ (${widget.expenses.length} รายการ):</td>
        <td style="padding: 10px; text-align: right; border-top: 2px solid #cbd5e1; font-size: 15px; color: #0f172a;">฿${widget.currencyFormat.format(total)}</td>
      </tr>
    </tfoot>
  </table>

  <div class="signatures">
    <div class="sig-col">
      <div class="sig-line"></div>
      <div style="font-weight: 700;">( ........................................................... )</div>
      <div style="color: #64748b; font-size: 11.5px; margin-top: 2px;">ผู้จัดทำรายงาน / เจ้าหน้าที่ฟลีต</div>
      <div style="color: #94a3b8; font-size: 11px;">วันที่: ......./......./............</div>
    </div>
    <div class="sig-col">
      <div class="sig-line"></div>
      <div style="font-weight: 700;">( ........................................................... )</div>
      <div style="color: #64748b; font-size: 11.5px; margin-top: 2px;">ผู้จัดการฝ่ายขนส่ง / ผู้มีอำนาจลงนาม</div>
      <div style="color: #94a3b8; font-size: 11px;">วันที่: ......./......./............</div>
    </div>
  </div>
</body>
</html>
    ''';

    if (kIsWeb) {
      printHtmlReport(printHtml);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เปิดหน้าต่างสั่งพิมพ์ / บันทึกเป็น PDF สำเร็จ! 🖨️📄'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } else {
      final filename = 'h2hfleet_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.html';
      downloadFile(filename, printHtml, 'text/html;charset=utf-8');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งออกเอกสารรายงาน HTML/PDF สำเร็จ!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.expenses.fold<double>(0, (s, e) => s + e.amount);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.file_download_rounded, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ส่งออกรายงาน (Export Report)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'รวม ${widget.expenses.length} รายการ · ฿${widget.currencyFormat.format(total)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Company Header Banner with Quick Edit Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Color(0xFF1E3A8A), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'หัวบิลรายงาน · เลขผู้เสียภาษี: $_companyTaxId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
                      );
                      _loadCompanyInfo();
                    },
                    icon: const Icon(Icons.edit_rounded, size: 13, color: Color(0xFF0284C7)),
                    label: const Text(
                      'แก้ไขหัวบิล',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Option 1: PDF Print
            _ExportOptionTile(
              icon: Icons.picture_as_pdf_rounded,
              color: const Color(0xFFE11D48),
              title: 'พิมพ์เอกสาร / บันทึกเป็น PDF (Print & PDF)',
              subtitle: 'ฟอร์มเอกสารแบบทางการ มีหัวบิลบริษัท ตารางสรุป และช่องเซ็น',
              onTap: _exportPdfAndPrint,
            ),

            const SizedBox(height: 10),

            // Option 2: Excel CSV
            _ExportOptionTile(
              icon: Icons.table_view_rounded,
              color: const Color(0xFF059669),
              title: 'ดาวน์โหลดไฟล์ CSV (Excel / Sheets)',
              subtitle: 'ตารางข้อมูลพร้อมเปิดใน Excel ไม่เป็นภาษาต่างดาว',
              onTap: _exportCsv,
            ),

            const SizedBox(height: 10),

            // Option 3: Copy Text Report
            _ExportOptionTile(
              icon: Icons.copy_rounded,
              color: const Color(0xFF4F46E5),
              title: 'คัดลอกรายงานสรุป (Copy Text)',
              subtitle: 'ข้อความจัดหมวดหมู่ สำหรับส่ง Email หรือทำบัญชี',
              onTap: _copyTextSummary,
            ),

            const SizedBox(height: 10),

            // Option 4: Send to LINE
            _ExportOptionTile(
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFF06C755),
              title: 'ส่งสรุปรายงานเข้า LINE Bot',
              subtitle: _isSendingLine ? 'กำลังส่งข้อมูล...' : 'ส่งสรุปค่าใช้จ่ายเข้า LINE ทันที',
              isLoading: _isSendingLine,
              onTap: _isSendingLine ? null : _sendSummaryToLine,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: color),
                      )
                    : Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────
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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFFE11D48)),
            ),
            const SizedBox(height: 18),
            const Text(
              'ยังไม่มีประวัติค่าใช้จ่าย',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'เริ่มต้นบันทึกค่าน้ำมัน ค่าซ่อมบำรุง หรือค่าเที่ยวรถ\nเพื่อนำมาวิเคราะห์และส่งออกรายงาน',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('บันทึกค่าใช้จ่ายแรก'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
