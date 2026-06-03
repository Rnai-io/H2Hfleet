import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gps_log_model.dart';
import '../services/supabase_service.dart';

// Parameters สำหรับ query route history
class RouteQuery {
  final String vehicleId;
  final DateTime date;
  RouteQuery({required this.vehicleId, required this.date});
}

final routeQueryProvider = StateProvider<RouteQuery?>((ref) => null);

final gpsLogsProvider =
    FutureProvider.family<List<GpsLogModel>, RouteQuery>((ref, query) async {
  final start = DateTime(query.date.year, query.date.month, query.date.day);
  final end = start.add(const Duration(days: 1));

  final rows = await SupabaseService().client
      .from('gps_logs')
      .select()
      .eq('vehicle_id', query.vehicleId)
      .gte('recorded_at', start.toUtc().toIso8601String())
      .lt('recorded_at', end.toUtc().toIso8601String())
      .order('recorded_at', ascending: true);

  return (rows as List).map((r) => GpsLogModel.fromJson(r)).toList();
});

// Analytics คำนวณจาก gps_logs
class RouteAnalytics {
  final double distanceKm;
  final double maxSpeed;
  final double avgSpeed;
  final int movingMinutes;
  final int idleMinutes;
  final int totalPoints;

  RouteAnalytics({
    required this.distanceKm,
    required this.maxSpeed,
    required this.avgSpeed,
    required this.movingMinutes,
    required this.idleMinutes,
    required this.totalPoints,
  });
}

RouteAnalytics computeAnalytics(List<GpsLogModel> logs) {
  if (logs.isEmpty) {
    return RouteAnalytics(
        distanceKm: 0, maxSpeed: 0, avgSpeed: 0,
        movingMinutes: 0, idleMinutes: 0, totalPoints: 0);
  }

  double distKm = 0;
  double maxSpeed = 0;
  double totalSpeed = 0;
  int movingSec = 0;
  int idleSec = 0;

  for (int i = 0; i < logs.length; i++) {
    final log = logs[i];
    if (log.speed > maxSpeed) maxSpeed = log.speed;
    totalSpeed += log.speed;

    if (i > 0) {
      final prev = logs[i - 1];
      final intervalSec =
          log.recordedAt.difference(prev.recordedAt).inSeconds.abs();

      // ระยะทาง Haversine
      distKm += _haversineKm(prev.lat, prev.lng, log.lat, log.lng);

      if (log.speed > 5) {
        movingSec += intervalSec;
      } else {
        idleSec += intervalSec;
      }
    }
  }

  return RouteAnalytics(
    distanceKm: distKm,
    maxSpeed: maxSpeed,
    avgSpeed: logs.isNotEmpty ? totalSpeed / logs.length : 0,
    movingMinutes: movingSec ~/ 60,
    idleMinutes: idleSec ~/ 60,
    totalPoints: logs.length,
  );
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _deg2rad(double deg) => deg * pi / 180;
