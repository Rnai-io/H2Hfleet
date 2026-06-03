import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_location_model.dart';
import '../services/supabase_service.dart';

final driverLocationsProvider = StateNotifierProvider<
    DriverLocationsNotifier, AsyncValue<List<DriverLocationModel>>>((ref) {
  return DriverLocationsNotifier();
});

class DriverLocationsNotifier
    extends StateNotifier<AsyncValue<List<DriverLocationModel>>> {
  final _supabase = SupabaseService();
  RealtimeChannel? _channel;

  DriverLocationsNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _fetch();
    _subscribeRealtime();
  }

  Future<void> _fetch() async {
    try {
      final user = _supabase.getCurrentUser();
      if (user == null) { state = const AsyncValue.data([]); return; }

      final userRow = await _supabase.client
          .from('users').select('company_id')
          .eq('id', user.id).maybeSingle();
      if (userRow == null) { state = const AsyncValue.data([]); return; }

      final companyId = userRow['company_id'] as String;

      // ดึง vehicle IDs ใน company
      final vehicleRows = await _supabase.client
          .from('vehicles').select('id').eq('company_id', companyId);
      final vehicleIds = (vehicleRows as List).map((v) => v['id'] as String).toList();
      if (vehicleIds.isEmpty) { state = const AsyncValue.data([]); return; }

      final rows = await _supabase.client
          .from('driver_locations').select().inFilter('vehicle_id', vehicleIds);

      state = AsyncValue.data(
        (rows as List).map((r) => DriverLocationModel.fromJson(r)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    _channel = _supabase.client
        .channel('driver_locations_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'driver_locations',
          callback: (_) => _fetch(),
        )
        .subscribe();
  }

  Future<void> refresh() => _fetch();

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
