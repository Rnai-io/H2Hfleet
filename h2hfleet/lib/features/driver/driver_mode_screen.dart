import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vehicle_model.dart';
import '../../providers/locale_provider.dart';
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
  String? _customStatusText;
  DateTime? _startTime;
  Timer? _uiTimer;
  int _sendCount = 0;

  // Digital Driver Profile Info
  final String _driverName = 'นายสมศักดิ์ ขับปลอดภัย';
  final String _driverLicenseNo = 'ท.3-4819203';
  final String _licenseType = 'ใบอนุญาตขับรถทุกประเภท ชนิดที่ 3 (ท.3)';
  final String _licenseExpiry = '15 พ.ย. 2028';
  bool _preTripChecked = true;

  @override
  void initState() {
    super.initState();
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
    final s = ref.read(strProvider);
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.selectVehicleFirst)),
      );
      return;
    }

    setState(() => _customStatusText = s.isTh ? 'กำลังขอสิทธิ์ GPS...' : 'Requesting GPS Permission...');

    final ok = await _locationService.startTracking(_selectedVehicle!.id);
    if (!ok) {
      if (mounted) {
        setState(() => _customStatusText = s.isTh ? 'ไม่สามารถเข้าถึง GPS ได้\nกรุณาเปิดการใช้งานตำแหน่งในการตั้งค่า' : 'GPS access denied.\nPlease enable location in Settings.');
      }
      return;
    }

    setState(() {
      _isTracking = true;
      _startTime = DateTime.now();
      _sendCount = 1;
      _customStatusText = s.isTh ? 'กำลังส่ง GPS แบบเรียลไทม์' : 'Broadcasting Live GPS Telemetry';
    });
  }

  Future<void> _stopTracking() async {
    final s = ref.read(strProvider);
    await _locationService.stopTracking();
    setState(() {
      _isTracking = false;
      _startTime = null;
      _sendCount = 0;
      _customStatusText = s.isTh ? 'กดเริ่มเดินทางเพื่อส่ง GPS' : 'Tap Start Trip to begin GPS tracking';
    });
  }

  String _getElapsedText(bool isTh) {
    if (_startTime == null) return '';
    final elapsed = DateTime.now().difference(_startTime!);
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    final s = elapsed.inSeconds % 60;
    if (h > 0) return isTh ? '$hชม. $mนาที' : '${h}h ${m}m';
    if (m > 0) return isTh ? '$mนาที $sวินาที' : '${m}m ${s}s';
    return isTh ? '$sวินาที' : '${s}s';
  }

  String get _elapsedText => _getElapsedText(ref.read(strProvider).isTh);
  String get _statusText => _customStatusText ?? (_isTracking ? (ref.read(strProvider).isTh ? 'กำลังส่ง GPS แบบเรียลไทม์' : 'Broadcasting Live GPS Telemetry') : (ref.read(strProvider).isTh ? 'กดเริ่มเดินทางเพื่อส่ง GPS' : 'Tap Start Trip to begin GPS tracking'));

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(strProvider);
    final isTh = s.isTh;
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;
    final statusText = _customStatusText ?? (_isTracking ? (isTh ? 'กำลังส่ง GPS แบบเรียลไทม์' : 'Broadcasting Live GPS Telemetry') : (isTh ? 'กดเริ่มเดินทางเพื่อส่ง GPS' : 'Tap Start Trip to begin GPS tracking'));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _isTracking ? const Color(0xFF059669) : const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(isTh ? 'โหมดคนขับและห้องควบคุมดิจิทัล (Driver Cockpit)' : 'Driver Cockpit & Telematics Mode',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _isTracking ? const Color(0xFF10B981) : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isTracking ? 'ONLINE GPS' : 'STANDBY',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: isLargeScreen
          ? _buildLargeScreenCockpit(context, vehiclesAsync)
          : _buildMobileCockpit(context, vehiclesAsync),
    );
  }

  // ═══════════════ iPad & Web Dual-Pane Cockpit Layout ═══════════════
  Widget _buildLargeScreenCockpit(BuildContext context, AsyncValue<List<VehicleModel>> vehiclesAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Left Column (Driver Credentials & Shift Status: 45%) ───
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Digital Driver License Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _driverName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('พนักงานขับรถขนส่งระดับ Enterprise', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: const Text('ผ่านการยืนยันตัวตน', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF34D399))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFF334155)),
                        const SizedBox(height: 14),

                        // License Details
                        _DriverDetailRow(icon: Icons.badge_rounded, label: 'เลขที่ใบอนุญาตขับขี่', value: _driverLicenseNo),
                        const SizedBox(height: 8),
                        _DriverDetailRow(icon: Icons.category_rounded, label: 'ประเภทใบขับขี่', value: _licenseType),
                        const SizedBox(height: 8),
                        _DriverDetailRow(icon: Icons.calendar_today_rounded, label: 'วันหมดอายุบัตร', value: _driverLicenseExpiryText),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Pre-Trip Inspection & Safety Checklist
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.fact_check_rounded, size: 18, color: Color(0xFF0284C7)),
                                SizedBox(width: 8),
                                Text('ตรวจความพร้อมก่อนขับ (Pre-Trip Check)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              ],
                            ),
                            Switch(
                              value: _preTripChecked,
                              activeThumbColor: const Color(0xFF059669),
                              onChanged: (val) => setState(() => _preTripChecked = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _SafetyCheckItem(label: 'ระดับแอลกอฮอล์ในลมหายใจ 0.00 mg%', isPass: _preTripChecked),
                        _SafetyCheckItem(label: 'แรงดันลมยาง & สภาพดอกยางพร้อมใช้งาน', isPass: _preTripChecked),
                        _SafetyCheckItem(label: 'ระบบเบรก สัญญาณไฟเลี้ยว & ไฟฉุกเฉิน', isPass: _preTripChecked),
                        _SafetyCheckItem(label: 'พักผ่อนต่อเนื่องเกิน 8 ชั่วโมงก่อนเริ่มกะ', isPass: _preTripChecked),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 24),

          // ─── Right Column (Live Telematics HUD & Controls: 55%) ───
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status HUD Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isTracking
                            ? [const Color(0xFF059669), const Color(0xFF10B981)]
                            : [const Color(0xFF1E3A8A), const Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_isTracking ? const Color(0xFF059669) : const Color(0xFF1E3A8A)).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isTracking ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isTracking ? 'กำลังติดตาม & ส่งพิกัด GPS สด' : 'ระบบพร้อมเริ่มการเดินทาง',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedVehicle != null
                              ? 'รถประจำกะ: ${_selectedVehicle!.plateNumber} (${_selectedVehicle!.brand} ${_selectedVehicle!.model})'
                              : 'กรุณาเลือกรถด้านล่างก่อนเริ่มเดินทาง',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5),
                        ),
                        if (_isTracking && _startTime != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatChip(label: 'ระยะเวลาวิ่ง', value: _elapsedText),
                              _StatChip(label: 'ส่งพิกัดแล้ว', value: '$_sendCount ครั้ง'),
                              _StatChip(
                                label: 'ความเร็วสด',
                                value: _locationService.lastPosition != null
                                    ? '${(_locationService.lastPosition!.speed * 3.6).toStringAsFixed(0)} กม./ชม.'
                                    : '0 กม./ชม.',
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Select Vehicle Section
                  if (!_isTracking) ...[
                    const Text('เลือกรถที่จะปฏิบัติหน้าที่', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    vehiclesAsync.when(
                      data: (vehicles) {
                        final active = vehicles.where((v) => v.status == 'active').toList();
                        if (active.isEmpty) {
                          return const Text('ไม่มีรถที่ active ในระบบ', style: TextStyle(color: Color(0xFF64748B)));
                        }
                        return SizedBox(
                          height: 68,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: active.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final v = active[i];
                              final isSel = _selectedVehicle?.id == v.id;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedVehicle = v),
                                child: Container(
                                  width: 220,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF0284C7).withValues(alpha: 0.1) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                                      width: isSel ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.directions_car_rounded, color: isSel ? const Color(0xFF0284C7) : const Color(0xFF64748B)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(v.plateNumber, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isSel ? const Color(0xFF0284C7) : AppColors.textPrimary)),
                                            Text('${v.brand} ${v.model}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTracking ? _stopTracking : _startTracking,
                          icon: Icon(_isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 22),
                          label: Text(_isTracking ? 'หยุดปฏิบัติหน้าที่ / สิ้นสุดกะ' : 'เริ่มออกเดินทาง (Start Shift)',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTracking ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      if (_isTracking) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _locationService.sendNow();
                            setState(() => _sendCount++);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ส่งพิกัดสดเข้าศูนย์ควบคุมแล้ว ✅')),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('ส่งพิกัดทันที'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════ Mobile Cockpit Layout ═══════════════
  Widget _buildMobileCockpit(BuildContext context, AsyncValue<List<VehicleModel>> vehiclesAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isTracking
                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                    : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(_isTracking ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(_isTracking ? 'กำลังติดตาม GPS' : 'ยังไม่ได้เริ่ม',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(_statusText, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                if (_isTracking && _startTime != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatChip(label: 'เวลาวิ่ง', value: _elapsedText),
                      _StatChip(label: 'ส่งแล้ว', value: '$_sendCount ครั้ง'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!_isTracking) ...[
            const Text('เลือกรถที่ขับ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            vehiclesAsync.when(
              data: (vehicles) {
                final active = vehicles.where((v) => v.status == 'active').toList();
                return Column(
                  children: active
                      .map((v) => _VehicleOption(
                            vehicle: v,
                            isSelected: _selectedVehicle?.id == v.id,
                            onTap: () => setState(() => _selectedVehicle = v),
                          ))
                      .toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTracking ? _stopTracking : _startTracking,
              icon: Icon(_isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 22),
              label: Text(_isTracking ? 'หยุดเดินทาง' : 'เริ่มเดินทาง', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? const Color(0xFFDC2626) : const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _driverLicenseExpiryText => _licenseExpiry;
}

class _DriverDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DriverDetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _SafetyCheckItem extends StatelessWidget {
  final String label;
  final bool isPass;

  const _SafetyCheckItem({required this.label, required this.isPass});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isPass ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 16, color: isPass ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)))),
        ],
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
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10.5)),
      ],
    );
  }
}

class _VehicleOption extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback onTap;
  const _VehicleOption({required this.vehicle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car_rounded, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.plateNumber, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                  Text(vehicle.nickName ?? '${vehicle.brand} ${vehicle.model}'.trim(), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
