import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance_model.dart';
import '../services/supabase_service.dart';

final maintenanceProvider =
    StateNotifierProvider<MaintenanceNotifier, AsyncValue<List<MaintenanceModel>>>((ref) {
  return MaintenanceNotifier();
});

class MaintenanceNotifier extends StateNotifier<AsyncValue<List<MaintenanceModel>>> {
  final _supabase = SupabaseService();

  MaintenanceNotifier() : super(const AsyncValue.loading()) {
    fetchMaintenance();
  }

  Future<void> fetchMaintenance() async {
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

      final records = await _supabase.client
          .from('maintenance')
          .select()
          .inFilter('vehicle_id', vehicleIds)
          .order('created_at', ascending: false);

      state = AsyncValue.data(
        (records as List).map((r) => MaintenanceModel.fromJson(r)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> uploadPhoto(File file, String vehicleId) async {
    try {
      final fileName =
          '$vehicleId/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      await _supabase.client.storage.from('maintenance-photos').upload(fileName, file);
      return _supabase.client.storage.from('maintenance-photos').getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }

  Future<void> addMaintenance({
    required String vehicleId,
    required String type,
    required String partCategory,
    String? partName,
    String? description,
    double cost = 0,
    String? photoUrl,
    DateTime? dueDate,
    int? dueKm,
    String status = 'pending',
  }) async {
    try {
      await _supabase.client.from('maintenance').insert({
        'vehicle_id': vehicleId,
        'type': type,
        'part_category': partCategory,
        if (partName != null && partName.isNotEmpty) 'part_name': partName,
        if (description != null && description.isNotEmpty) 'description': description,
        'cost': cost,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (dueDate != null) 'due_date': dueDate.toIso8601String().split('T').first,
        if (dueKm != null) 'due_km': dueKm,
        'status': status,
      });
      await fetchMaintenance();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markCompleted(String id) async {
    try {
      await _supabase.client.from('maintenance').update({
        'status': 'completed',
        'completed_date': DateTime.now().toIso8601String().split('T').first,
      }).eq('id', id);
      await fetchMaintenance();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMaintenance(String id) async {
    try {
      await _supabase.client.from('maintenance').delete().eq('id', id);
      await fetchMaintenance();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
