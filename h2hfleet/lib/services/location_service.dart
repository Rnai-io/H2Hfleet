import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'supabase_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  LocationService._internal();
  factory LocationService() => _instance;

  Timer? _timer;
  bool _isTracking = false;
  String? _vehicleId;
  Position? lastPosition;

  bool get isTracking => _isTracking;
  String? get vehicleId => _vehicleId;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<bool> startTracking(String vehicleId) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return false;

    _vehicleId = vehicleId;
    _isTracking = true;

    await _sendLocation();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _sendLocation());
    return true;
  }

  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    _isTracking = false;

    // ลบ driver location เมื่อหยุดเดินทาง (ไม่ให้ค้างบนแผนที่)
    if (_vehicleId != null) {
      try {
        await SupabaseService().client
            .from('driver_locations')
            .delete()
            .eq('vehicle_id', _vehicleId!);
      } catch (_) {}
    }
    _vehicleId = null;
  }

  Future<void> _sendLocation() async {
    if (_vehicleId == null) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      lastPosition = position;

      final client = SupabaseService().client;
      final userId = client.auth.currentUser?.id;
      final now = DateTime.now().toUtc().toIso8601String();
      final speed = (position.speed * 3.6).clamp(0, 300).toDouble();

      // 1. บันทึก GPS log (ประวัติ)
      await client.from('gps_logs').insert({
        'vehicle_id': _vehicleId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': speed,
        'recorded_at': now,
      });

      // 2. อัปเดต driver_locations (แยกจาก vehicle_current_location)
      await client.from('driver_locations').upsert({
        'vehicle_id': _vehicleId,
        'user_id': userId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': speed,
        'heading': position.heading,
        'updated_at': now,
      }, onConflict: 'vehicle_id');
    } catch (_) {}
  }

  Future<void> sendNow() => _sendLocation();
}
