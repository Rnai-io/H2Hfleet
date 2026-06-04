import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gemini_service.dart';
import 'expenses_provider.dart';
import 'vehicles_provider.dart';

final aiSummaryProvider = FutureProvider<String>((ref) async {
  final expensesAsync = ref.watch(expensesProvider);
  final vehiclesAsync = ref.watch(vehiclesProvider);

  final vehicleCount = vehiclesAsync.when(
    data: (v) => v.length,
    loading: () => 0,
    error: (_, __) => 0,
  );

  // รอข้อมูล expenses ก่อน
  if (expensesAsync.isLoading) return 'กำลังดึงข้อมูล...';
  if (expensesAsync.hasError) return 'เกิดข้อผิดพลาด ลองใหม่อีกครั้ง';

  final expenseList = expensesAsync.valueOrNull ?? [];

  // กรองเฉพาะค่าใช้จ่ายวันนี้
  final today = DateTime.now();
  final todayExpenses = expenseList.where((e) =>
      e.expenseDate.year == today.year &&
      e.expenseDate.month == today.month &&
      e.expenseDate.day == today.day).toList();

  // จัดกลุ่มตามประเภท
  final byType = <String, double>{};
  for (final expense in todayExpenses) {
    byType[expense.type] = (byType[expense.type] ?? 0) + expense.amount;
  }

  final totalSpent = todayExpenses.fold<double>(0, (sum, e) => sum + e.amount);

  // เรียก Gemini AI (รวมกรณีไม่มีค่าใช้จ่ายวันนี้ → ให้ tip ประจำวัน)
  return GeminiService().generateFleetSummary(
    totalSpent: totalSpent,
    expenses: byType,
    vehicleCount: vehicleCount,
  );
});
