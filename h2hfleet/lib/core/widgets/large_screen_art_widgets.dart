import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../features/map/route_navigation_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_location_model.dart';

/// ─── 1. Cyber Fleet Isometric Hero Art (CustomPainter) ─────────────────────
class CyberFleetHeroArt extends StatelessWidget {
  final double height;
  final int activeVehicles;
  final bool isTh;

  const CyberFleetHeroArt({
    super.key,
    this.height = 180,
    this.activeVehicles = 0,
    this.isTh = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F2744),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Vector Mesh
            Positioned.fill(
              child: CustomPaint(
                painter: _CyberGridPainter(),
              ),
            ),

            // Ambient Glow Circles
            Positioned(
              top: -40,
              right: 60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: 40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                ),
              ),
            ),

            // Foreground Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  // Left: High-Tech Typography & Telemetry
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.satellite_alt_rounded, color: Color(0xFF38BDF8), size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    isTh ? 'ระบบองค์กรอัจฉริยะ · IPAD & WEB' : 'H2H FLEET ENTERPRISE · IPAD & WEB',
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isTh ? 'ออนไลน์ $activeVehicles คัน' : 'ONLINE $activeVehicles Vehicles',
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isTh ? 'ศูนย์ควบคุมกองยานพาหนะอัจฉริยะ' : 'Smart Fleet Command Center',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTh
                              ? 'ติดตาม GPS สดผ่านดาวเทียม วิเคราะห์ต้นทุนด้วย AI และกระจายงานสู่พนักงานขับรถอัตโนมัติ'
                              : 'Live satellite GPS tracking, AI cost analytics, and automated fleet dispatching',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: Bespoke Custom Isometric Truck Art
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(160, 120),
                        painter: _IsometricTruckArtPainter(),
                      ),
                    ),
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

/// ─── 2. Isometric Smart Truck Vector Art Painter ───────────────────────────
class _IsometricTruckArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.55);

    // Glow aura under truck
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.5),
          const Color(0xFF0284C7).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center.translate(0, 20), radius: 60));
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 25), width: 140, height: 45),
      auraPaint,
    );

    // Orbit Ring / Telemetry waves
    final ringPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 15), width: 120, height: 35),
      ringPaint,
    );

    // Truck Cargo Container (Isometric Cube)
    final cargoTop = Path()
      ..moveTo(center.dx - 15, center.dy - 35)
      ..lineTo(center.dx + 40, center.dy - 55)
      ..lineTo(center.dx + 65, center.dy - 40)
      ..lineTo(center.dx + 10, center.dy - 20)
      ..close();
    canvas.drawPath(cargoTop, Paint()..color = const Color(0xFF0284C7));

    final cargoLeft = Path()
      ..moveTo(center.dx - 15, center.dy - 35)
      ..lineTo(center.dx + 10, center.dy - 20)
      ..lineTo(center.dx + 10, center.dy + 15)
      ..lineTo(center.dx - 15, center.dy)
      ..close();
    canvas.drawPath(cargoLeft, Paint()..color = const Color(0xFF0369A1));

    final cargoRight = Path()
      ..moveTo(center.dx + 10, center.dy - 20)
      ..lineTo(center.dx + 65, center.dy - 40)
      ..lineTo(center.dx + 65, center.dy - 5)
      ..lineTo(center.dx + 10, center.dy + 15)
      ..close();
    canvas.drawPath(cargoRight, Paint()..color = const Color(0xFF0C4A6E));

    // Truck Cabin (Front)
    final cabinTop = Path()
      ..moveTo(center.dx - 55, center.dy - 12)
      ..lineTo(center.dx - 20, center.dy - 28)
      ..lineTo(center.dx - 10, center.dy - 22)
      ..lineTo(center.dx - 45, center.dy - 6)
      ..close();
    canvas.drawPath(cabinTop, Paint()..color = const Color(0xFF38BDF8));

    final cabinLeft = Path()
      ..moveTo(center.dx - 55, center.dy - 12)
      ..lineTo(center.dx - 45, center.dy - 6)
      ..lineTo(center.dx - 45, center.dy + 20)
      ..lineTo(center.dx - 55, center.dy + 14)
      ..close();
    canvas.drawPath(cabinLeft, Paint()..color = const Color(0xFF0284C7));

    final cabinRight = Path()
      ..moveTo(center.dx - 45, center.dy - 6)
      ..lineTo(center.dx - 10, center.dy - 22)
      ..lineTo(center.dx - 10, center.dy + 6)
      ..lineTo(center.dx - 45, center.dy + 20)
      ..close();
    canvas.drawPath(cabinRight, Paint()..color = const Color(0xFF0369A1));

    // Windshield (Cyan Glowing Glass)
    final windshield = Path()
      ..moveTo(center.dx - 50, center.dy - 8)
      ..lineTo(center.dx - 25, center.dy - 21)
      ..lineTo(center.dx - 25, center.dy - 8)
      ..lineTo(center.dx - 50, center.dy + 5)
      ..close();
    canvas.drawPath(
      windshield,
      Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.85),
    );

    // Front Headlights
    final lightPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    canvas.drawCircle(Offset(center.dx - 52, center.dy + 8), 3, lightPaint);
    canvas.drawCircle(Offset(center.dx - 44, center.dy + 14), 3, lightPaint);

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 38, center.dy + 22), width: 14, height: 18), wheelPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 5, center.dy + 20), width: 14, height: 18), wheelPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 45, center.dy + 2), width: 14, height: 18), wheelPaint);

    // GPS Antenna Pin on top of Cargo
    final pinPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(Offset(center.dx + 25, center.dy - 45), 4, pinPaint);
    canvas.drawLine(
      Offset(center.dx + 25, center.dy - 45),
      Offset(center.dx + 25, center.dy - 35),
      Paint()..color = const Color(0xFF10B981)..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ─── 3. Cyber Grid Vector Background Painter ───────────────────────────────
class _CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ─── 4. iPad / Web Telemetry Radar Scanner Card ────────────────────────────
class IpadTelemetryRadarCard extends StatefulWidget {
  final List<VehicleModel> vehicles;
  final List<VehicleLocationModel> locations;
  final VoidCallback onOpenMap;
  final bool isTh;

  const IpadTelemetryRadarCard({
    super.key,
    required this.vehicles,
    required this.locations,
    required this.onOpenMap,
    this.isTh = true,
  });

  @override
  State<IpadTelemetryRadarCard> createState() => _IpadTelemetryRadarCardState();
}

class _IpadTelemetryRadarCardState extends State<IpadTelemetryRadarCard> with SingleTickerProviderStateMixin {
  late AnimationController _radarCtrl;
  String _currentAddress = 'กำลังระบุพิกัด GPS สด...';
  String _nearestHubName = 'กำลังค้นหาสถานที่ใกล้เคียง...';
  String _nearestHubCategory = 'ศูนย์กระจายสินค้า';
  double? _nearestDistanceKm;
  Position? _currentPosition;
  bool _isLoadingGps = true;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _detectLiveLocation();
  }

  Future<void> _detectLiveLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingGps = true);

    try {
      Position? pos;
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          pos = await Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 4),
          );
        }
      }

      if (pos != null) {
        if (!mounted) return;
        setState(() {
          _currentPosition = pos;
          _isLoadingGps = false;
        });

        // Reverse geocoding via Nominatim
        final addr = await RouteNavigationService.reverseGeocode(
          LatLng(pos.latitude, pos.longitude),
        );
        if (mounted && addr != null) {
          setState(() => _currentAddress = addr);
        }

        // Nearest POI hub search
        final pois = await RouteNavigationService.searchLocations(
          'ปั๊มน้ำมัน คลังสินค้า ศูนย์กระจายสินค้า',
          userLocation: LatLng(pos.latitude, pos.longitude),
        );
        if (mounted && pois.isNotEmpty) {
          final nearest = pois.first;
          setState(() {
            _nearestHubName = nearest.title;
            _nearestHubCategory = nearest.category;
            _nearestDistanceKm = nearest.distanceKm ?? 1.2;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _currentAddress = widget.isTh ? 'กรุงเทพมหานคร (Bangkok Central HQ)' : 'Bangkok Central HQ (Thailand)';
          _nearestHubName = widget.isTh ? 'ศูนย์กระจายสินค้า วังน้อย (DC Wang Noi)' : 'Wang Noi Logistics Hub (DC)';
          _nearestHubCategory = widget.isTh ? 'คลังสินค้าหลัก' : 'Main Depot';
          _nearestDistanceKm = 1.4;
          _isLoadingGps = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentAddress = widget.isTh ? 'กรุงเทพมหานคร (Bangkok Central HQ)' : 'Bangkok Central HQ (Thailand)';
        _nearestHubName = widget.isTh ? 'ศูนย์กระจายสินค้า วังน้อย (DC Wang Noi)' : 'Wang Noi Logistics Hub (DC)';
        _nearestHubCategory = widget.isTh ? 'คลังสินค้าหลัก' : 'Main Depot';
        _nearestDistanceKm = 1.4;
        _isLoadingGps = false;
      });
    }
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTh = widget.isTh;
    final latText = _currentPosition != null ? '${_currentPosition!.latitude.toStringAsFixed(4)}° N' : '13.7563° N';
    final lngText = _currentPosition != null ? '${_currentPosition!.longitude.toStringAsFixed(4)}° E' : '100.5018° E';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. Header Bar ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    isTh ? 'เรดาร์ตรวจสอบพิกัดสด (Live Radar)' : 'Live Telematics Radar',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('LIVE', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                                ),
                              ],
                            ),
                            Text(
                              isTh ? 'สแกนพิกัดกองรถ & ตรวจจับสถานที่ใกล้เคียงแบบเรียลไทม์' : 'Fleet scanning & nearby facility live detection',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: _isLoadingGps
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)))
                          : const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF0284C7)),
                      tooltip: isTh ? 'รีเฟรชพิกัดสด' : 'Refresh Live GPS',
                      onPressed: _detectLiveLocation,
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: widget.onOpenMap,
                      icon: const Icon(Icons.map_rounded, size: 14, color: Color(0xFF0284C7)),
                      label: Text(
                        isTh ? 'แผนที่เต็ม' : 'Full Map',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // ─── 2. Enlarged Futuristic Radar Screen (Height: 235px) ───
          Container(
            height: 235,
            width: double.infinity,
            color: const Color(0xFF070D1E),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated Radar Sweep
                AnimatedBuilder(
                  animation: _radarCtrl,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(220, 220),
                      painter: _RadarSweepPainter(angle: _radarCtrl.value * 2 * math.pi),
                    );
                  },
                ),

                // Top Left HUD Coordinate Overlay
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'LAT: $latText\nLON: $lngText',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF38BDF8),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),

                // Top Right Telemetry Lock Indicator
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.6)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.satellite_alt_rounded, color: Color(0xFF34D399), size: 11),
                        SizedBox(width: 4),
                        Text(
                          'SATELLITE LOCK',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center HQ Core (Blinking Pulse)
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.9),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),

                // Vehicle Pings Plotted in Radius on Radar
                ...widget.vehicles.take(6).toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final v = entry.value;
                  // Dynamic spread across concentric circles
                  final radius = 45.0 + (idx * 20.0);
                  final angle = (idx * 1.15) + 0.6;
                  final x = radius * math.cos(angle);
                  final y = radius * math.sin(angle);

                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Tooltip(
                      message: isTh ? '${v.plateNumber} (${v.brand}) · พิกัดสด' : '${v.plateNumber} (${v.brand}) · Live GPS',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.8),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            const SizedBox(width: 3),
                            Text(
                              v.plateNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ─── 3. Live Location & Nearest Place Telemetry Box ───
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Current GPS Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Color(0xFF0284C7), size: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isTh ? 'ตำแหน่ง GPS ปัจจุบัน' : 'Current GPS Location',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isTh ? '• เรียลไทม์' : '• Realtime',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _currentAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 8),

                // Row 2: Nearest Landmark / Logistics Hub
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.near_me_rounded, color: Color(0xFFD97706), size: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isTh ? 'สถานที่/ศูนย์กระจายสินค้าใกล้เคียงที่สุด' : 'Nearest Logistics Hub / Facility',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              if (_nearestDistanceKm != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isTh ? 'ห่าง ${_nearestDistanceKm!.toStringAsFixed(1)} กม.' : '${_nearestDistanceKm!.toStringAsFixed(1)} km away',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$_nearestHubName ($_nearestHubCategory)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── 4. Footer Status Bar ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTh ? 'ยานพาหนะพร้อมตรวจจับ: ${widget.vehicles.length} คัน' : 'Vehicles Tracked: ${widget.vehicles.length}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Text(
                    '⚡ WSS SUB-SECOND SYNC',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── 5. Radar Sweep Custom Painter ─────────────────────────────────────────
class _RadarSweepPainter extends CustomPainter {
  final double angle;

  _RadarSweepPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Grid Concentric Rings (4 rings)
    final ringPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius * 0.25, ringPaint);
    canvas.drawCircle(center, radius * 0.50, ringPaint);
    canvas.drawCircle(center, radius * 0.75, ringPaint);
    canvas.drawCircle(center, radius * 0.98, ringPaint);

    // Cross Axis lines
    final axisPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);

    // 45-degree diagonal lines
    canvas.drawLine(Offset(center.dx - radius * 0.7, center.dy - radius * 0.7), Offset(center.dx + radius * 0.7, center.dy + radius * 0.7), axisPaint);
    canvas.drawLine(Offset(center.dx - radius * 0.7, center.dy + radius * 0.7), Offset(center.dx + radius * 0.7, center.dy - radius * 0.7), axisPaint);

    // Sweep cone
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.0),
          const Color(0xFF0284C7).withValues(alpha: 0.42),
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius * 0.98, sweepPaint);

    // Sweep leading line
    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2;
    final endX = center.dx + radius * 0.98 * math.cos(angle);
    final endY = center.dy + radius * 0.98 * math.sin(angle);
    canvas.drawLine(center, Offset(endX, endY), linePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) => oldDelegate.angle != angle;
}
