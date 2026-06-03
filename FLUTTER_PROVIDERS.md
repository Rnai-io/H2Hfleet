# H2HFleet Riverpod Providers

## Core Providers Setup

### `lib/providers/auth_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(ref);
});

class AuthRepository {
  final Ref _ref;

  AuthRepository(this._ref);

  final _supabase = SupabaseService();

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Fetch user profile from users table
        final user = await _supabase.client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(user);
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
    return null;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String companyName,
  }) async {
    try {
      // 1. Create auth user
      final response = await _supabase.client.auth.signUpWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // 2. Create company
        final company = await _supabase.client
            .from('companies')
            .insert({
              'name': companyName,
              'plan': 'free',
            })
            .select()
            .single();

        // 3. Create user profile
        await _supabase.client.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'name': name,
          'company_id': company['id'],
          'role': 'owner',
        });

        return true;
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
    return false;
  }

  Future<void> logout() async {
    await _supabase.client.auth.signOut();
  }

  User? getCurrentUser() {
    return _supabase.getCurrentUser();
  }
}
```

### `lib/providers/vehicles_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_model.dart';
import '../services/supabase_service.dart';

final vehiclesProvider =
    StateNotifierProvider<VehiclesNotifier, AsyncValue<List<VehicleModel>>>((ref) {
  return VehiclesNotifier(ref);
});

class VehiclesNotifier extends StateNotifier<AsyncValue<List<VehicleModel>>> {
  final Ref _ref;
  final _supabase = SupabaseService();

  VehiclesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      state = const AsyncValue.loading();

      final user = _supabase.getCurrentUser();
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Get user's company_id
      final userRecord = await _supabase.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final companyId = userRecord['company_id'];

      // Fetch vehicles
      final vehicles = await _supabase.client
          .from('vehicles')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      final vehicleModels =
          (vehicles as List).map((v) => VehicleModel.fromJson(v)).toList();

      state = AsyncValue.data(vehicleModels);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addVehicle({
    required String plateNumber,
    required String vehicleType,
    required String brand,
    required String model,
    required int year,
    required String fuelType,
  }) async {
    try {
      final user = _supabase.getCurrentUser();
      if (user == null) return;

      // Get company_id
      final userRecord = await _supabase.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final companyId = userRecord['company_id'];

      // Add vehicle
      await _supabase.client.from('vehicles').insert({
        'company_id': companyId,
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
        'brand': brand,
        'model': model,
        'year': year,
        'fuel_type': fuelType,
        'status': 'active',
      });

      // Refresh list
      await _fetchVehicles();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
```

### `lib/providers/expenses_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../models/vehicle_model.dart';
import '../services/supabase_service.dart';
import 'vehicles_provider.dart';

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, AsyncValue<List<ExpenseModel>>>((ref) {
  return ExpensesNotifier(ref);
});

final expenseSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final expenses = ref.watch(expensesProvider);
  final vehicles = ref.watch(vehiclesProvider);

  return expenses.when(
    data: (expenseList) {
      final summary = <String, double>{};

      for (final expense in expenseList) {
        final key = expense.vehicleId;
        summary[key] = (summary[key] ?? 0) + expense.amount;
      }

      return summary;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  final Ref _ref;
  final _supabase = SupabaseService();

  ExpensesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      state = const AsyncValue.loading();

      final user = _supabase.getCurrentUser();
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Get user's company_id
      final userRecord = await _supabase.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final companyId = userRecord['company_id'];

      // Get all vehicles for this company
      final vehicles = await _supabase.client
          .from('vehicles')
          .select()
          .eq('company_id', companyId);

      final vehicleIds = (vehicles as List).map((v) => v['id']).toList();

      if (vehicleIds.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      // Fetch expenses for all vehicles
      final expenses = await _supabase.client
          .from('expenses')
          .select()
          .inFilter('vehicle_id', vehicleIds)
          .order('expense_date', ascending: false);

      final expenseModels =
          (expenses as List).map((e) => ExpenseModel.fromJson(e)).toList();

      state = AsyncValue.data(expenseModels);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
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
        'expense_date': expenseDate.toIso8601String(),
        'note': note,
      });

      // Refresh list
      await _fetchExpenses();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
```

### `lib/providers/ai_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/openai_service.dart';
import 'expenses_provider.dart';

final aiSummaryProvider = FutureProvider<String>((ref) async {
  final expenses = ref.watch(expensesProvider);

  return expenses.when(
    data: (expenseList) async {
      if (expenseList.isEmpty) {
        return 'ยังไม่มีข้อมูลค่าใช้จ่ายสำหรับวันนี้';
      }

      // Get today's expenses
      final today = DateTime.now();
      final todayExpenses = expenseList.where((e) {
        return e.expenseDate.year == today.year &&
            e.expenseDate.month == today.month &&
            e.expenseDate.day == today.day;
      }).toList();

      if (todayExpenses.isEmpty) {
        return 'ยังไม่มีค่าใช้จ่ายสำหรับวันนี้';
      }

      // Group by type
      final byType = <String, double>{};
      for (final expense in todayExpenses) {
        byType[expense.type] = (byType[expense.type] ?? 0) + expense.amount;
      }

      final totalSpent = todayExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );

      // Generate summary using OpenAI
      final aiService = OpenAIService();
      final summary = await aiService.generateFleetSummary(
        totalSpent: totalSpent,
        expenses: byType,
        vehicleCount: 1, // TODO: Get actual vehicle count
      );

      return summary;
    },
    loading: () => 'กำลังดึงข้อมูล...',
    error: (error, _) => 'เกิดข้อผิดพลาด: $error',
  );
});
```

### `lib/services/openai_service.dart`

```dart
import 'package:dio/dio.dart';

class OpenAIService {
  final _dio = Dio();
  final _apiKey = 'YOUR_OPENAI_API_KEY'; // Move to .env later

  Future<String> generateFleetSummary({
    required double totalSpent,
    required Map<String, double> expenses,
    required int vehicleCount,
  }) async {
    try {
      final prompt = _buildPrompt(
        totalSpent: totalSpent,
        expenses: expenses,
        vehicleCount: vehicleCount,
      );

      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a fleet manager AI assistant. Respond in Thai.',
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        },
      );

      final message = response.data['choices'][0]['message']['content'];
      return message.toString().trim();
    } catch (e) {
      return 'ไม่สามารถสร้างสรุปได้: $e';
    }
  }

  String _buildPrompt({
    required double totalSpent,
    required Map<String, double> expenses,
    required int vehicleCount,
  }) {
    final expenseList = expenses.entries
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)} บาท')
        .join(', ');

    return '''
วันนี้รถ $vehicleCount คันใช้จ่ายทั้งหมด $totalSpent บาท
รายละเอียด: $expenseList

สร้างสรุปสั้นๆ (ไม่เกิน 50 คำ) แบบเจ้าของกิจการเข้าใจง่าย
ถ้ามีปัญหา ให้บอกสำหรับแนวทางตรวจสอบ
''';
  }
}
```

---

## Usage in Screens

### Example: Expense Screen Using Providers

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final summaryAsync = ref.watch(expenseSummaryProvider);

    return Scaffold(
      body: expensesAsync.when(
        data: (expenses) {
          return ListView(
            children: [
              // AI Summary
              summaryAsync.when(
                data: (summary) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(summary),
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              // Expenses list
              ...expenses.map((e) => ListTile(
                title: Text(e.type),
                subtitle: Text(e.expenseDate.toString()),
                trailing: Text('${e.amount} บาท'),
              )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
```

---

## Next Steps

1. Create `repositories/` directory with data access logic
2. Implement error handling + retry logic
3. Add offline support (local_storage)
4. Add analytics tracking

See `DEPLOYMENT.md` for Supabase connection details.
