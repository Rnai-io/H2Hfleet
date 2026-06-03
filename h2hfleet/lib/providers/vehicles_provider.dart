import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_model.dart';
import '../services/supabase_service.dart';

final vehiclesProvider =
    StateNotifierProvider<VehiclesNotifier, AsyncValue<List<VehicleModel>>>((ref) {
  return VehiclesNotifier();
});

class VehiclesNotifier extends StateNotifier<AsyncValue<List<VehicleModel>>> {
  final _supabase = SupabaseService();

  VehiclesNotifier() : super(const AsyncValue.loading()) {
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    try {
      state = const AsyncValue.loading();

      final user = _supabase.getCurrentUser();
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // maybeSingle() ไม่ throw เมื่อไม่พบ row
      final userRow = await _supabase.client
          .from('users')
          .select('company_id')
          .eq('id', user.id)
          .maybeSingle();

      if (userRow == null) {
        // User profile ยังไม่มีใน DB (อาจ register ไม่สมบูรณ์)
        state = const AsyncValue.data([]);
        return;
      }

      final companyId = userRow['company_id'] as String;

      final vehicles = await _supabase.client
          .from('vehicles')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      state = AsyncValue.data(
        (vehicles as List).map((v) => VehicleModel.fromJson(v)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addVehicle({
    required String plateNumber,
    String? nickName,
    required String vehicleType,
    required String brand,
    required String model,
    required int year,
    required String fuelType,
    String? remark,
  }) async {
    try {
      final user = _supabase.getCurrentUser();
      if (user == null) return;

      final userRow = await _supabase.client
          .from('users')
          .select('company_id')
          .eq('id', user.id)
          .maybeSingle();

      if (userRow == null) return;

      // payload หลัก (columns ที่มีแน่นอนใน DB)
      final basePayload = <String, dynamic>{
        'company_id': userRow['company_id'],
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
        'brand': brand,
        'model': model,
        'year': year,
        'fuel_type': fuelType,
        'status': 'active',
      };

      // ลอง insert พร้อม optional fields ก่อน
      // ถ้า PGRST204 (column ยังไม่มี) → retry ด้วย base payload เท่านั้น
      try {
        final fullPayload = {
          ...basePayload,
          if (nickName != null && nickName.isNotEmpty) 'nick_name': nickName,
          if (remark != null && remark.isNotEmpty) 'remark': remark,
        };
        await _supabase.client.from('vehicles').insert(fullPayload);
      } catch (insertErr) {
        final errStr = insertErr.toString();
        if (errStr.contains('PGRST204') ||
            errStr.contains('schema cache') ||
            errStr.contains('Could not find')) {
          // column ยังไม่มีใน DB → insert แค่ core fields
          await _supabase.client.from('vehicles').insert(basePayload);
        } else {
          rethrow;
        }
      }

      await fetchVehicles();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      // ลบ expenses ที่เชื่อมกับรถก่อน (แก้ FK violation 23503)
      await _supabase.client
          .from('expenses')
          .delete()
          .eq('vehicle_id', vehicleId);

      // แล้วค่อยลบรถ
      await _supabase.client
          .from('vehicles')
          .delete()
          .eq('id', vehicleId);

      await fetchVehicles();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateVehicle({
    required String vehicleId,
    required String plateNumber,
    String? nickName,
    required String vehicleType,
    required String brand,
    required String model,
    required int year,
    required String fuelType,
    required String status,
    String? remark,
  }) async {
    try {
      // core payload — columns ที่มีแน่นอนใน DB
      final basePayload = <String, dynamic>{
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
        'brand': brand,
        'model': model,
        'year': year,
        'fuel_type': fuelType,
        'status': status,
      };

      // ลอง update พร้อม optional columns ก่อน
      // ถ้า PGRST204 → retry ด้วย base payload เท่านั้น
      try {
        final fullPayload = {
          ...basePayload,
          if (nickName != null && nickName.isNotEmpty) 'nick_name': nickName,
          'remark': (remark != null && remark.isNotEmpty) ? remark : null,
        };
        await _supabase.client
            .from('vehicles')
            .update(fullPayload)
            .eq('id', vehicleId);
      } catch (updateErr) {
        final errStr = updateErr.toString();
        if (errStr.contains('PGRST204') ||
            errStr.contains('schema cache') ||
            errStr.contains('Could not find')) {
          // column ยังไม่มีใน DB → update แค่ core fields
          await _supabase.client
              .from('vehicles')
              .update(basePayload)
              .eq('id', vehicleId);
        } else {
          rethrow;
        }
      }

      await fetchVehicles();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
