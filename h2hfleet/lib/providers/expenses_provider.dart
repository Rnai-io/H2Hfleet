import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/supabase_service.dart';

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, AsyncValue<List<ExpenseModel>>>((ref) {
  return ExpensesNotifier();
});

final expenseSummaryProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(expensesProvider).when(
    data: (expenses) {
      final summary = <String, double>{};
      for (final e in expenses) {
        summary[e.vehicleId] = (summary[e.vehicleId] ?? 0) + e.amount;
      }
      return summary;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  final _supabase = SupabaseService();

  ExpensesNotifier() : super(const AsyncValue.loading()) {
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    try {
      state = const AsyncValue.loading();

      final user = _supabase.getCurrentUser();
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final userRow = await _supabase.client
          .from('users')
          .select('company_id')
          .eq('id', user.id)
          .maybeSingle();

      if (userRow == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final companyId = userRow['company_id'] as String;

      final vehicles = await _supabase.client
          .from('vehicles')
          .select('id')
          .eq('company_id', companyId);

      final vehicleIds = (vehicles as List).map((v) => v['id'] as String).toList();

      if (vehicleIds.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      final expenses = await _supabase.client
          .from('expenses')
          .select()
          .inFilter('vehicle_id', vehicleIds)
          .order('expense_date', ascending: false);

      state = AsyncValue.data(
        (expenses as List).map((e) => ExpenseModel.fromJson(e)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense({
    required String vehicleId,
    required String type,
    required double amount,
    required DateTime expenseDate,
    String? note,
  }) async {
    try {
      await _supabase.client.from('expenses').insert({
        'vehicle_id': vehicleId,
        'type': type,
        'amount': amount,
        'expense_date': expenseDate.toIso8601String().split('T').first,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      await fetchExpenses();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
