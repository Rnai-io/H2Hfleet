import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'part_categories.dart';

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
  if (t.contains('บรรทุก') || u.contains('TRUCK')) return VehicleArchetype.truck;
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
      return 'รถเก๋ง';
    case VehicleArchetype.suv:
      return 'SUV';
    case VehicleArchetype.pickup:
      return 'รถกระบะ';
    case VehicleArchetype.van:
      return 'รถตู้';
    case VehicleArchetype.boxVan:
      return 'รถตู้ทึบ / ห้องเย็น';
    case VehicleArchetype.bus:
      return 'รถบัส';
    case VehicleArchetype.truck:
      return 'รถบรรทุก';
    case VehicleArchetype.mixer:
      return 'รถมิกเซอร์ปูน';
  }
}

/// จุดกด (สัดส่วนของ w/h)
class HotspotSpec {
  final double fx, fy, fw, fh;
  final String key;
  const HotspotSpec(this.fx, this.fy, this.fw, this.fh, this.key);
}

/// เรขาคณิตของรถแต่ละแบบ — ใช้ร่วมกันระหว่างตัววาดและจุดกด
class VehicleGeometry {
  final List<Offset> wheels; // ศูนย์กลางล้อ (สัดส่วน x ของ w, y ของ h)
  final double wheelR; // รัศมีล้อ (สัดส่วนของ h)
  final double topY; // จุดสูงสุดของหลังคา (สัดส่วน h) — ใช้ทำเส้นบอกขนาด
  final double leftX; // หน้าสุด
  final double rightX; // ท้ายสุด
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

List<HotspotSpec> _wheelHotspots(List<Offset> wheels) {
  final out = <HotspotSpec>[];
  for (final c in wheels) {
    out.add(HotspotSpec(c.dx - 0.060, c.dy - 0.17, 0.120, 0.31, 'tire'));
  }
  for (int i = 0; i < wheels.length && i < 2; i++) {
    final c = wheels[i];
    out.add(HotspotSpec(c.dx - 0.040, c.dy - 0.105, 0.080, 0.11, 'brake'));
  }
  return out;
}

VehicleGeometry geometryFor(VehicleArchetype a) {
  switch (a) {
    case VehicleArchetype.sedan:
      final wheels = [const Offset(0.255, 0.80), const Offset(0.745, 0.80)];
      return VehicleGeometry(
        wheels: wheels,
        wheelR: 0.115,
        topY: 0.355,
        leftX: 0.05,
        rightX: 0.945,
        hotspots: [
          const HotspotSpec(0.07, 0.55, 0.18, 0.14, 'engine'),
          const HotspotSpec(0.07, 0.665, 0.10, 0.06, 'oil'),
          const HotspotSpec(0.085, 0.50, 0.10, 0.06, 'battery'),
          const HotspotSpec(0.34, 0.40, 0.12, 0.11, 'electrical'),
          const HotspotSpec(0.41, 0.345, 0.16, 0.05, 'ac'),
          const HotspotSpec(0.40, 0.50, 0.30, 0.16, 'body'),
          const HotspotSpec(0.43, 0.665, 0.18, 0.05, 'transmission'),
          const HotspotSpec(0.30, 0.70, 0.20, 0.05, 'suspension'),
          const HotspotSpec(0.80, 0.62, 0.12, 0.08, 'exhaust'),
          ..._wheelHotspots(wheels),
        ],
      );
    case VehicleArchetype.suv:
      final wheels = [const Offset(0.265, 0.795), const Offset(0.745, 0.795)];
      return VehicleGeometry(
        wheels: wheels,
        wheelR: 0.135,
        topY: 0.265,
        leftX: 0.05,
        rightX: 0.945,
        hotspots: [
          const HotspotSpec(0.06, 0.52, 0.18, 0.14, 'engine'),
          const HotspotSpec(0.06, 0.64, 0.10, 0.06, 'oil'),
          const HotspotSpec(0.08, 0.47, 0.10, 0.06, 'battery'),
          const HotspotSpec(0.30, 0.34, 0.12, 0.12, 'electrical'),
          const HotspotSpec(0.40, 0.26, 0.34, 0.05, 'ac'),
          const HotspotSpec(0.40, 0.42, 0.32, 0.18, 'body'),
          const HotspotSpec(0.44, 0.64, 0.18, 0.05, 'transmission'),
          const HotspotSpec(0.31, 0.685, 0.20, 0.05, 'suspension'),
          const HotspotSpec(0.81, 0.58, 0.12, 0.08, 'exhaust'),
          ..._wheelHotspots(wheels),
        ],
      );
    case VehicleArchetype.pickup:
      final wheels = [const Offset(0.235, 0.795), const Offset(0.715, 0.795)];
      return VehicleGeometry(
        wheels: wheels,
        wheelR: 0.125,
        topY: 0.255,
        leftX: 0.045,
        rightX: 0.945,
        hotspots: [
          const HotspotSpec(0.055, 0.52, 0.16, 0.14, 'engine'),
          const HotspotSpec(0.055, 0.64, 0.10, 0.06, 'oil'),
          const HotspotSpec(0.07, 0.47, 0.10, 0.06, 'battery'),
          const HotspotSpec(0.27, 0.33, 0.12, 0.12, 'electrical'),
          const HotspotSpec(0.35, 0.255, 0.16, 0.05, 'ac'),
          const HotspotSpec(0.55, 0.42, 0.36, 0.18, 'body'),
          const HotspotSpec(0.40, 0.64, 0.18, 0.05, 'transmission'),
          const HotspotSpec(0.30, 0.685, 0.18, 0.05, 'suspension'),
          const HotspotSpec(0.81, 0.60, 0.12, 0.08, 'exhaust'),
          ..._wheelHotspots(wheels),
        ],
      );
    case VehicleArchetype.van:
      final wheels = [const Offset(0.215, 0.805), const Offset(0.79, 0.805)];
      return VehicleGeometry(
        wheels: wheels,
        wheelR: 0.11,
        topY: 0.25,
        leftX: 0.05,
        rightX: 0.95,
        hotspots: [
          const HotspotSpec(0.05, 0.50, 0.10, 0.16, 'engine'),
          const HotspotSpec(0.05, 0.66, 0.08, 0.06, 'oil'),
          const HotspotSpec(0.055, 0.45, 0.08, 0.06, 'battery'),
          const HotspotSpec(0.10, 0.34, 0.12, 0.12, 'electrical'),
          const HotspotSpec(0.18, 0.25, 0.70, 0.05, 'ac'),
          const HotspotSpec(0.30, 0.42, 0.55, 0.18, 'body'),
          const HotspotSpec(0.42, 0.66, 0.20, 0.05, 'transmission'),
          const HotspotSpec(0.32, 0.70, 0.22, 0.05, 'suspension'),
          const HotspotSpec(0.85, 0.62, 0.10, 0.08, 'exhaust'),
          ..._wheelHotspots(wheels),
        ],
      );
    case VehicleArchetype.boxVan:
      final wheels = [const Offset(0.205, 0.805), const Offset(0.78, 0.805)];
      return VehicleGeometry(
        wheels: wheels,
        wheelR: 0.108,
        topY: 0.27,
        leftX: 0.05,
        rightX: 0.95,
        hotspots: [
          const HotspotSpec(0.05, 0.50, 0.10, 0.16, 'engine'),
          const HotspotSpec(0.05, 0.66, 0.08, 0.06, 'oil'),
          const HotspotSpec(0.055, 0.45, 0.08, 0.06, 'battery'),
          const HotspotSpec(0.10, 0.40, 0.12, 0.10, 'electrical'),
          const HotspotSpec(0.24, 0.28, 0.66, 0.05, 'ac'),
          const HotspotSpec(0.30, 0.40, 0.60, 0.22, 'body'),
          const HotspotSpec(0.42, 0.66, 0.20, 0.05, 'transmission'),
          const HotspotSpec(0.32, 0.70, 0.22, 0.05, 'suspension'),
          const HotspotSpec(0.85, 0.62, 0.10, 0.08, 'exhaust'),
          ..._wheelHotspots(wheels),
        ],
      );
    case VehicleArchetype.bus:
      final wheels = [const Offset(0.16, 0.815), const Offset(0.84, 0.815)];
      return VehicleGeometry(
        wheels: wheels,
        wheelR: 0.10,
        topY: 0.275,
        leftX: 0.04,
        rightX: 0.958,
        hotspots: [
          const HotspotSpec(0.86, 0.46, 0.10, 0.16, 'engine'),
          const HotspotSpec(0.88, 0.62, 0.08, 0.06, 'oil'),
          const HotspotSpec(0.05, 0.42, 0.10, 0.10, 'electrical'),
          const HotspotSpec(0.13, 0.275, 0.74, 0.05, 'ac'),
          const HotspotSpec(0.20, 0.42, 0.62, 0.18, 'body'),
          const HotspotSpec(0.45, 0.66, 0.20, 0.05, 'transmission'),
          const HotspotSpec(0.30, 0.70, 0.26, 0.05, 'suspension'),
          const HotspotSpec(0.05, 0.50, 0.07, 0.06, 'battery'),
          const HotspotSpec(0.88, 0.66, 0.08, 0.07, 'exhaust'),
          ..._wheelHotspots(wheels),
        ],
      );
    case VehicleArchetype.truck:
      final wheels = [
        const Offset(0.155, 0.82),
        const Offset(0.70, 0.82),
        const Offset(0.80, 0.82),
      ];
      return VehicleGeometry(
        wheels: wheels,
        wheelR: 0.105,
        topY: 0.27,
        leftX: 0.04,
        rightX: 0.95,
        hotspots: [
          const HotspotSpec(0.045, 0.52, 0.12, 0.14, 'engine'),
          const HotspotSpec(0.05, 0.65, 0.09, 0.06, 'oil'),
          const HotspotSpec(0.05, 0.47, 0.08, 0.06, 'battery'),
          const HotspotSpec(0.085, 0.34, 0.11, 0.12, 'electrical'),
          const HotspotSpec(0.09, 0.30, 0.11, 0.04, 'ac'),
          const HotspotSpec(0.30, 0.30, 0.62, 0.26, 'body'),
          const HotspotSpec(0.36, 0.65, 0.20, 0.05, 'transmission'),
          const HotspotSpec(0.26, 0.70, 0.20, 0.05, 'suspension'),
          const HotspotSpec(0.24, 0.62, 0.06, 0.10, 'exhaust'),
          ..._wheelHotspots(wheels),
        ],
      );
    case VehicleArchetype.mixer:
      final wheels = [
        const Offset(0.15, 0.82),
        const Offset(0.72, 0.82),
        const Offset(0.82, 0.82),
      ];
      return VehicleGeometry(
        wheels: wheels,
        wheelR: 0.105,
        topY: 0.20,
        leftX: 0.04,
        rightX: 0.96,
        hotspots: [
          const HotspotSpec(0.045, 0.52, 0.12, 0.14, 'engine'),
          const HotspotSpec(0.05, 0.65, 0.09, 0.06, 'oil'),
          const HotspotSpec(0.05, 0.47, 0.08, 0.06, 'battery'),
          const HotspotSpec(0.085, 0.34, 0.11, 0.12, 'electrical'),
          const HotspotSpec(0.30, 0.26, 0.55, 0.30, 'body'),
          const HotspotSpec(0.36, 0.65, 0.20, 0.05, 'transmission'),
          const HotspotSpec(0.26, 0.70, 0.18, 0.05, 'suspension'),
          const HotspotSpec(0.24, 0.62, 0.06, 0.10, 'exhaust'),
          ..._wheelHotspots(wheels),
        ],
      );
  }
}

/// แผนผังรถสไตล์ blueprint (เส้นเทคนิค) — เปลี่ยนรูปตามประเภทรถ
/// กดที่โซนต่างๆ เพื่อกรองรายการซ่อมบำรุงตามหมวดอะไหล่
class VehicleDiagram extends StatelessWidget {
  final String? vehicleType;
  final String? label; // ป้ายทะเบียน/ชื่อรุ่นที่จะแสดงมุมบนซ้าย
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const VehicleDiagram({
    super.key,
    this.vehicleType,
    this.label,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final archetype = archetypeFromType(vehicleType);
    final geo = geometryFor(archetype);
    final titleLabel =
        (label != null && label!.trim().isNotEmpty) ? label! : archetypeLabelTh(archetype);

    return AspectRatio(
      aspectRatio: 16 / 8.5,
      child: LayoutBuilder(
        builder: (context, size) {
          final w = size.maxWidth;
          final h = size.maxHeight;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BlueprintPainter(
                    archetype: archetype,
                    geo: geo,
                    label: titleLabel,
                  ),
                ),
              ),
              for (final spot in geo.hotspots)
                _hotspot(w, h, spot),
            ],
          );
        },
      ),
    );
  }

  Widget _hotspot(double w, double h, HotspotSpec spot) {
    final cat = partCategoryByKey(spot.key);
    final selected = selectedCategory == spot.key;
    return Positioned(
      left: spot.fx * w,
      top: spot.fy * h,
      width: spot.fw * w,
      height: spot.fh * h,
      child: Tooltip(
        message: cat.labelTh,
        waitDuration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: () => onCategorySelected(selected ? null : spot.key),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? cat.color.withValues(alpha: 0.30) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  PAINTER
// ---------------------------------------------------------------------------

class _Bp {
  final Paint line; // เส้นหลัก
  final Paint bold; // เส้นขอบหนา
  final Paint soft; // เส้นรายละเอียดบาง
  final Paint glass; // กระจก
  final Paint fill; // เติมตัวถังจางๆ
  final Paint dim; // เส้นบอกขนาด
  final double sw;
  _Bp(this.line, this.bold, this.soft, this.glass, this.fill, this.dim, this.sw);
}

class _BlueprintPainter extends CustomPainter {
  final VehicleArchetype archetype;
  final VehicleGeometry geo;
  final String label;

  _BlueprintPainter({
    required this.archetype,
    required this.geo,
    required this.label,
  });

  static const _lineColor = Color(0xFFE6EEFF);
  static const _softColor = Color(0xFFAEC4F2);
  static const _dimColor = Color(0xFF8FB0EC);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = math.max(1.4, h * 0.011);

    final p = _Bp(
      Paint()
        ..color = _lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
      Paint()
        ..color = _lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 1.7
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
      Paint()
        ..color = _softColor.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 0.7
        ..strokeCap = StrokeCap.round,
      Paint()
        ..color = const Color(0xFF8FB6F0).withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill,
      Paint()
        ..color = _dimColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 0.6,
      sw,
    );

    _drawBackground(canvas, w, h);
    _drawGrid(canvas, w, h);
    _drawFrame(canvas, w, h, sw);
    _drawDimensions(canvas, w, h, p);
    _drawBody(canvas, w, h, p);
    for (final c in geo.wheels) {
      _drawWheel(canvas, Offset(c.dx * w, c.dy * h), geo.wheelR * h, p);
    }
    _drawLabels(canvas, w, h);
  }

  // ---- backdrop -----------------------------------------------------------

  void _drawBackground(Canvas canvas, double w, double h) {
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), const Radius.circular(14));
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B47A6), Color(0xFF112E73), Color(0xFF0B2050)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  void _drawGrid(Canvas canvas, double w, double h) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), const Radius.circular(14)));
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.8;
    const step = 0.05;
    for (double fx = step; fx < 1; fx += step) {
      canvas.drawLine(Offset(fx * w, 0), Offset(fx * w, h), grid);
    }
    for (double fy = step * 1.6; fy < 1; fy += step * 1.6) {
      canvas.drawLine(Offset(0, fy * h), Offset(w, fy * h), grid);
    }
    canvas.restore();
  }

  void _drawFrame(Canvas canvas, double w, double h, double sw) {
    final frame = RRect.fromRectAndRadius(
        Rect.fromLTWH(sw, sw, w - 2 * sw, h - 2 * sw),
        const Radius.circular(12));
    canvas.drawRRect(
      frame,
      Paint()
        ..color = _softColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );
    // corner ticks
    final tick = Paint()
      ..color = _lineColor.withValues(alpha: 0.8)
      ..strokeWidth = sw;
    const m = 0.045;
    final len = 0.03 * w;
    final corners = [
      Offset(m * w, m * h),
      Offset((1 - m) * w, m * h),
      Offset(m * w, (1 - m) * h),
      Offset((1 - m) * w, (1 - m) * h),
    ];
    for (final c in corners) {
      canvas.drawLine(c.translate(-len / 2, 0), c.translate(len / 2, 0), tick);
      canvas.drawLine(c.translate(0, -len / 2), c.translate(0, len / 2), tick);
    }
  }

  // ---- dimension annotations ---------------------------------------------

  void _drawDimensions(Canvas canvas, double w, double h, _Bp p) {
    double groundY = 0;
    for (final c in geo.wheels) {
      groundY = math.max(groundY, c.dy + geo.wheelR);
    }
    // overall length dimension (bottom)
    final yDim = (groundY + 0.05).clamp(0.0, 0.97).toDouble() * h;
    final x1 = geo.leftX * w;
    final x2 = geo.rightX * w;
    canvas.drawLine(Offset(x1, yDim), Offset(x2, yDim), p.dim);
    _arrow(canvas, Offset(x1, yDim), true, p.dim);
    _arrow(canvas, Offset(x2, yDim), false, p.dim);
    // extension ticks
    canvas.drawLine(Offset(x1, geo.topY * h), Offset(x1, yDim + 0.02 * h), p.dim);
    canvas.drawLine(Offset(x2, geo.topY * h), Offset(x2, yDim + 0.02 * h), p.dim);

    // overall height dimension (right side)
    final xDim = (geo.rightX + 0.03).clamp(0.0, 0.985).toDouble() * w;
    final yTop = geo.topY * h;
    final yBot = groundY * h;
    canvas.drawLine(Offset(xDim, yTop), Offset(xDim, yBot), p.dim);
    _arrowV(canvas, Offset(xDim, yTop), true, p.dim);
    _arrowV(canvas, Offset(xDim, yBot), false, p.dim);
  }

  void _arrow(Canvas canvas, Offset tip, bool pointLeft, Paint paint) {
    final dir = pointLeft ? 1.0 : -1.0;
    const a = 7.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + dir * a, tip.dy - a * 0.55)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + dir * a, tip.dy + a * 0.55);
    canvas.drawPath(path, paint);
  }

  void _arrowV(Canvas canvas, Offset tip, bool pointUp, Paint paint) {
    final dir = pointUp ? 1.0 : -1.0;
    const a = 7.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - a, tip.dy + dir * a)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + a, tip.dy + dir * a);
    canvas.drawPath(path, paint);
  }

  // ---- body switch --------------------------------------------------------

  void _drawBody(Canvas canvas, double w, double h, _Bp p) {
    switch (archetype) {
      case VehicleArchetype.sedan:
        _sedan(canvas, w, h, p);
        break;
      case VehicleArchetype.suv:
        _suv(canvas, w, h, p);
        break;
      case VehicleArchetype.pickup:
        _pickup(canvas, w, h, p);
        break;
      case VehicleArchetype.van:
        _van(canvas, w, h, p);
        break;
      case VehicleArchetype.boxVan:
        _boxVan(canvas, w, h, p);
        break;
      case VehicleArchetype.bus:
        _bus(canvas, w, h, p);
        break;
      case VehicleArchetype.truck:
        _truck(canvas, w, h, p);
        break;
      case VehicleArchetype.mixer:
        _mixer(canvas, w, h, p);
        break;
    }
  }

  // helpers to make path with fractional coords
  Path _path(double w, double h, void Function(Path, _PT) build) {
    final path = Path();
    build(path, _PT(w, h));
    return path;
  }

  void _stroke(Canvas c, Path path, _Bp p, {bool bold = true, bool fill = true}) {
    if (fill) c.drawPath(path, p.fill);
    c.drawPath(path, bold ? p.bold : p.line);
  }

  void _line(Canvas c, double w, double h, double x1, double y1, double x2,
      double y2, Paint paint) {
    c.drawLine(Offset(x1 * w, y1 * h), Offset(x2 * w, y2 * h), paint);
  }

  // ---- SEDAN --------------------------------------------------------------
  void _sedan(Canvas c, double w, double h, _Bp p) {
    final body = _path(w, h, (path, t) {
      path.moveTo(t.x(0.055), t.y(0.72));
      path.lineTo(t.x(0.052), t.y(0.63));
      path.quadraticBezierTo(t.x(0.05), t.y(0.585), t.x(0.105), t.y(0.565));
      path.lineTo(t.x(0.30), t.y(0.545));
      path.quadraticBezierTo(t.x(0.345), t.y(0.40), t.x(0.43), t.y(0.355));
      path.lineTo(t.x(0.595), t.y(0.355));
      path.quadraticBezierTo(t.x(0.70), t.y(0.36), t.x(0.755), t.y(0.55));
      path.lineTo(t.x(0.90), t.y(0.565));
      path.quadraticBezierTo(t.x(0.945), t.y(0.575), t.x(0.945), t.y(0.66));
      path.lineTo(t.x(0.945), t.y(0.72));
      path.lineTo(t.x(0.805), t.y(0.72));
      path.quadraticBezierTo(t.x(0.745), t.y(0.60), t.x(0.685), t.y(0.72));
      path.lineTo(t.x(0.315), t.y(0.72));
      path.quadraticBezierTo(t.x(0.255), t.y(0.60), t.x(0.195), t.y(0.72));
      path.close();
    });
    _stroke(c, body, p);

    // greenhouse glass
    final glass = _path(w, h, (path, t) {
      path.moveTo(t.x(0.345), t.y(0.50));
      path.lineTo(t.x(0.435), t.y(0.375));
      path.lineTo(t.x(0.60), t.y(0.375));
      path.lineTo(t.x(0.72), t.y(0.50));
      path.close();
    });
    c.drawPath(glass, p.glass);
    c.drawPath(glass, p.line);
    // B-pillar + beltline + door
    _line(c, w, h, 0.515, 0.378, 0.515, 0.50, p.line);
    _line(c, w, h, 0.30, 0.50, 0.78, 0.50, p.soft);
    _line(c, w, h, 0.515, 0.50, 0.515, 0.71, p.soft);
    // door handle
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0.45 * w, 0.535 * h, 0.045 * w, 0.012 * h),
            const Radius.circular(2)),
        p.soft);
    _headlight(c, w, h, 0.075, 0.585, p);
    _grille(c, w, h, 0.052, 0.61, 0.045, 0.07, p);
    _taillight(c, w, h, 0.918, 0.585, p);
    _mirror(c, w, h, 0.335, 0.46, p);
  }

  // ---- SUV ----------------------------------------------------------------
  void _suv(Canvas c, double w, double h, _Bp p) {
    final body = _path(w, h, (path, t) {
      path.moveTo(t.x(0.055), t.y(0.72));
      path.lineTo(t.x(0.05), t.y(0.56));
      path.quadraticBezierTo(t.x(0.05), t.y(0.52), t.x(0.10), t.y(0.50));
      path.lineTo(t.x(0.255), t.y(0.485));
      path.quadraticBezierTo(t.x(0.30), t.y(0.35), t.x(0.355), t.y(0.31));
      path.lineTo(t.x(0.41), t.y(0.27));
      path.lineTo(t.x(0.74), t.y(0.27));
      path.lineTo(t.x(0.80), t.y(0.305));
      path.quadraticBezierTo(t.x(0.875), t.y(0.34), t.x(0.905), t.y(0.42));
      path.lineTo(t.x(0.94), t.y(0.55));
      path.quadraticBezierTo(t.x(0.95), t.y(0.60), t.x(0.95), t.y(0.66));
      path.lineTo(t.x(0.95), t.y(0.72));
      path.lineTo(t.x(0.81), t.y(0.72));
      path.quadraticBezierTo(t.x(0.745), t.y(0.585), t.x(0.68), t.y(0.72));
      path.lineTo(t.x(0.33), t.y(0.72));
      path.quadraticBezierTo(t.x(0.265), t.y(0.585), t.x(0.20), t.y(0.72));
      path.close();
    });
    _stroke(c, body, p);
    final glass = _path(w, h, (path, t) {
      path.moveTo(t.x(0.33), t.y(0.47));
      path.lineTo(t.x(0.385), t.y(0.30));
      path.lineTo(t.x(0.745), t.y(0.30));
      path.lineTo(t.x(0.80), t.y(0.47));
      path.close();
    });
    c.drawPath(glass, p.glass);
    c.drawPath(glass, p.line);
    _line(c, w, h, 0.50, 0.305, 0.50, 0.47, p.line);
    _line(c, w, h, 0.645, 0.305, 0.645, 0.47, p.line);
    _line(c, w, h, 0.27, 0.49, 0.86, 0.49, p.soft);
    _line(c, w, h, 0.50, 0.49, 0.50, 0.71, p.soft);
    // roof rails
    _line(c, w, h, 0.42, 0.262, 0.73, 0.262, p.soft);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0.44 * w, 0.525 * h, 0.045 * w, 0.012 * h),
            const Radius.circular(2)),
        p.soft);
    _headlight(c, w, h, 0.075, 0.52, p);
    _grille(c, w, h, 0.05, 0.55, 0.05, 0.10, p);
    _taillight(c, w, h, 0.922, 0.50, p);
    _mirror(c, w, h, 0.32, 0.42, p);
  }

  // ---- PICKUP -------------------------------------------------------------
  void _pickup(Canvas c, double w, double h, _Bp p) {
    final body = _path(w, h, (path, t) {
      path.moveTo(t.x(0.048), t.y(0.72));
      path.lineTo(t.x(0.045), t.y(0.555));
      path.quadraticBezierTo(t.x(0.045), t.y(0.52), t.x(0.095), t.y(0.50));
      path.lineTo(t.x(0.215), t.y(0.485));
      path.quadraticBezierTo(t.x(0.255), t.y(0.345), t.x(0.315), t.y(0.295));
      path.lineTo(t.x(0.355), t.y(0.258));
      path.lineTo(t.x(0.495), t.y(0.258));
      path.lineTo(t.x(0.515), t.y(0.35));
      path.lineTo(t.x(0.525), t.y(0.42)); // back of cab to bed
      path.lineTo(t.x(0.555), t.y(0.42));
      path.lineTo(t.x(0.555), t.y(0.40));
      path.lineTo(t.x(0.925), t.y(0.40)); // bed top rail
      path.lineTo(t.x(0.945), t.y(0.45));
      path.lineTo(t.x(0.945), t.y(0.72));
      path.lineTo(t.x(0.78), t.y(0.72));
      path.quadraticBezierTo(t.x(0.715), t.y(0.59), t.x(0.65), t.y(0.72));
      path.lineTo(t.x(0.30), t.y(0.72));
      path.quadraticBezierTo(t.x(0.235), t.y(0.59), t.x(0.17), t.y(0.72));
      path.close();
    });
    _stroke(c, body, p);
    // cab glass
    final glass = _path(w, h, (path, t) {
      path.moveTo(t.x(0.245), t.y(0.475));
      path.lineTo(t.x(0.32), t.y(0.30));
      path.lineTo(t.x(0.495), t.y(0.30));
      path.lineTo(t.x(0.495), t.y(0.475));
      path.close();
    });
    c.drawPath(glass, p.glass);
    c.drawPath(glass, p.line);
    _line(c, w, h, 0.375, 0.302, 0.375, 0.475, p.line);
    _line(c, w, h, 0.25, 0.49, 0.50, 0.49, p.soft);
    // bed inner line
    _line(c, w, h, 0.555, 0.425, 0.925, 0.425, p.soft);
    _line(c, w, h, 0.555, 0.40, 0.555, 0.72, p.soft);
    _headlight(c, w, h, 0.072, 0.52, p);
    _grille(c, w, h, 0.05, 0.55, 0.05, 0.10, p);
    _taillight(c, w, h, 0.918, 0.46, p);
    _mirror(c, w, h, 0.235, 0.42, p);
  }

  // ---- VAN ----------------------------------------------------------------
  void _van(Canvas c, double w, double h, _Bp p) {
    final body = _path(w, h, (path, t) {
      path.moveTo(t.x(0.05), t.y(0.73));
      path.lineTo(t.x(0.05), t.y(0.46));
      path.quadraticBezierTo(t.x(0.05), t.y(0.40), t.x(0.085), t.y(0.355));
      path.lineTo(t.x(0.115), t.y(0.30));
      path.quadraticBezierTo(t.x(0.135), t.y(0.252), t.x(0.185), t.y(0.25));
      path.lineTo(t.x(0.90), t.y(0.25));
      path.quadraticBezierTo(t.x(0.945), t.y(0.25), t.x(0.95), t.y(0.32));
      path.lineTo(t.x(0.95), t.y(0.73));
      path.lineTo(t.x(0.855), t.y(0.73));
      path.quadraticBezierTo(t.x(0.79), t.y(0.605), t.x(0.725), t.y(0.73));
      path.lineTo(t.x(0.28), t.y(0.73));
      path.quadraticBezierTo(t.x(0.215), t.y(0.605), t.x(0.15), t.y(0.73));
      path.close();
    });
    _stroke(c, body, p);
    // windshield
    final ws = _path(w, h, (path, t) {
      path.moveTo(t.x(0.06), t.y(0.44));
      path.lineTo(t.x(0.115), t.y(0.30));
      path.lineTo(t.x(0.165), t.y(0.30));
      path.lineTo(t.x(0.165), t.y(0.44));
      path.close();
    });
    c.drawPath(ws, p.glass);
    c.drawPath(ws, p.line);
    // side windows row
    for (int i = 0; i < 4; i++) {
      final x = 0.22 + i * 0.16;
      final r = Rect.fromLTWH(x * w, 0.30 * h, 0.135 * w, 0.13 * h);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), p.glass);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), p.line);
    }
    _line(c, w, h, 0.18, 0.46, 0.92, 0.46, p.soft);
    // sliding door line
    _line(c, w, h, 0.55, 0.46, 0.55, 0.73, p.soft);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0.50 * w, 0.555 * h, 0.04 * w, 0.012 * h),
            const Radius.circular(2)),
        p.soft);
    _headlight(c, w, h, 0.072, 0.52, p);
    _taillight(c, w, h, 0.922, 0.50, p);
    _mirror(c, w, h, 0.165, 0.40, p);
  }

  // ---- BOX VAN / FRIDGE ---------------------------------------------------
  void _boxVan(Canvas c, double w, double h, _Bp p) {
    // cab
    final cab = _path(w, h, (path, t) {
      path.moveTo(t.x(0.05), t.y(0.73));
      path.lineTo(t.x(0.05), t.y(0.46));
      path.quadraticBezierTo(t.x(0.05), t.y(0.40), t.x(0.085), t.y(0.37));
      path.lineTo(t.x(0.13), t.y(0.36));
      path.lineTo(t.x(0.235), t.y(0.36));
      path.lineTo(t.x(0.235), t.y(0.73));
      path.close();
    });
    _stroke(c, cab, p);
    // box body (taller than cab)
    final box = _path(w, h, (path, t) {
      path.moveTo(t.x(0.235), t.y(0.73));
      path.lineTo(t.x(0.235), t.y(0.275));
      path.lineTo(t.x(0.95), t.y(0.275));
      path.lineTo(t.x(0.95), t.y(0.73));
      path.close();
    });
    _stroke(c, box, p);
    // bottom arches over box body (cut visually with soft arcs)
    _line(c, w, h, 0.30, 0.73, 0.95, 0.73, p.line);
    // cab windshield
    final ws = _path(w, h, (path, t) {
      path.moveTo(t.x(0.06), t.y(0.45));
      path.lineTo(t.x(0.10), t.y(0.37));
      path.lineTo(t.x(0.165), t.y(0.37));
      path.lineTo(t.x(0.165), t.y(0.45));
      path.close();
    });
    c.drawPath(ws, p.glass);
    c.drawPath(ws, p.line);
    // box panel lines
    for (int i = 1; i <= 3; i++) {
      final y = 0.275 + i * 0.11;
      _line(c, w, h, 0.245, y, 0.94, y, p.soft);
    }
    // refrigeration unit on box front-top
    final fridge = Rect.fromLTWH(0.245 * w, 0.225 * h, 0.10 * w, 0.05 * h);
    c.drawRRect(RRect.fromRectAndRadius(fridge, const Radius.circular(3)), p.fill);
    c.drawRRect(RRect.fromRectAndRadius(fridge, const Radius.circular(3)), p.soft);
    _headlight(c, w, h, 0.072, 0.52, p);
    _mirror(c, w, h, 0.165, 0.42, p);
  }

  // ---- BUS ----------------------------------------------------------------
  void _bus(Canvas c, double w, double h, _Bp p) {
    final body = _path(w, h, (path, t) {
      path.moveTo(t.x(0.045), t.y(0.74));
      path.lineTo(t.x(0.042), t.y(0.42));
      path.quadraticBezierTo(t.x(0.045), t.y(0.32), t.x(0.085), t.y(0.30));
      path.quadraticBezierTo(t.x(0.11), t.y(0.275), t.x(0.16), t.y(0.275));
      path.lineTo(t.x(0.91), t.y(0.275));
      path.quadraticBezierTo(t.x(0.955), t.y(0.28), t.x(0.957), t.y(0.40));
      path.lineTo(t.x(0.958), t.y(0.74));
      path.lineTo(t.x(0.905), t.y(0.74));
      path.quadraticBezierTo(t.x(0.84), t.y(0.62), t.x(0.775), t.y(0.74));
      path.lineTo(t.x(0.225), t.y(0.74));
      path.quadraticBezierTo(t.x(0.16), t.y(0.62), t.x(0.095), t.y(0.74));
      path.close();
    });
    _stroke(c, body, p);
    // windshield
    final ws = _path(w, h, (path, t) {
      path.moveTo(t.x(0.05), t.y(0.45));
      path.lineTo(t.x(0.075), t.y(0.32));
      path.lineTo(t.x(0.145), t.y(0.32));
      path.lineTo(t.x(0.145), t.y(0.45));
      path.close();
    });
    c.drawPath(ws, p.glass);
    c.drawPath(ws, p.line);
    // window row
    for (int i = 0; i < 6; i++) {
      final x = 0.18 + i * 0.125;
      final r = Rect.fromLTWH(x * w, 0.32 * h, 0.105 * w, 0.13 * h);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), p.glass);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), p.line);
    }
    _line(c, w, h, 0.05, 0.49, 0.95, 0.49, p.soft);
    // door
    final door = Rect.fromLTWH(0.155 * w, 0.49 * h, 0.05 * w, 0.245 * h);
    c.drawRRect(RRect.fromRectAndRadius(door, const Radius.circular(3)), p.soft);
    _headlight(c, w, h, 0.07, 0.55, p);
    _taillight(c, w, h, 0.93, 0.55, p);
    _mirror(c, w, h, 0.155, 0.40, p);
  }

  // ---- TRUCK (6-wheel cab + cargo) ---------------------------------------
  void _truck(Canvas c, double w, double h, _Bp p) {
    // cab
    final cab = _path(w, h, (path, t) {
      path.moveTo(t.x(0.042), t.y(0.73));
      path.lineTo(t.x(0.04), t.y(0.42));
      path.quadraticBezierTo(t.x(0.04), t.y(0.34), t.x(0.075), t.y(0.31));
      path.lineTo(t.x(0.095), t.y(0.30));
      path.lineTo(t.x(0.20), t.y(0.30));
      path.lineTo(t.x(0.20), t.y(0.73));
      path.close();
    });
    _stroke(c, cab, p);
    // chassis line
    _line(c, w, h, 0.20, 0.60, 0.95, 0.60, p.line);
    // cargo box
    final cargo = _path(w, h, (path, t) {
      path.moveTo(t.x(0.255), t.y(0.60));
      path.lineTo(t.x(0.255), t.y(0.285));
      path.lineTo(t.x(0.95), t.y(0.285));
      path.lineTo(t.x(0.95), t.y(0.60));
      path.close();
    });
    _stroke(c, cargo, p);
    // windshield
    final ws = _path(w, h, (path, t) {
      path.moveTo(t.x(0.05), t.y(0.41));
      path.lineTo(t.x(0.082), t.y(0.31));
      path.lineTo(t.x(0.155), t.y(0.31));
      path.lineTo(t.x(0.155), t.y(0.41));
      path.close();
    });
    c.drawPath(ws, p.glass);
    c.drawPath(ws, p.line);
    // cargo slats
    for (int i = 1; i <= 3; i++) {
      final y = 0.285 + i * 0.078;
      _line(c, w, h, 0.262, y, 0.945, y, p.soft);
    }
    _headlight(c, w, h, 0.062, 0.52, p);
    _grille(c, w, h, 0.045, 0.55, 0.045, 0.10, p);
    _mirror(c, w, h, 0.155, 0.40, p);
  }

  // ---- MIXER (cement) -----------------------------------------------------
  void _mixer(Canvas c, double w, double h, _Bp p) {
    // cab
    final cab = _path(w, h, (path, t) {
      path.moveTo(t.x(0.042), t.y(0.73));
      path.lineTo(t.x(0.04), t.y(0.42));
      path.quadraticBezierTo(t.x(0.04), t.y(0.34), t.x(0.075), t.y(0.31));
      path.lineTo(t.x(0.095), t.y(0.30));
      path.lineTo(t.x(0.20), t.y(0.30));
      path.lineTo(t.x(0.20), t.y(0.73));
      path.close();
    });
    _stroke(c, cab, p);
    _line(c, w, h, 0.20, 0.62, 0.96, 0.62, p.line);
    // windshield
    final ws = _path(w, h, (path, t) {
      path.moveTo(t.x(0.05), t.y(0.41));
      path.lineTo(t.x(0.082), t.y(0.31));
      path.lineTo(t.x(0.155), t.y(0.31));
      path.lineTo(t.x(0.155), t.y(0.41));
      path.close();
    });
    c.drawPath(ws, p.glass);
    c.drawPath(ws, p.line);
    // mixer drum (big tilted barrel)
    final drum = _path(w, h, (path, t) {
      path.moveTo(t.x(0.255), t.y(0.60));
      path.quadraticBezierTo(t.x(0.27), t.y(0.40), t.x(0.40), t.y(0.30));
      path.quadraticBezierTo(t.x(0.62), t.y(0.18), t.x(0.85), t.y(0.30));
      path.quadraticBezierTo(t.x(0.93), t.y(0.355), t.x(0.92), t.y(0.45));
      path.quadraticBezierTo(t.x(0.915), t.y(0.55), t.x(0.86), t.y(0.60));
      path.close();
    });
    _stroke(c, drum, p);
    // drum spiral ribs
    final rib = Paint()
      ..color = _softColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = p.sw * 0.7;
    for (int i = 0; i < 5; i++) {
      final fx = 0.34 + i * 0.12;
      c.drawLine(Offset(fx * w, 0.34 * h), Offset((fx - 0.05) * w, 0.58 * h), rib);
    }
    // feed funnel (top rear)
    final funnel = _path(w, h, (path, t) {
      path.moveTo(t.x(0.86), t.y(0.30));
      path.lineTo(t.x(0.91), t.y(0.205));
      path.lineTo(t.x(0.965), t.y(0.205));
      path.lineTo(t.x(0.93), t.y(0.33));
      path.close();
    });
    _stroke(c, funnel, p, bold: false);
    // chute
    _line(c, w, h, 0.92, 0.50, 0.975, 0.62, p.line);
    _headlight(c, w, h, 0.062, 0.52, p);
    _grille(c, w, h, 0.045, 0.55, 0.045, 0.10, p);
    _mirror(c, w, h, 0.155, 0.40, p);
  }

  // ---- shared small details ----------------------------------------------

  void _headlight(Canvas c, double w, double h, double fx, double fy, _Bp p) {
    final r = 0.022 * h;
    c.drawCircle(Offset(fx * w, fy * h), r, p.line);
    c.drawCircle(Offset(fx * w, fy * h), r * 0.45, p.soft);
  }

  void _taillight(Canvas c, double w, double h, double fx, double fy, _Bp p) {
    final rect = Rect.fromCenter(
        center: Offset(fx * w, fy * h), width: 0.018 * w, height: 0.055 * h);
    c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)), p.line);
  }

  void _grille(Canvas c, double w, double h, double fx, double fy, double fw,
      double fh, _Bp p) {
    final rect = Rect.fromLTWH(fx * w, fy * h, fw * w, fh * h);
    c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), p.soft);
    const n = 3;
    for (int i = 1; i <= n; i++) {
      final y = rect.top + rect.height * i / (n + 1);
      c.drawLine(Offset(rect.left + 1, y), Offset(rect.right - 1, y), p.soft);
    }
  }

  void _mirror(Canvas c, double w, double h, double fx, double fy, _Bp p) {
    final rect = Rect.fromLTWH(fx * w, fy * h, 0.02 * w, 0.045 * h);
    c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), p.line);
    c.drawLine(Offset(fx * w, (fy + 0.045) * h),
        Offset((fx + 0.02) * w, (fy + 0.07) * h), p.soft);
  }

  void _drawWheel(Canvas c, Offset center, double r, _Bp p) {
    // tire (outer)
    c.drawCircle(center, r, p.bold);
    // tread ring
    c.drawCircle(center, r * 0.86,
        Paint()
          ..color = _softColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = p.sw * 0.6);
    // rim
    c.drawCircle(center, r * 0.55, p.line);
    // spokes
    final spoke = Paint()
      ..color = _softColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = p.sw * 0.8
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final ang = i * math.pi / 3;
      c.drawLine(
        center,
        center.translate(r * 0.5 * math.cos(ang), r * 0.5 * math.sin(ang)),
        spoke,
      );
    }
    // hub
    c.drawCircle(center, r * 0.16, p.line);
  }

  // ---- labels -------------------------------------------------------------

  void _drawLabels(Canvas canvas, double w, double h) {
    _text(canvas, label, Offset(0.075 * w, 0.075 * h),
        fontSize: h * 0.072, weight: FontWeight.w700, alpha: 0.95);
    _text(canvas, 'H2HFLEET · ENGINEERING VIEW',
        Offset(0.075 * w, 0.155 * h),
        fontSize: h * 0.046, weight: FontWeight.w500, alpha: 0.55, letter: 1.2);
  }

  void _text(Canvas canvas, String s, Offset at,
      {required double fontSize,
      FontWeight weight = FontWeight.w500,
      double alpha = 1,
      double letter = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: _lineColor.withValues(alpha: alpha),
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: letter,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 0.7 * 9999);
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter old) =>
      old.archetype != archetype || old.label != label;
}

/// ตัวช่วยแปลงสัดส่วน → พิกัดจริง
class _PT {
  final double w, h;
  const _PT(this.w, this.h);
  double x(double fx) => fx * w;
  double y(double fy) => fy * h;
}
