import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/gps_log_model.dart';
import '../../models/vehicle_model.dart';
import '../../providers/gps_log_provider.dart';

class RouteHistoryScreen extends ConsumerStatefulWidget {
  final VehicleModel vehicle;
  const RouteHistoryScreen({super.key, required this.vehicle});

  @override
  ConsumerState<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends ConsumerState<RouteHistoryScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late TabController _tabCtrl;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  RouteQuery get _query =>
      RouteQuery(vehicleId: widget.vehicle.id, date: _selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      locale: const Locale('th'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(gpsLogsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.vehicle.plateNumber,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            Text(
              widget.vehicle.nickName ??
                  '${widget.vehicle.brand} ${widget.vehicle.model}'.trim(),
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
        ),
        actions: [
          // Date picker
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded,
                color: Colors.white, size: 16),
            label: Text(
              DateFormat('d MMM').format(_selectedDate),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'เส้นทาง'),
            Tab(text: 'วิเคราะห์'),
          ],
        ),
      ),
      body: logsAsync.when(
        data: (logs) => TabBarView(
          controller: _tabCtrl,
          children: [
            _RouteMapTab(logs: logs, mapController: _mapController),
            _AnalyticsTab(logs: logs, date: _selectedDate),
          ],
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text('โหลดข้อมูลไม่สำเร็จ\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 1: เส้นทางบนแผนที่ ──────────────────────────────────────
class _RouteMapTab extends StatelessWidget {
  final List<GpsLogModel> logs;
  final MapController mapController;

  const _RouteMapTab({required this.logs, required this.mapController});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _EmptyRoute();
    }

    final points = logs.map((l) => LatLng(l.lat, l.lng)).toList();
    final first = points.first;
    final last = points.last;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: last,
            initialZoom: 13,
            onMapReady: () {
              if (points.length > 1) {
                final bounds = LatLngBounds.fromPoints(points);
                mapController.fitCamera(
                  CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(48)),
                );
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.h2hfleet.app',
            ),
            // เส้นทาง
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 4,
                  color: AppColors.primary,
                  borderStrokeWidth: 1.5,
                  borderColor: Colors.white,
                ),
              ],
            ),
            // จุด GPS แต่ละจุด (ถ้าน้อยกว่า 100 จุด)
            if (logs.length <= 100)
              CircleLayer(
                circles: logs.map((l) {
                  final isStop = l.speed <= 5;
                  return CircleMarker(
                    point: LatLng(l.lat, l.lng),
                    radius: 4,
                    color: isStop
                        ? AppColors.danger.withValues(alpha: 0.7)
                        : AppColors.primary.withValues(alpha: 0.5),
                    borderColor: Colors.white,
                    borderStrokeWidth: 1,
                  );
                }).toList(),
              ),
            // Marker จุดเริ่มต้น
            MarkerLayer(
              markers: [
                Marker(
                  point: first,
                  width: 32,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                // Marker จุดสิ้นสุด
                Marker(
                  point: last,
                  width: 32,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.stop_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Legend
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendItem(
                    color: AppColors.success, icon: Icons.play_arrow_rounded, label: 'จุดเริ่มต้น'),
                const SizedBox(height: 4),
                _LegendItem(
                    color: AppColors.danger, icon: Icons.stop_rounded, label: 'จุดสิ้นสุด'),
                const SizedBox(height: 4),
                _LegendItem(
                    color: AppColors.danger, isCircle: true, label: 'จอดรถ'),
                const SizedBox(height: 4),
                _LegendItem(
                    color: AppColors.primary, isCircle: true, label: 'วิ่งอยู่'),
              ],
            ),
          ),
        ),

        // Point count badge
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6)
              ],
            ),
            child: Text(
              '${logs.length} จุด',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab 2: วิเคราะห์ ─────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final List<GpsLogModel> logs;
  final DateTime date;

  const _AnalyticsTab({required this.logs, required this.date});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _EmptyRoute();
    }

    final analytics = computeAnalytics(logs);
    final timeFmt = DateFormat('HH:mm');
    final totalMinutes = analytics.movingMinutes + analytics.idleMinutes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _AnalyticCard(
                  icon: Icons.route_rounded,
                  label: 'ระยะทาง',
                  value: '${analytics.distanceKm.toStringAsFixed(1)} กม.',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnalyticCard(
                  icon: Icons.speed_rounded,
                  label: 'ความเร็วสูงสุด',
                  value: '${analytics.maxSpeed.toStringAsFixed(0)} กม./ชม.',
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AnalyticCard(
                  icon: Icons.timer_rounded,
                  label: 'เวลาวิ่ง',
                  value: '${analytics.movingMinutes} นาที',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnalyticCard(
                  icon: Icons.pause_circle_rounded,
                  label: 'เวลาจอด',
                  value: '${analytics.idleMinutes} นาที',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Moving vs Idle bar
          if (totalMinutes > 0) ...[
            _SectionTitle('สัดส่วนการใช้งาน'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          Flexible(
                            flex: analytics.movingMinutes,
                            child: Container(color: AppColors.success),
                          ),
                          Flexible(
                            flex: analytics.idleMinutes == 0
                                ? 1
                                : analytics.idleMinutes,
                            child: Container(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _BarLegend(
                          color: AppColors.success,
                          label: 'วิ่ง',
                          percent: totalMinutes > 0
                              ? (analytics.movingMinutes / totalMinutes * 100)
                                  .toStringAsFixed(0)
                              : '0'),
                      const SizedBox(width: 16),
                      _BarLegend(
                          color: AppColors.warning,
                          label: 'จอด',
                          percent: totalMinutes > 0
                              ? (analytics.idleMinutes / totalMinutes * 100)
                                  .toStringAsFixed(0)
                              : '0'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Speed profile (simple chart)
          _SectionTitle('ความเร็วตลอดเส้นทาง'),
          const SizedBox(height: 10),
          Container(
            height: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: _SpeedChart(logs: logs),
          ),
          const SizedBox(height: 16),

          // Timeline
          _SectionTitle('ไทม์ไลน์การเดินทาง'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _buildTimelineItem(
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.success,
                  label: 'เริ่มต้น',
                  time: timeFmt.format(logs.first.recordedAt),
                  detail:
                      '${logs.first.lat.toStringAsFixed(4)}, ${logs.first.lng.toStringAsFixed(4)}',
                  isFirst: true,
                ),
                _buildTimelineItem(
                  icon: Icons.speed_rounded,
                  color: AppColors.primary,
                  label: 'ความเร็วเฉลี่ย',
                  time: '',
                  detail: '${analytics.avgSpeed.toStringAsFixed(0)} กม./ชม.',
                ),
                _buildTimelineItem(
                  icon: Icons.straighten_rounded,
                  color: AppColors.warning,
                  label: 'ระยะทางรวม',
                  time: '',
                  detail: '${analytics.distanceKm.toStringAsFixed(2)} กม.',
                ),
                _buildTimelineItem(
                  icon: Icons.stop_rounded,
                  color: AppColors.danger,
                  label: 'สิ้นสุด',
                  time: timeFmt.format(logs.last.recordedAt),
                  detail:
                      '${logs.last.lat.toStringAsFixed(4)}, ${logs.last.lng.toStringAsFixed(4)}',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color color,
    required String label,
    required String time,
    required String detail,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (time.isNotEmpty)
            Text(time,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
        ],
      ),
    );
  }
}

// ── Speed Chart ─────────────────────────────────────────────────
class _SpeedChart extends StatelessWidget {
  final List<GpsLogModel> logs;
  const _SpeedChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();
    final maxSpeed =
        logs.map((l) => l.speed).reduce((a, b) => a > b ? a : b);
    if (maxSpeed == 0) {
      return const Center(
        child: Text('รถจอดตลอดวัน',
            style: TextStyle(color: AppColors.textHint, fontSize: 12)),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final step = w / (logs.length - 1).clamp(1, logs.length);

      return CustomPaint(
        size: Size(w, h),
        painter: _SpeedPainter(logs: logs, maxSpeed: maxSpeed, step: step),
      );
    });
  }
}

class _SpeedPainter extends CustomPainter {
  final List<GpsLogModel> logs;
  final double maxSpeed;
  final double step;

  _SpeedPainter(
      {required this.logs, required this.maxSpeed, required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.length < 2) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    final fillPath = ui.Path();

    for (int i = 0; i < logs.length; i++) {
      final x = i * step;
      final y = size.height - (logs[i].speed / maxSpeed * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo((logs.length - 1) * step, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Max speed line
    final maxPaint = Paint()
      ..color = AppColors.danger.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(0, 0), Offset(size.width, 0), maxPaint);
  }

  @override
  bool shouldRepaint(_SpeedPainter old) => old.logs != logs;
}

// ── Helpers ─────────────────────────────────────────────────────
class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_rounded, size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text('ไม่มีข้อมูลการเดินทาง\nในวันที่เลือก',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _AnalyticCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String label;
  final bool isCircle;
  const _LegendItem(
      {required this.color,
      this.icon,
      required this.label,
      this.isCircle = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isCircle
            ? Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle))
            : Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _BarLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String percent;
  const _BarLegend(
      {required this.color, required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text('$label $percent%',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
