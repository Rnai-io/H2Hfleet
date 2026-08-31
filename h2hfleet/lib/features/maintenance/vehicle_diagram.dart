import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ประเภทตัวถังที่ใช้วาด (blueprint side-profile)
enum VehicleArchetype { sedan, suv, pickup, van, boxVan, bus, truck, mixer }

/// แปลงค่า vehicle_type (ภาษาไทย/อังกฤษ) เป็น archetype สำหรับวาด
VehicleArchetype archetypeFromType(String? type) {
  final t = (type ?? '').trim();
  final u = t.toUpperCase();
  if (t.contains('เก๋ง') || u.contains('SEDAN')) return VehicleArchetype.sedan;
  if (u.contains('SUV') || u.contains('PPV') || t.contains('อเนกประสงค์')) {
    return VehicleArchetype.suv;
  }
  if (t.contains('ปูน') || t.contains('มิกเซอร์') || u.contains('MIXER')) {
    return VehicleArchetype.mixer;
  }
  if (t.contains('ห้องเย็น') || t.contains('ทึบ') || u.contains('BOX')) {
    return VehicleArchetype.boxVan;
  }
  if (t.contains('บรรทุก') || t.contains('สิบล้อ') || t.contains('หกล้อ') || u.contains('TRUCK')) {
    return VehicleArchetype.truck;
  }
  if (t.contains('บัส') || t.contains('บัซ') || u.contains('BUS')) {
    return VehicleArchetype.bus;
  }
  if (t.contains('ตู้') || u.contains('VIP') || u.contains('VAN')) {
    return VehicleArchetype.van;
  }
  if (t.contains('กระบะ') || u.contains('PICKUP')) return VehicleArchetype.pickup;
  return VehicleArchetype.pickup;
}

String archetypeLabelTh(VehicleArchetype a) {
  switch (a) {
    case VehicleArchetype.sedan:
      return 'รถเก๋ง (Sedan)';
    case VehicleArchetype.suv:
      return 'รถอเนกประสงค์ (SUV / PPV)';
    case VehicleArchetype.pickup:
      return 'รถกระบะ (Pickup Truck)';
    case VehicleArchetype.van:
      return 'รถตู้ (Van / Minibus)';
    case VehicleArchetype.boxVan:
      return 'รถตู้ทึบ / ห้องเย็น (Box Van)';
    case VehicleArchetype.bus:
      return 'รถบัส (Bus / Coach)';
    case VehicleArchetype.truck:
      return 'รถบรรทุก 6-10 ล้อ (Heavy Truck)';
    case VehicleArchetype.mixer:
      return 'รถโม่ปูน (Concrete Mixer)';
  }
}

String archetypeDimSpec(VehicleArchetype a) {
  switch (a) {
    case VehicleArchetype.sedan:
      return 'L: 4,680mm · H: 1,435mm · W: 1,810mm';
    case VehicleArchetype.suv:
      return 'L: 4,890mm · H: 1,840mm · W: 1,890mm';
    case VehicleArchetype.pickup:
      return 'L: 5,325mm · H: 1,815mm · W: 1,855mm';
    case VehicleArchetype.van:
      return 'L: 5,265mm · H: 1,990mm · W: 1,950mm';
    case VehicleArchetype.boxVan:
      return 'L: 5,600mm · H: 2,650mm · W: 1,980mm';
    case VehicleArchetype.bus:
      return 'L: 12,000mm · H: 3,650mm · W: 2,500mm';
    case VehicleArchetype.truck:
      return 'L: 9,850mm · H: 3,250mm · W: 2,490mm';
    case VehicleArchetype.mixer:
      return 'L: 8,450mm · H: 3,750mm · W: 2,500mm';
  }
}

/// จุดกดตรวจเช็ค (สัดส่วนของ w/h)
class HotspotSpec {
  final double fx, fy, fw, fh;
  final String key;
  final String label;
  const HotspotSpec(this.fx, this.fy, this.fw, this.fh, this.key, [this.label = '']);
}

/// เรขาคณิตของรถแต่ละแบบ
class VehicleGeometry {
  final List<Offset> wheels;
  final double wheelR;
  final double topY;
  final double leftX;
  final double rightX;
  final List<HotspotSpec> hotspots;

  const VehicleGeometry({
    required this.wheels,
    required this.wheelR,
    required this.topY,
    required this.leftX,
    required this.rightX,
    required this.hotspots,
  });
}

VehicleGeometry geometryFor(VehicleArchetype a) {
  switch (a) {
    case VehicleArchetype.sedan:
      return const VehicleGeometry(
        wheels: [Offset(0.24, 0.76), Offset(0.76, 0.76)],
        wheelR: 0.115,
        topY: 0.32,
        leftX: 0.05,
        rightX: 0.95,
        hotspots: [
          HotspotSpec(0.06, 0.50, 0.22, 0.24, 'engine', 'ห้องเครื่องยนต์'),
          HotspotSpec(0.14, 0.60, 0.12, 0.15, 'oil', 'น้ำมันเครื่อง'),
          HotspotSpec(0.08, 0.44, 0.10, 0.12, 'battery', 'แบตเตอรี่'),
          HotspotSpec(0.18, 0.46, 0.12, 0.14, 'ac', 'ระบบแอร์'),
          HotspotSpec(0.36, 0.58, 0.20, 0.16, 'transmission', 'ระบบเกียร์'),
          HotspotSpec(0.20, 0.66, 0.10, 0.20, 'brake', 'เบรกหน้า'),
          HotspotSpec(0.72, 0.66, 0.10, 0.20, 'brake', 'เบรกหลัง'),
          HotspotSpec(0.18, 0.66, 0.12, 0.20, 'tire', 'ยางหน้า'),
          HotspotSpec(0.70, 0.66, 0.12, 0.20, 'tire', 'ยางหลัง'),
          HotspotSpec(0.18, 0.70, 0.14, 0.12, 'suspension', 'ช่วงล่างหน้า'),
          HotspotSpec(0.70, 0.70, 0.14, 0.12, 'suspension', 'ช่วงล่างหลัง'),
          HotspotSpec(0.86, 0.68, 0.10, 0.12, 'exhaust', 'ท่อไอเสีย'),
          HotspotSpec(0.32, 0.35, 0.45, 0.32, 'body', 'ห้องโดยสาร/ตัวถัง'),
        ],
      );

    case VehicleArchetype.suv:
      return const VehicleGeometry(
        wheels: [Offset(0.25, 0.76), Offset(0.75, 0.76)],
        wheelR: 0.125,
        topY: 0.25,
        leftX: 0.05,
        rightX: 0.95,
        hotspots: [
          HotspotSpec(0.06, 0.46, 0.22, 0.26, 'engine', 'เครื่องยนต์'),
          HotspotSpec(0.12, 0.56, 0.12, 0.15, 'oil', 'น้ำมันเครื่อง'),
          HotspotSpec(0.08, 0.40, 0.10, 0.12, 'battery', 'แบตเตอรี่'),
          HotspotSpec(0.18, 0.42, 0.12, 0.14, 'ac', 'ระบบแอร์'),
          HotspotSpec(0.38, 0.56, 0.22, 0.18, 'transmission', 'ระบบเกียร์ 4WD'),
          HotspotSpec(0.20, 0.66, 0.11, 0.20, 'brake', 'เบรกหน้า'),
          HotspotSpec(0.70, 0.66, 0.11, 0.20, 'brake', 'เบรกหลัง'),
          HotspotSpec(0.19, 0.64, 0.13, 0.22, 'tire', 'ยางหน้า'),
          HotspotSpec(0.69, 0.64, 0.13, 0.22, 'tire', 'ยางหลัง'),
          HotspotSpec(0.19, 0.70, 0.14, 0.14, 'suspension', 'ช่วงล่างยกสูง'),
          HotspotSpec(0.69, 0.70, 0.14, 0.14, 'suspension', 'ช่วงล่างหลัง'),
          HotspotSpec(0.86, 0.68, 0.10, 0.12, 'exhaust', 'ท่อไอเสีย'),
          HotspotSpec(0.30, 0.28, 0.55, 0.38, 'body', 'ตัวถัง SUV'),
        ],
      );

    case VehicleArchetype.pickup:
      return const VehicleGeometry(
        wheels: [Offset(0.24, 0.76), Offset(0.76, 0.76)],
        wheelR: 0.125,
        topY: 0.26,
        leftX: 0.05,
        rightX: 0.95,
        hotspots: [
          HotspotSpec(0.06, 0.46, 0.22, 0.26, 'engine', 'เครื่องยนต์ดีเซล'),
          HotspotSpec(0.12, 0.56, 0.12, 0.15, 'oil', 'น้ำมันเครื่อง'),
          HotspotSpec(0.08, 0.40, 0.10, 0.12, 'battery', 'แบตเตอรี่'),
          HotspotSpec(0.18, 0.42, 0.12, 0.14, 'ac', 'ระบบแอร์'),
          HotspotSpec(0.36, 0.56, 0.24, 0.18, 'transmission', 'เกียร์/เพลากลาง'),
          HotspotSpec(0.19, 0.64, 0.11, 0.20, 'brake', 'เบรกหน้า'),
          HotspotSpec(0.71, 0.64, 0.11, 0.20, 'brake', 'เบรกหลัง'),
          HotspotSpec(0.18, 0.64, 0.13, 0.22, 'tire', 'ยางหน้า'),
          HotspotSpec(0.70, 0.64, 0.13, 0.22, 'tire', 'ยางหลัง'),
          HotspotSpec(0.18, 0.70, 0.14, 0.14, 'suspension', 'สปริงหน้า'),
          HotspotSpec(0.70, 0.70, 0.14, 0.14, 'suspension', 'แหนบหลัง'),
          HotspotSpec(0.86, 0.68, 0.10, 0.12, 'exhaust', 'ท่อไอเสีย'),
          HotspotSpec(0.55, 0.38, 0.38, 0.32, 'body', 'กระบะบรรทุก'),
        ],
      );

    case VehicleArchetype.van:
      return const VehicleGeometry(
        wheels: [Offset(0.22, 0.76), Offset(0.78, 0.76)],
        wheelR: 0.12,
        topY: 0.20,
        leftX: 0.06,
        rightX: 0.94,
        hotspots: [
          HotspotSpec(0.08, 0.48, 0.20, 0.24, 'engine', 'เครื่องยนต์'),
          HotspotSpec(0.12, 0.58, 0.12, 0.14, 'oil', 'น้ำมันเครื่อง'),
          HotspotSpec(0.08, 0.40, 0.10, 0.12, 'battery', 'แบตเตอรี่'),
          HotspotSpec(0.24, 0.24, 0.45, 0.16, 'ac', 'แอร์ตอนหลัง'),
          HotspotSpec(0.36, 0.58, 0.22, 0.16, 'transmission', 'ระบบเกียร์'),
          HotspotSpec(0.18, 0.66, 0.10, 0.18, 'brake', 'เบรกหน้า'),
          HotspotSpec(0.74, 0.66, 0.10, 0.18, 'brake', 'เบรกหลัง'),
          HotspotSpec(0.16, 0.64, 0.13, 0.22, 'tire', 'ยางหน้า'),
          HotspotSpec(0.72, 0.64, 0.13, 0.22, 'tire', 'ยางหลัง'),
          HotspotSpec(0.16, 0.70, 0.14, 0.12, 'suspension', 'ช่วงล่างหน้า'),
          HotspotSpec(0.72, 0.70, 0.14, 0.12, 'suspension', 'ช่วงล่างหลัง'),
          HotspotSpec(0.85, 0.70, 0.10, 0.12, 'exhaust', 'ท่อไอเสีย'),
          HotspotSpec(0.30, 0.24, 0.58, 0.45, 'body', 'ห้องโดยสาร VIP'),
        ],
      );

    case VehicleArchetype.boxVan:
      return const VehicleGeometry(
        wheels: [Offset(0.22, 0.78), Offset(0.74, 0.78), Offset(0.84, 0.78)],
        wheelR: 0.11,
        topY: 0.14,
        leftX: 0.05,
        rightX: 0.95,
        hotspots: [
          HotspotSpec(0.06, 0.50, 0.18, 0.25, 'engine', 'เครื่องยนต์'),
          HotspotSpec(0.10, 0.60, 0.10, 0.14, 'oil', 'น้ำมันเครื่อง'),
          HotspotSpec(0.07, 0.44, 0.09, 0.12, 'battery', 'แบตเตอรี่'),
          HotspotSpec(0.28, 0.16, 0.20, 0.18, 'ac', 'ชุดทำความเย็น/แอร์'),
          HotspotSpec(0.32, 0.62, 0.24, 0.16, 'transmission', 'ระบบเกียร์'),
          HotspotSpec(0.17, 0.68, 0.10, 0.18, 'brake', 'เบรกหน้า'),
          HotspotSpec(0.73, 0.68, 0.18, 0.18, 'brake', 'เบรกหลังคู่'),
          HotspotSpec(0.16, 0.66, 0.12, 0.20, 'tire', 'ยางหน้า'),
          HotspotSpec(0.70, 0.66, 0.20, 0.20, 'tire', 'ยางหลังคู่'),
          HotspotSpec(0.70, 0.72, 0.20, 0.12, 'suspension', 'แหนบบรรทุกหนัก'),
          HotspotSpec(0.30, 0.16, 0.62, 0.54, 'body', 'ตู้ทึบ/ห้องเย็น'),
        ],
      );

    case VehicleArchetype.bus:
      return const VehicleGeometry(
        wheels: [Offset(0.18, 0.78), Offset(0.76, 0.78), Offset(0.86, 0.78)],
        wheelR: 0.115,
        topY: 0.12,
        leftX: 0.04,
        rightX: 0.96,
        hotspots: [
          HotspotSpec(0.78, 0.48, 0.16, 0.26, 'engine', 'เครื่องยนต์ท้ายบัส'),
          HotspotSpec(0.82, 0.58, 0.10, 0.14, 'oil', 'น้ำมันเครื่อง'),
          HotspotSpec(0.12, 0.60, 0.10, 0.12, 'battery', 'แบตเตอรี่ระบบไฟ'),
          HotspotSpec(0.40, 0.12, 0.28, 0.14, 'ac', 'ชุดแอร์บนหลังคา'),
          HotspotSpec(0.66, 0.62, 0.18, 0.16, 'transmission', 'เกียร์/รีทาร์เดอร์'),
          HotspotSpec(0.13, 0.68, 0.10, 0.18, 'brake', 'เบรกลมหน้า'),
          HotspotSpec(0.74, 0.68, 0.18, 0.18, 'brake', 'เบรกลมหลังคู่'),
          HotspotSpec(0.12, 0.66, 0.12, 0.20, 'tire', 'ยางหน้า'),
          HotspotSpec(0.72, 0.66, 0.20, 0.20, 'tire', 'ยางหลังคู่'),
          HotspotSpec(0.12, 0.72, 0.12, 0.12, 'suspension', 'ถุงลมช่วงล่าง'),
          HotspotSpec(0.72, 0.72, 0.20, 0.12, 'suspension', 'ถุงลมหลังคู่'),
          HotspotSpec(0.06, 0.14, 0.88, 0.52, 'body', 'ตัวถังและที่นั่งบัส'),
        ],
      );

    case VehicleArchetype.truck:
      return const VehicleGeometry(
        wheels: [Offset(0.18, 0.78), Offset(0.72, 0.78), Offset(0.84, 0.78)],
        wheelR: 0.12,
        topY: 0.18,
        leftX: 0.04,
        rightX: 0.96,
        hotspots: [
          HotspotSpec(0.06, 0.44, 0.20, 0.28, 'engine', 'เครื่องยนต์ดีเซล 6 สูบ'),
          HotspotSpec(0.12, 0.58, 0.10, 0.14, 'oil', 'น้ำมันเครื่อง'),
          HotspotSpec(0.24, 0.58, 0.10, 0.14, 'battery', 'แบตเตอรี่ 24V'),
          HotspotSpec(0.14, 0.32, 0.12, 0.14, 'ac', 'ระบบแอร์หัวเก๋ง'),
          HotspotSpec(0.36, 0.60, 0.28, 0.16, 'transmission', 'เกียร์/เพลากลางสิบล้อ'),
          HotspotSpec(0.13, 0.68, 0.10, 0.18, 'brake', 'เบรกลม Air Brake'),
          HotspotSpec(0.70, 0.68, 0.20, 0.18, 'brake', 'เบรกลมเพลาคู่'),
          HotspotSpec(0.12, 0.66, 0.12, 0.22, 'tire', 'ยางหน้า'),
          HotspotSpec(0.68, 0.66, 0.22, 0.22, 'tire', 'ยางเพลาคู่'),
          HotspotSpec(0.68, 0.72, 0.22, 0.14, 'suspension', 'แหนบสิบล้อคู่'),
          HotspotSpec(0.28, 0.24, 0.66, 0.46, 'body', 'กระบะบรรทุกหนัก'),
        ],
      );

    case VehicleArchetype.mixer:
      return const VehicleGeometry(
        wheels: [Offset(0.18, 0.78), Offset(0.70, 0.78), Offset(0.82, 0.78)],
        wheelR: 0.12,
        topY: 0.12,
        leftX: 0.04,
        rightX: 0.96,
        hotspots: [
          HotspotSpec(0.06, 0.44, 0.20, 0.28, 'engine', 'เครื่องยนต์โม่ปูน'),
          HotspotSpec(0.12, 0.58, 0.10, 0.14, 'oil', 'น้ำมันเครื่อง'),
          HotspotSpec(0.24, 0.58, 0.10, 0.14, 'battery', 'แบตเตอรี่ 24V'),
          HotspotSpec(0.14, 0.32, 0.12, 0.14, 'ac', 'ระบบแอร์'),
          HotspotSpec(0.34, 0.60, 0.26, 0.16, 'transmission', 'ระบบขับโม่/ปั๊มไฮดรอลิก'),
          HotspotSpec(0.13, 0.68, 0.10, 0.18, 'brake', 'เบรกลม'),
          HotspotSpec(0.68, 0.68, 0.20, 0.18, 'brake', 'เบรกลมหลังคู่'),
          HotspotSpec(0.12, 0.66, 0.12, 0.22, 'tire', 'ยางหน้า'),
          HotspotSpec(0.66, 0.66, 0.22, 0.22, 'tire', 'ยางเพลาคู่'),
          HotspotSpec(0.66, 0.72, 0.22, 0.14, 'suspension', 'แหนบรับน้ำหนักโม่'),
          HotspotSpec(0.28, 0.16, 0.66, 0.50, 'body', 'ถังโม่ปูน/โครงสร้าง'),
        ],
      );
  }
}

/// Widget แสดงภาพพิมพ์เขียว Engineering Diagnostic View แบบ Interactive
class VehicleDiagram extends StatefulWidget {
  final VehicleArchetype archetype;
  final String? selectedCategory;
  final ValueChanged<String>? onCategorySelected;
  final String? customHeaderTitle;
  final double? height;
  final double aspectRatio;

  const VehicleDiagram({
    super.key,
    required this.archetype,
    this.selectedCategory,
    this.onCategorySelected,
    this.customHeaderTitle,
    this.height,
    this.aspectRatio = 16 / 7.2,
  });

  @override
  State<VehicleDiagram> createState() => _VehicleDiagramState();
}

class _VehicleDiagramState extends State<VehicleDiagram> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Size size) {
    final geo = geometryFor(widget.archetype);
    final px = details.localPosition.dx / size.width;
    final py = details.localPosition.dy / size.height;

    for (final spot in geo.hotspots.reversed) {
      if (px >= spot.fx && px <= spot.fx + spot.fw && py >= spot.fy && py <= spot.fy + spot.fh) {
        widget.onCategorySelected?.call(spot.key);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final geo = geometryFor(widget.archetype);
    final activeSpot = widget.selectedCategory != null
        ? geo.hotspots.firstWhere(
            (s) => s.key == widget.selectedCategory,
            orElse: () => const HotspotSpec(0, 0, 0, 0, ''),
          )
        : null;

    final childWidget = Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF070D1E),
              Color(0xFF0B1736),
              Color(0xFF0F1E4A),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Custom Animated Blueprint Painter
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) => _handleTap(
                          details,
                          Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                        child: CustomPaint(
                          painter: _HighTechBlueprintPainter(
                            archetype: widget.archetype,
                            selectedCategory: widget.selectedCategory,
                            pulseValue: _pulseController.value,
                          ),
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                      );
                    },
                  );
                },
              ),

              // Technical Header Overlay
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6)),
                                ),
                                child: const Text(
                                  'CAD HUD',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF38BDF8),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.customHeaderTitle ?? archetypeLabelTh(widget.archetype),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            archetypeDimSpec(widget.archetype),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Active Inspection Badge
                    if (widget.selectedCategory != null && activeSpot != null && activeSpot.key.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activeSpot.label.isNotEmpty ? activeSpot.label : widget.selectedCategory!,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Interactive Tap Hint Footnote
              Positioned(
                bottom: 10,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'แตะชิ้นส่วนบนภาพเพื่อกรองอะไหล่',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

    if (widget.height != null) {
      return SizedBox(height: widget.height, width: double.infinity, child: childWidget);
    }
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: childWidget,
    );
  }
}

/// Painter ที่วาดลายเส้นพิมพ์เขียวสไตล์ High-Tech Telematics
class _HighTechBlueprintPainter extends CustomPainter {
  final VehicleArchetype archetype;
  final String? selectedCategory;
  final double pulseValue;

  _HighTechBlueprintPainter({
    required this.archetype,
    required this.selectedCategory,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawEngineeringGrid(canvas, w, h);
    _drawDimensionLines(canvas, w, h);
    _drawVehicleArchetypeBody(canvas, w, h);
    _drawHotspotHighlights(canvas, w, h);
  }

  // 1. ตาราง CAD และเส้นตัด Crosshair
  void _drawEngineeringGrid(Canvas canvas, double w, double h) {
    final gridPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.05)
      ..strokeWidth = 0.8;

    const step = 24.0;
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Corner Calibration Marks
    final cornerPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const cLen = 14.0;
    // Top-Left
    canvas.drawLine(const Offset(8, 8), const Offset(8 + cLen, 8), cornerPaint);
    canvas.drawLine(const Offset(8, 8), const Offset(8, 8 + cLen), cornerPaint);
    // Top-Right
    canvas.drawLine(Offset(w - 8, 8), Offset(w - 8 - cLen, 8), cornerPaint);
    canvas.drawLine(Offset(w - 8, 8), Offset(w - 8, 8 + cLen), cornerPaint);
    // Bottom-Left
    canvas.drawLine(Offset(8, h - 8), Offset(8 + cLen, h - 8), cornerPaint);
    canvas.drawLine(Offset(8, h - 8), Offset(8, h - 8 - cLen), cornerPaint);
    // Bottom-Right
    canvas.drawLine(Offset(w - 8, h - 8), Offset(w - 8 - cLen, h - 8), cornerPaint);
    canvas.drawLine(Offset(w - 8, h - 8), Offset(w - 8, h - 8 - cLen), cornerPaint);
  }

  // 2. เส้นแสดงมิติ Dimension CAD
  void _drawDimensionLines(Canvas canvas, double w, double h) {
    final dimPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    // Ground datum line
    final groundPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.04, h * 0.88), Offset(w * 0.96, h * 0.88), groundPaint);
    // Wheelbase extension ticks
    canvas.drawLine(Offset(w * 0.04, h * 0.86), Offset(w * 0.04, h * 0.90), dimPaint);
    canvas.drawLine(Offset(w * 0.96, h * 0.86), Offset(w * 0.96, h * 0.90), dimPaint);
  }

  // 3. วาดรูปร่างตัวถังตาม Archetype
  void _drawVehicleArchetypeBody(Canvas canvas, double w, double h) {
    final bodyStroke = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final bodyFill = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final glassFill = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final detailStroke = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final geo = geometryFor(archetype);

    // Draw Archetype Silhouette
    switch (archetype) {
      case VehicleArchetype.sedan:
        _drawSedan(canvas, w, h, bodyStroke, bodyFill, glassFill, detailStroke);
        break;
      case VehicleArchetype.suv:
        _drawSuv(canvas, w, h, bodyStroke, bodyFill, glassFill, detailStroke);
        break;
      case VehicleArchetype.pickup:
        _drawPickup(canvas, w, h, bodyStroke, bodyFill, glassFill, detailStroke);
        break;
      case VehicleArchetype.van:
        _drawVan(canvas, w, h, bodyStroke, bodyFill, glassFill, detailStroke);
        break;
      case VehicleArchetype.boxVan:
        _drawBoxVan(canvas, w, h, bodyStroke, bodyFill, glassFill, detailStroke);
        break;
      case VehicleArchetype.bus:
        _drawBus(canvas, w, h, bodyStroke, bodyFill, glassFill, detailStroke);
        break;
      case VehicleArchetype.truck:
        _drawTruck(canvas, w, h, bodyStroke, bodyFill, glassFill, detailStroke);
        break;
      case VehicleArchetype.mixer:
        _drawMixer(canvas, w, h, bodyStroke, bodyFill, glassFill, detailStroke);
        break;
    }

    // Draw Modern Alloy Wheels & Brake Calipers
    for (final wheel in geo.wheels) {
      final center = Offset(wheel.dx * w, wheel.dy * h);
      final r = geo.wheelR * h;

      // Tire Outer Rim
      final tirePaint = Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r, tirePaint);

      final tireStroke = Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, r, tireStroke);

      // Inner Alloy Rim
      final rimStroke = Paint()
        ..color = const Color(0xFFBAE6FD)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, r * 0.65, rimStroke);

      // Brake Disc Rotor & Caliper
      final brakePaint = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(center.dx - r * 0.35, center.dy), width: r * 0.25, height: r * 0.45),
        brakePaint,
      );

      // Multi-spoke lines
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        canvas.drawLine(
          center,
          Offset(center.dx + r * 0.65 * math.cos(angle), center.dy + r * 0.65 * math.sin(angle)),
          rimStroke,
        );
      }

      // Center Hub
      canvas.drawCircle(center, r * 0.2, tirePaint);
      canvas.drawCircle(center, r * 0.2, rimStroke);
    }
  }

  // --- Profile Drawings -----------------------------------------------------
  void _drawPickup(Canvas c, double w, double h, Paint stroke, Paint fill, Paint glass, Paint detail) {
    final path = Path()
      ..moveTo(w * 0.06, h * 0.74)
      ..lineTo(w * 0.05, h * 0.56)
      ..quadraticBezierTo(w * 0.06, h * 0.50, w * 0.12, h * 0.48)
      ..lineTo(w * 0.24, h * 0.46)
      ..lineTo(w * 0.34, h * 0.28)
      ..lineTo(w * 0.54, h * 0.28)
      ..lineTo(w * 0.56, h * 0.42)
      ..lineTo(w * 0.92, h * 0.42)
      ..lineTo(w * 0.94, h * 0.45)
      ..lineTo(w * 0.94, h * 0.74)
      ..lineTo(w * 0.84, h * 0.74)
      ..arcToPoint(Offset(w * 0.68, h * 0.74), radius: Radius.circular(w * 0.08), clockwise: false)
      ..lineTo(w * 0.32, h * 0.74)
      ..arcToPoint(Offset(w * 0.16, h * 0.74), radius: Radius.circular(w * 0.08), clockwise: false)
      ..close();

    c.drawPath(path, fill);
    c.drawPath(path, stroke);

    // Cab Window Glass
    final glassPath = Path()
      ..moveTo(w * 0.27, h * 0.46)
      ..lineTo(w * 0.35, h * 0.31)
      ..lineTo(w * 0.52, h * 0.31)
      ..lineTo(w * 0.53, h * 0.46)
      ..close();
    c.drawPath(glassPath, glass);
    c.drawPath(glassPath, detail);

    // Door line & bed line
    c.drawLine(Offset(w * 0.41, h * 0.31), Offset(w * 0.41, h * 0.72), detail);
    c.drawLine(Offset(w * 0.56, h * 0.42), Offset(w * 0.56, h * 0.72), detail);
    // Headlight & Taillight
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.05, h * 0.52, w * 0.04, h * 0.06), const Radius.circular(2)), detail);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.92, h * 0.45, w * 0.02, h * 0.08), const Radius.circular(2)), detail);
  }

  void _drawSedan(Canvas c, double w, double h, Paint stroke, Paint fill, Paint glass, Paint detail) {
    final path = Path()
      ..moveTo(w * 0.06, h * 0.74)
      ..lineTo(w * 0.05, h * 0.62)
      ..quadraticBezierTo(w * 0.06, h * 0.54, w * 0.14, h * 0.52)
      ..lineTo(w * 0.30, h * 0.50)
      ..lineTo(w * 0.42, h * 0.34)
      ..lineTo(w * 0.62, h * 0.34)
      ..lineTo(w * 0.76, h * 0.50)
      ..lineTo(w * 0.90, h * 0.52)
      ..quadraticBezierTo(w * 0.94, h * 0.54, w * 0.94, h * 0.64)
      ..lineTo(w * 0.94, h * 0.74)
      ..lineTo(w * 0.84, h * 0.74)
      ..arcToPoint(Offset(w * 0.68, h * 0.74), radius: Radius.circular(w * 0.08), clockwise: false)
      ..lineTo(w * 0.32, h * 0.74)
      ..arcToPoint(Offset(w * 0.16, h * 0.74), radius: Radius.circular(w * 0.08), clockwise: false)
      ..close();

    c.drawPath(path, fill);
    c.drawPath(path, stroke);

    final glassPath = Path()
      ..moveTo(w * 0.33, h * 0.48)
      ..lineTo(w * 0.43, h * 0.36)
      ..lineTo(w * 0.61, h * 0.36)
      ..lineTo(w * 0.73, h * 0.48)
      ..close();
    c.drawPath(glassPath, glass);
    c.drawPath(glassPath, detail);
    c.drawLine(Offset(w * 0.51, h * 0.36), Offset(w * 0.51, h * 0.72), detail);
  }

  void _drawSuv(Canvas c, double w, double h, Paint stroke, Paint fill, Paint glass, Paint detail) {
    final path = Path()
      ..moveTo(w * 0.06, h * 0.74)
      ..lineTo(w * 0.05, h * 0.55)
      ..quadraticBezierTo(w * 0.06, h * 0.48, w * 0.14, h * 0.46)
      ..lineTo(w * 0.28, h * 0.44)
      ..lineTo(w * 0.38, h * 0.27)
      ..lineTo(w * 0.78, h * 0.27)
      ..lineTo(w * 0.88, h * 0.44)
      ..lineTo(w * 0.94, h * 0.50)
      ..lineTo(w * 0.94, h * 0.74)
      ..lineTo(w * 0.83, h * 0.74)
      ..arcToPoint(Offset(w * 0.67, h * 0.74), radius: Radius.circular(w * 0.08), clockwise: false)
      ..lineTo(w * 0.33, h * 0.74)
      ..arcToPoint(Offset(w * 0.17, h * 0.74), radius: Radius.circular(w * 0.08), clockwise: false)
      ..close();

    c.drawPath(path, fill);
    c.drawPath(path, stroke);

    final glassPath = Path()
      ..moveTo(w * 0.31, h * 0.44)
      ..lineTo(w * 0.39, h * 0.30)
      ..lineTo(w * 0.76, h * 0.30)
      ..lineTo(w * 0.85, h * 0.44)
      ..close();
    c.drawPath(glassPath, glass);
    c.drawPath(glassPath, detail);

    // Roof rack
    c.drawLine(Offset(w * 0.40, h * 0.24), Offset(w * 0.76, h * 0.24), detail);
  }

  void _drawVan(Canvas c, double w, double h, Paint stroke, Paint fill, Paint glass, Paint detail) {
    final path = Path()
      ..moveTo(w * 0.07, h * 0.74)
      ..lineTo(w * 0.06, h * 0.48)
      ..quadraticBezierTo(w * 0.08, h * 0.26, w * 0.22, h * 0.22)
      ..lineTo(w * 0.88, h * 0.22)
      ..quadraticBezierTo(w * 0.94, h * 0.24, w * 0.94, h * 0.36)
      ..lineTo(w * 0.94, h * 0.74)
      ..lineTo(w * 0.85, h * 0.74)
      ..arcToPoint(Offset(w * 0.71, h * 0.74), radius: Radius.circular(w * 0.07), clockwise: false)
      ..lineTo(w * 0.29, h * 0.74)
      ..arcToPoint(Offset(w * 0.15, h * 0.74), radius: Radius.circular(w * 0.07), clockwise: false)
      ..close();

    c.drawPath(path, fill);
    c.drawPath(path, stroke);

    // Panoramic VIP windows
    final glassPath = Path()
      ..moveTo(w * 0.16, h * 0.44)
      ..lineTo(w * 0.24, h * 0.27)
      ..lineTo(w * 0.88, h * 0.27)
      ..lineTo(w * 0.88, h * 0.44)
      ..close();
    c.drawPath(glassPath, glass);
    c.drawPath(glassPath, detail);
  }

  void _drawBoxVan(Canvas c, double w, double h, Paint stroke, Paint fill, Paint glass, Paint detail) {
    // Cab
    final cabPath = Path()
      ..moveTo(w * 0.06, h * 0.74)
      ..lineTo(w * 0.05, h * 0.52)
      ..quadraticBezierTo(w * 0.08, h * 0.36, w * 0.18, h * 0.34)
      ..lineTo(w * 0.28, h * 0.34)
      ..lineTo(w * 0.28, h * 0.74)
      ..lineTo(w * 0.24, h * 0.74)
      ..arcToPoint(Offset(w * 0.12, h * 0.74), radius: Radius.circular(w * 0.06), clockwise: false)
      ..close();
    c.drawPath(cabPath, fill);
    c.drawPath(cabPath, stroke);

    // Cargo Box
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.16, w * 0.66, h * 0.58),
      const Radius.circular(6),
    );
    c.drawRRect(boxRect, fill);
    c.drawRRect(boxRect, stroke);

    // Aerodynamic Wind Deflector
    final deflector = Path()
      ..moveTo(w * 0.16, h * 0.34)
      ..quadraticBezierTo(w * 0.24, h * 0.18, w * 0.28, h * 0.16)
      ..lineTo(w * 0.28, h * 0.34)
      ..close();
    c.drawPath(deflector, glass);
    c.drawPath(deflector, detail);
  }

  void _drawBus(Canvas c, double w, double h, Paint stroke, Paint fill, Paint glass, Paint detail) {
    final path = Path()
      ..moveTo(w * 0.05, h * 0.74)
      ..lineTo(w * 0.04, h * 0.22)
      ..quadraticBezierTo(w * 0.06, h * 0.14, w * 0.14, h * 0.14)
      ..lineTo(w * 0.94, h * 0.14)
      ..quadraticBezierTo(w * 0.96, h * 0.16, w * 0.96, h * 0.26)
      ..lineTo(w * 0.96, h * 0.74)
      ..lineTo(w * 0.92, h * 0.74)
      ..arcToPoint(Offset(w * 0.70, h * 0.74), radius: Radius.circular(w * 0.11), clockwise: false)
      ..lineTo(w * 0.24, h * 0.74)
      ..arcToPoint(Offset(w * 0.12, h * 0.74), radius: Radius.circular(w * 0.06), clockwise: false)
      ..close();

    c.drawPath(path, fill);
    c.drawPath(path, stroke);

    // Panoramic bus windows
    final glassPath = Path()
      ..moveTo(w * 0.06, h * 0.42)
      ..lineTo(w * 0.06, h * 0.20)
      ..lineTo(w * 0.92, h * 0.20)
      ..lineTo(w * 0.92, h * 0.42)
      ..close();
    c.drawPath(glassPath, glass);
    c.drawPath(glassPath, detail);

    // Luggage doors
    for (int i = 0; i < 4; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * (0.26 + i * 0.11), h * 0.54, w * 0.09, h * 0.16),
          const Radius.circular(3),
        ),
        detail,
      );
    }
  }

  void _drawTruck(Canvas c, double w, double h, Paint stroke, Paint fill, Paint glass, Paint detail) {
    // Heavy duty cab
    final cab = Path()
      ..moveTo(w * 0.05, h * 0.74)
      ..lineTo(w * 0.04, h * 0.32)
      ..lineTo(w * 0.12, h * 0.22)
      ..lineTo(w * 0.26, h * 0.22)
      ..lineTo(w * 0.26, h * 0.74)
      ..lineTo(w * 0.22, h * 0.74)
      ..arcToPoint(Offset(w * 0.12, h * 0.74), radius: Radius.circular(w * 0.05), clockwise: false)
      ..close();
    c.drawPath(cab, fill);
    c.drawPath(cab, stroke);

    // Cargo Bed / Container
    final bedRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.26, w * 0.67, h * 0.48),
      const Radius.circular(4),
    );
    c.drawRRect(bedRect, fill);
    c.drawRRect(bedRect, stroke);

    // Chassis rail
    c.drawLine(Offset(w * 0.05, h * 0.70), Offset(w * 0.95, h * 0.70), detail);
  }

  void _drawMixer(Canvas c, double w, double h, Paint stroke, Paint fill, Paint glass, Paint detail) {
    // Heavy truck cab
    final cab = Path()
      ..moveTo(w * 0.05, h * 0.74)
      ..lineTo(w * 0.04, h * 0.34)
      ..lineTo(w * 0.12, h * 0.24)
      ..lineTo(w * 0.26, h * 0.24)
      ..lineTo(w * 0.26, h * 0.74)
      ..lineTo(w * 0.22, h * 0.74)
      ..arcToPoint(Offset(w * 0.12, h * 0.74), radius: Radius.circular(w * 0.05), clockwise: false)
      ..close();
    c.drawPath(cab, fill);
    c.drawPath(cab, stroke);

    // Angled Concrete Mixing Drum
    final drumPath = Path()
      ..moveTo(w * 0.28, h * 0.58)
      ..lineTo(w * 0.44, h * 0.20)
      ..lineTo(w * 0.74, h * 0.24)
      ..lineTo(w * 0.88, h * 0.48)
      ..lineTo(w * 0.78, h * 0.68)
      ..lineTo(w * 0.38, h * 0.68)
      ..close();
    c.drawPath(drumPath, fill);
    c.drawPath(drumPath, stroke);

    // Drum spiral spiral blades
    c.drawLine(Offset(w * 0.44, h * 0.24), Offset(w * 0.58, h * 0.68), detail);
    c.drawLine(Offset(w * 0.58, h * 0.22), Offset(w * 0.72, h * 0.68), detail);
  }

  // 4. วาดจุดตรวจเช็คเรืองแสง (Diagnostic Hotspots & Glowing Aura)
  void _drawHotspotHighlights(Canvas canvas, double w, double h) {
    final geo = geometryFor(archetype);

    for (final spot in geo.hotspots) {
      final isSelected = selectedCategory != null && spot.key == selectedCategory;
      final center = Offset((spot.fx + spot.fw / 2) * w, (spot.fy + spot.fh / 2) * h);
      final spotColor = _getPartCategoryColor(spot.key);

      if (isSelected) {
        // Glowing Neon Pulse Aura
        final auraRadius = (16.0 + pulseValue * 10.0);
        final glowPaint = Paint()
          ..color = spotColor.withValues(alpha: 0.35 * (1.0 - pulseValue * 0.4))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, auraRadius, glowPaint);

        // Active Target Ring
        final ringPaint = Paint()
          ..color = spotColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(center, 12.0, ringPaint);

        // Core Pulse
        final corePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 4.5, corePaint);

        // Floating Component Pin Label
        final labelBg = Paint()
          ..color = spotColor
          ..style = PaintingStyle.fill;
        final tagRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, center.dy - 22), width: 70, height: 18),
          const Radius.circular(5),
        );
        canvas.drawRRect(tagRect, labelBg);

        final textPainter = TextPainter(
          text: TextSpan(
            text: spot.label.isNotEmpty ? spot.label : spot.key.toUpperCase(),
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 70);
        textPainter.paint(
          canvas,
          Offset(center.dx - textPainter.width / 2, center.dy - 22 - textPainter.height / 2),
        );
      } else {
        // Subtle Dormant Inspection Node
        final nodeBg = Paint()
          ..color = const Color(0xFF0F172A).withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;
        final nodeStroke = Paint()
          ..color = spotColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

        canvas.drawCircle(center, 5.5, nodeBg);
        canvas.drawCircle(center, 5.5, nodeStroke);
        canvas.drawCircle(center, 2.0, Paint()..color = spotColor);
      }
    }
  }

  Color _getPartCategoryColor(String key) {
    switch (key) {
      case 'engine':
        return const Color(0xFFEF4444);
      case 'oil':
        return const Color(0xFFF59E0B);
      case 'brake':
        return const Color(0xFFDC2626);
      case 'tire':
        return const Color(0xFF38BDF8);
      case 'battery':
        return const Color(0xFF10B981);
      case 'suspension':
        return const Color(0xFF8B5CF6);
      case 'electrical':
        return const Color(0xFFEAB308);
      case 'ac':
        return const Color(0xFF06B6D4);
      case 'transmission':
        return const Color(0xFF6366F1);
      case 'body':
        return const Color(0xFF3B82F6);
      case 'exhaust':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF0284C7);
    }
  }

  @override
  bool shouldRepaint(covariant _HighTechBlueprintPainter oldDelegate) {
    return oldDelegate.archetype != archetype ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.pulseValue != pulseValue;
  }
}
