import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicles_provider.dart';
import '../../services/location_service.dart';

class DriverModeScreen extends ConsumerStatefulWidget {
  const DriverModeScreen({super.key});

  @override
  ConsumerState<DriverModeScreen> createState() => _DriverModeScreenState();
}

class _DriverModeScreenState extends ConsumerState<DriverModeScreen> {
  final _locationService = LocationService();
  VehicleModel? _selectedVehicle;
  bool _isTracking = false;
  String _statusText = 'กดเริ่มเดินทางเพื่อส่ง GPS';
  DateTime? _startTime;
  Timer? _uiTimer;
  int _sendCount = 0;

  @override
  void initState() {
    super.initState();
    // อัปเดต UI ทุก 1 วินาที (แสดงเวลาที่วิ่งมา)
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTracking && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรถก่อน')),
      );
      return;
    }

    setState(() => _statusText = 'กำลังขอสิทธิ์ GPS...');

    final ok = await _locationService.startTracking(_selectedVehicle!.id);
    if (!ok) {
      if (mounted) {
        setState(() => _statusText = 'ไม่สามารถเข้าถึง GPS ได้\nกรุณาเปิดการใช้งานตำแหน่งในการตั้งค่า');
      }
      return;
    }

    setState(() {
      _isTracking = true;
      _startTime = DateTime.now();
      _sendCount = 1;
      _statusText = 'กำลังส่ง GPS ทุก 60 วินาที';
    });
  }

  Future<void> _stopTracking() async {
    await _locationService.stopTracking();
    setState(() {
      _isTracking = false;
      _startTime = null;
      _sendCount = 0;
      _statusText = 'กดเริ่มเดินทางเพื่อส่ง GPS';
    });
  }

  String get _elapsedText {
    if (_startTime == null) return '';
    final elapsed = DateTime.now().difference(_startTime!);
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    final s = elapsed.inSeconds % 60;
    if (h > 0) return '${h}ชม. ${m}นาที';
    if (m > 0) return '${m}นาที ${s}วินาที';
    return '${s}วินาที';
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: _isTracking ? AppColors.success : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('โหมดคนขับ',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isTracking
                      ? [const Color(0xFF059669), const Color(0xFF10B981)]
                      : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isTracking ? AppColors.success : AppColors.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Pulsing icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isTracking
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isTracking ? 'กำลังติดตาม GPS' : 'ยังไม่ได้เริ่ม',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4),
                  ),
                  if (_isTracking && _startTime != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatChip(
                            label: 'เวลาวิ่ง', value: _elapsedText),
                        _StatChip(
                            label: 'ส่งแล้ว',
                            value: '$_sendCount ครั้ง'),
                        if (_locationService.lastPosition != null)
                          _StatChip(
                              label: 'ความเร็ว',
                              value:
                                  '${(_locationService.lastPosition!.speed * 3.6).toStringAsFixed(0)} กม./ชม.'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // เลือกรถ
            if (!_isTracking) ...[
              const Text('เลือกรถที่ขับ',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              vehiclesAsync.when(
                data: (vehicles) {
                  final active =
                      vehicles.where((v) => v.status == 'active').toList();
                  if (active.isEmpty) {
                    return const Text('ไม่มีรถที่ active',
                        style:
                            TextStyle(color: AppColors.textSecondary));
                  }
                  return Column(
                    children: active
                        .map((v) => _VehicleOption(
                              vehicle: v,
                              isSelected: _selectedVehicle?.id == v.id,
                              onTap: () =>
                                  setState(() => _selectedVehicle = v),
                            ))
                        .toList(),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],

            // ปุ่มหลัก
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTracking ? _stopTracking : _startTracking,
                icon: Icon(
                    _isTracking
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    size: 24),
                label: Text(
                  _isTracking ? 'หยุดเดินทาง' : 'เริ่มเดินทาง',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isTracking ? AppColors.danger : AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),

            // ปุ่มส่งตำแหน่งทันที
            if (_isTracking) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _locationService.sendNow();
                    setState(() => _sendCount++);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ส่งตำแหน่งแล้ว ✅'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('ส่งตำแหน่งทันที',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            // คำแนะนำ
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text('วิธีใช้งาน',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. เลือกรถที่กำลังขับ\n'
                    '2. กด "เริ่มเดินทาง" ก่อนออกรถ\n'
                    '3. วางโทรศัพท์ไว้ในรถ เปิดหน้าจอหรือ background\n'
                    '4. แอปส่ง GPS ให้เจ้าของเห็นทุก 60 วินาที\n'
                    '5. กด "หยุดเดินทาง" เมื่อถึงที่หมาย',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11)),
      ],
    );
  }
}

class _VehicleOption extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback onTap;
  const _VehicleOption(
      {required this.vehicle,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car_rounded,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.plateNumber,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  Text(
                    vehicle.nickName ??
                        '${vehicle.brand} ${vehicle.model}'.trim(),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
