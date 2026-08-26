import 'package:flutter/foundation.dart';
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
      List<dynamic> rows = [];
      try {
        rows = await _supabase.client
            .from('vehicle_current_location')
            .select()
            .inFilter('vehicle_id', vehicleIds);
      } catch (e) {
        debugPrint('vehicle_current_location select error: $e');
      }

      final existingMap = <String, VehicleLocationModel>{};
      for (final r in rows) {
        final loc = VehicleLocationModel.fromJson(r);
        existingMap[loc.vehicleId] = loc;
      }

      // ตรวจสอบรถทุกคัน หากยังไม่มีพิกัดใน DB ให้กำหนดพิกัดเริ่มต้นศูนย์กระจายสินค้า
      final allLocations = <VehicleLocationModel>[];
      for (int i = 0; i < vehicleIds.length; i++) {
        final vId = vehicleIds[i];
        if (existingMap.containsKey(vId)) {
          allLocations.add(existingMap[vId]!);
        } else {
          // พิกัดศูนย์กระจายสินค้าภาคกลางและจุดยุทธศาสตร์ (กระจายตำแหน่งไม่ให้ทับกัน)
          final defaultLat = 13.8200 + ((i % 4) * 0.035) - 0.04;
          final defaultLng = 100.5800 + ((i ~/ 4) * 0.045) - 0.02;
          final fallbackLoc = VehicleLocationModel(
            id: 'init_$vId',
            vehicleId: vId,
            lat: defaultLat,
            lng: defaultLng,
            speed: 0,
            heading: (i * 45).toDouble(),
            updatedAt: DateTime.now(),
          );
          allLocations.add(fallbackLoc);

          // บันทึกพิกัดเริ่มต้นลง DB ใน background
          _supabase.client.from('vehicle_current_location').upsert({
            'vehicle_id': vId,
            'lat': defaultLat,
            'lng': defaultLng,
            'speed': 0,
            'heading': (i * 45).toDouble(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'vehicle_id').then((_) {}).catchError((_) {});
        }
      }

      state = AsyncValue.data(allLocations);
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
