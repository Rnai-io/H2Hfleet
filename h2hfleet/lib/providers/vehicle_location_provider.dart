import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_location_model.dart';
import '../services/supabase_service.dart';

// Provider สำหรับ live locations ของรถทั้งหมดใน company
final vehicleLocationsProvider = StateNotifierProvider<
    VehicleLocationsNotifier, AsyncValue<List<VehicleLocationModel>>>((ref) {
  return VehicleLocationsNotifier();
});

class VehicleLocationsNotifier
    extends StateNotifier<AsyncValue<List<VehicleLocationModel>>> {
  final _supabase = SupabaseService();
  RealtimeChannel? _channel;

  VehicleLocationsNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _fetchLocations();
    _subscribeRealtime();
  }

  Future<void> _fetchLocations() async {
    try {
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

      // ดึง vehicle IDs ใน company ก่อน
      final vehicleRows = await _supabase.client
          .from('vehicles')
          .select('id')
          .eq('company_id', companyId);

      final vehicleIds = (vehicleRows as List)
          .map((v) => v['id'] as String)
          .toList();

      if (vehicleIds.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      // ดึง current locations ของรถเหล่านั้น
      final rows = await _supabase.client
          .from('vehicle_current_location')
          .select()
          .inFilter('vehicle_id', vehicleIds);

      final locations = (rows as List)
          .map((r) => VehicleLocationModel.fromJson(r))
          .toList();

      state = AsyncValue.data(locations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    _channel = _supabase.client
        .channel('vehicle_current_location')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vehicle_current_location',
          callback: (payload) {
            _fetchLocations();
          },
        )
        .subscribe();
  }

  Future<void> refresh() => _fetchLocations();

  // บันทึก location จาก simulator (สำหรับ test)
  Future<void> simulateLocation({
    required String vehicleId,
    required double lat,
    required double lng,
    double speed = 0,
  }) async {
    try {
      await _supabase.client.from('vehicle_current_location').upsert({
        'vehicle_id': vehicleId,
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'vehicle_id');
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
