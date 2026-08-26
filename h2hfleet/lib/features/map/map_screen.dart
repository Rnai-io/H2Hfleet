import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_exporter.dart';
import '../../models/vehicle_location_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/driver_location_model.dart';
import '../../providers/driver_location_provider.dart';
import '../../providers/vehicle_location_provider.dart';
import '../../providers/vehicles_provider.dart';
import 'gps_device_dialog.dart';
import 'route_history_screen.dart';
import 'route_navigation_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  VehicleLocationModel? _selected;
  bool _simulatorMode = false;
  VehicleModel? _simulatorTarget;

  // ─── Navigation & Waypoint Planning State ─────────────────────────────────
  bool _isRoutingMode = false;
  RouteWaypoint? _startPoint;
  final List<RouteWaypoint> _pickupStops = [];
  final List<RouteWaypoint> _restStops = [];
  RouteWaypoint? _destinationPoint;

  List<LatLng> _routePolyline = [];
  double _routeDistanceKm = 0;
  double _routeDurationMinutes = 0;
  double _routeFuelCost = 0;
  bool _isCalculatingRoute = false;

  static const _defaultCenter = LatLng(13.7563, 100.5018); // Bangkok

  @override
  void initState() {
    super.initState();
    // Default initial Start & Destination demo
    _startPoint = RouteWaypoint(
      id: 'start_def',
      name: 'ศูนย์กระจายสินค้า วังน้อย (DC)',
      point: const LatLng(14.2272, 100.7145),
      type: WaypointType.start,
      address: 'ถ.พหลโยธิน อ.วังน้อย จ.อยุธยา',
    );
    _destinationPoint = RouteWaypoint(
      id: 'dest_def',
      name: 'ท่าเรือแหลมฉบัง (Laem Chabang)',
      point: const LatLng(13.0827, 100.8847),
      type: WaypointType.destination,
      address: 'ต.ทุ่งสุขลา อ.ศรีราชา จ.ชลบุรี',
    );
  }

  Future<void> _calculateRoutePath() async {
    if (_startPoint == null || _destinationPoint == null) {
      setState(() {
        _routePolyline = [];
        _routeDistanceKm = 0;
        _routeDurationMinutes = 0;
        _routeFuelCost = 0;
      });
      return;
    }

    setState(() => _isCalculatingRoute = true);

    // Combine all stops in logical sequence: Start -> Pickups -> Rest Stops -> Destination
    final intermediatePoints = [
      ..._pickupStops.map((s) => s.point),
      ..._restStops.map((s) => s.point),
    ];

    try {
      final res = await RouteNavigationService.calculateRoute(
        start: _startPoint!.point,
        waypoints: intermediatePoints,
        destination: _destinationPoint!.point,
      );

      if (mounted) {
        setState(() {
          _routePolyline = res['polyline'] as List<LatLng>;
          _routeDistanceKm = (res['distanceKm'] as num).toDouble();
          _routeDurationMinutes = (res['durationMinutes'] as num).toDouble();
          _routeFuelCost = (res['fuelCost'] as num).toDouble();
          _isCalculatingRoute = false;
        });

        // Fit map bounds safely
        if (_routePolyline.length >= 2) {
          try {
            final bounds = LatLngBounds.fromPoints(_routePolyline);
            if (bounds.north != bounds.south || bounds.east != bounds.west) {
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(40),
                  maxZoom: 16,
                ),
              );
            } else {
              _mapController.move(_routePolyline.first, 14);
            }
          } catch (_) {}
        } else if (_routePolyline.isNotEmpty) {
          _mapController.move(_routePolyline.first, 14);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isCalculatingRoute = false);
    }
  }

  void _openLocationSearchSheet(BuildContext context, {WaypointType? targetType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSearchModal(
        onSelectLocation: (result, type) {
          final waypoint = RouteWaypoint(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: result.title,
            point: result.point,
            type: type,
            address: result.subtitle,
          );

          setState(() {
            _isRoutingMode = true;
            if (type == WaypointType.start) {
              _startPoint = waypoint;
            } else if (type == WaypointType.destination) {
              _destinationPoint = waypoint;
            } else if (type == WaypointType.pickup) {
              _pickupStops.add(waypoint);
            } else if (type == WaypointType.rest) {
              _restStops.add(waypoint);
            }
          });

          _mapController.move(result.point, 13);
          _calculateRoutePath();
        },
        defaultType: targetType ?? WaypointType.destination,
      ),
    );
  }

  void _openInGoogleMaps() {
    if (_startPoint == null || _destinationPoint == null) return;
    final allStops = [
      ..._pickupStops.map((s) => s.point),
      ..._restStops.map((s) => s.point),
    ];
    final url = RouteNavigationService.buildGoogleMapsNavigationUrl(
      start: _startPoint!.point,
      waypoints: allStops,
      destination: _destinationPoint!.point,
    );

    openExternalUrl(url);
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เปิดการนำทาง Google Maps แล้ว! 🚀 (คัดลอกลิงก์เรียบร้อย)'),
        backgroundColor: Color(0xFF0284C7),
      ),
    );
  }

  Future<void> _dispatchRouteToLine() async {
    if (_startPoint == null || _destinationPoint == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('line_user_id') ?? '';

    final stopsSummary = StringBuffer();
    stopsSummary.writeln('🗺️ แผนการเดินทางกองรถ H2HFleet:');
    stopsSummary.writeln('🚩 จุดเริ่มต้น: ${_startPoint!.name}');
    for (int i = 0; i < _pickupStops.length; i++) {
      stopsSummary.writeln('📦 จุดแวะรับ ${i + 1}: ${_pickupStops[i].name}');
    }
    for (int i = 0; i < _restStops.length; i++) {
      stopsSummary.writeln('☕ จุดพักรถ: ${_restStops[i].name}');
    }
    stopsSummary.writeln('🏁 ปลายทาง: ${_destinationPoint!.name}');
    stopsSummary.writeln('------------------------------');
    stopsSummary.writeln('📏 ระยะทาง: ${_routeDistanceKm.toStringAsFixed(1)} กม.');
    stopsSummary.writeln('⏱️ เวลาโดยประมาณ: ${(_routeDurationMinutes / 60).toStringAsFixed(1)} ชม.');
    stopsSummary.writeln('⛽ ประมาณการค่าน้ำมัน: ฿${_routeFuelCost.toStringAsFixed(0)}');

    final allStops = [
      ..._pickupStops.map((s) => s.point),
      ..._restStops.map((s) => s.point),
    ];
    final gmapsUrl = RouteNavigationService.buildGoogleMapsNavigationUrl(
      start: _startPoint!.point,
      waypoints: allStops,
      destination: _destinationPoint!.point,
    );
    stopsSummary.writeln('🔗 นำทาง: $gmapsUrl');

    if (userId.isEmpty) {
      await Clipboard.setData(ClipboardData(text: stopsSummary.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คัดลอกรายละเอียดเส้นทางแล้ว! (ยังไม่ได้ตั้ง LINE ID)'),
            backgroundColor: Color(0xFF0284C7),
          ),
        );
      }
      return;
    }

    try {
      const supabaseUrl = 'https://rdobhvuiadmsqdfugrlp.supabase.co';
      const anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkb2JodnVpYWRtc3FkZnVncmxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNjU4MzMsImV4cCI6MjA5NDc0MTgzM30.7pvs8B38unEmBkPmP14lfgDrr59wjd-WroMiqpkIzvY';

      final dio = Dio(BaseOptions(validateStatus: (status) => true));
      final res = await dio.post(
        '$supabaseUrl/functions/v1/line-push-message',
        data: jsonEncode({
          'userId': userId,
          'message': stopsSummary.toString(),
        }),
        options: Options(headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        }),
      );

      if (mounted) {
        final ok = res.statusCode == 200;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'ส่งเส้นทางไปยัง LINE Bot สำเร็จ! 🚛📲' : 'LINE Error: ${res.data}'),
            backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(vehicleLocationsProvider);
    final driverLocsAsync = ref.watch(driverLocationsProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);

    final vehicleMap = vehiclesAsync.when(
      data: (list) => {for (final v in list) v.id: v},
      loading: () => <String, VehicleModel>{},
      error: (_, __) => <String, VehicleModel>{},
    );

    final driverMap = driverLocsAsync.when(
      data: (list) => {for (final d in list) d.vehicleId: d},
      loading: () => <String, DriverLocationModel>{},
      error: (_, __) => <String, DriverLocationModel>{},
    );

    final vehicleLocs = locationsAsync.valueOrNull ?? [];
    final driverLocs = driverLocsAsync.valueOrNull ?? [];
    final uniqueVehicleIds = {
      ...vehicleLocs.map((l) => l.vehicleId),
      ...driverLocs.map((d) => d.vehicleId),
    };
    final vehicleCount = uniqueVehicleIds.length;
    final activeDriverCount = driverLocs.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ─── 1. FlutterMap with Route & Markers ───────────────────────────
          locationsAsync.when(
            data: (locations) => _buildMap(locations, driverMap, vehicleMap),
            loading: () => const _MapPlaceholder(),
            error: (e, _) => _buildMap([], driverMap, vehicleMap),
          ),

          // ─── 2. Top Navigation Control Bar ────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Prominent Glass Back button
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 3,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(14),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF0F172A), size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Header Banner
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'แผนที่สด & ติดตามรถ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  _VehicleCountBadge(vehicleCount, activeDriverCount),
                                ],
                              ),
                              // Route Planner Toggle Chip
                              ActionChip(
                                avatar: Icon(
                                  _isRoutingMode ? Icons.close_rounded : Icons.alt_route_rounded,
                                  size: 14,
                                  color: _isRoutingMode ? Colors.white : const Color(0xFF0284C7),
                                ),
                                label: Text(
                                  _isRoutingMode ? 'ปิดนำทาง' : 'วางแผนเส้นทาง',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _isRoutingMode ? Colors.white : const Color(0xFF0284C7),
                                  ),
                                ),
                                backgroundColor: _isRoutingMode ? const Color(0xFF0284C7) : const Color(0xFFE0F2FE),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                onPressed: () {
                                  setState(() => _isRoutingMode = !_isRoutingMode);
                                  if (_isRoutingMode && _routePolyline.isEmpty) {
                                    _calculateRoutePath();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── 3. Floating Map Controls (Right Side) ────────────────────────
          Positioned(
            right: 12,
            top: 90,
            child: Column(
              children: [
                // Search Location FAB
                _MapFab(
                  icon: Icons.search_rounded,
                  tooltip: 'ค้นหาพิกัด / สถานที่',
                  color: const Color(0xFF0284C7),
                  onTap: () => _openLocationSearchSheet(context),
                ),
                const SizedBox(height: 8),

                // Calculate / Refresh Route
                if (_isRoutingMode) ...[
                  _MapFab(
                    icon: Icons.refresh_rounded,
                    tooltip: 'คำนวณเส้นทางใหม่',
                    color: const Color(0xFF7C3AED),
                    onTap: _calculateRoutePath,
                  ),
                  const SizedBox(height: 8),
                ],

                // Fit Screen FAB
                _MapFab(
                  icon: Icons.fit_screen_rounded,
                  tooltip: 'รวมรถทั้งหมดในจอ',
                  onTap: () {
                    final locs = locationsAsync.valueOrNull ?? [];
                    if (locs.isEmpty) return;
                    if (locs.length == 1) {
                      _mapController.move(LatLng(locs.first.lat, locs.first.lng), 14);
                      return;
                    }
                    try {
                      final bounds = LatLngBounds.fromPoints(
                        locs.map((l) => LatLng(l.lat, l.lng)).toList(),
                      );
                      if (bounds.north != bounds.south || bounds.east != bounds.west) {
                        _mapController.fitCamera(
                          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50), maxZoom: 16),
                        );
                      } else {
                        _mapController.move(LatLng(locs.first.lat, locs.first.lng), 14);
                      }
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 8),

                // Route History FAB
                if (vehiclesAsync.valueOrNull != null && vehiclesAsync.valueOrNull!.isNotEmpty) ...[
                  _MapFab(
                    icon: Icons.history_rounded,
                    tooltip: 'ประวัติการเดินทางย้อนหลัง',
                    color: const Color(0xFF059669),
                    onTap: () {
                      final targetVehicle = (_selected != null ? vehicleMap[_selected!.vehicleId] : null) ??
                          _simulatorTarget ??
                          vehiclesAsync.valueOrNull!.first;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteHistoryScreen(vehicle: targetVehicle),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                // Device Connection Dialog
                if (vehiclesAsync.valueOrNull != null && vehiclesAsync.valueOrNull!.isNotEmpty)
                  _MapFab(
                    icon: Icons.sensors_rounded,
                    tooltip: 'เชื่อมต่ออุปกรณ์ GPS',
                    onTap: () {
                      final targetVehicle = (_selected != null ? vehicleMap[_selected!.vehicleId] : null) ??
                          _simulatorTarget ??
                          vehiclesAsync.valueOrNull!.first;
                      showDialog(
                        context: context,
                        builder: (_) => GpsDeviceDialog(vehicle: targetVehicle),
                      );
                    },
                  ),
              ],
            ),
          ),

          // ─── 4. Navigation Waypoints HUD Panel (Bottom) ───────────────────
          if (_isRoutingMode)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: _RouteNavigationHUD(
                vehicle: (_selected != null ? vehicleMap[_selected!.vehicleId] : null) ??
                    _simulatorTarget ??
                    (vehiclesAsync.valueOrNull != null && vehiclesAsync.valueOrNull!.isNotEmpty
                        ? vehiclesAsync.valueOrNull!.first
                        : null),
                start: _startPoint,
                pickups: _pickupStops,
                rests: _restStops,
                destination: _destinationPoint,
                distanceKm: _routeDistanceKm,
                durationMinutes: _routeDurationMinutes,
                fuelCost: _routeFuelCost,
                isCalculating: _isCalculatingRoute,
                onAddStop: (type) => _openLocationSearchSheet(context, targetType: type),
                onRemoveStop: (waypoint) {
                  setState(() {
                    _pickupStops.removeWhere((s) => s.id == waypoint.id);
                    _restStops.removeWhere((s) => s.id == waypoint.id);
                  });
                  _calculateRoutePath();
                },
                onStartGoogleMaps: _openInGoogleMaps,
                onDispatchToLine: _dispatchRouteToLine,
                onTripCompleted: () {
                  final currentVehicle = (_selected != null ? vehicleMap[_selected!.vehicleId] : null) ??
                      _simulatorTarget ??
                      (vehiclesAsync.valueOrNull != null && vehiclesAsync.valueOrNull!.isNotEmpty
                          ? vehiclesAsync.valueOrNull!.first
                          : null);
                  showDialog(
                    context: context,
                    builder: (_) => _TripArrivalReportDialog(
                      vehicle: currentVehicle,
                      start: _startPoint,
                      pickups: _pickupStops,
                      rests: _restStops,
                      destination: _destinationPoint,
                      distanceKm: _routeDistanceKm,
                      durationMinutes: _routeDurationMinutes,
                      fuelCost: _routeFuelCost,
                    ),
                  );
                },
                onClearRoute: () {
                  setState(() {
                    _startPoint = null;
                    _destinationPoint = null;
                    _pickupStops.clear();
                    _restStops.clear();
                    _routePolyline.clear();
                    _isRoutingMode = false;
                  });
                },
              ),
            ),

          // ─── 5. Vehicle Detail Sheet ──────────────────────────────────────
          if (!_isRoutingMode && _selected != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _VehicleDetailSheet(
                location: _selected!,
                vehicle: vehicleMap[_selected!.vehicleId],
                onClose: () => setState(() => _selected = null),
                parentContext: context,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Map Builder ──────────────────────────────────────────────────────────
  Widget _buildMap(
    List<VehicleLocationModel> locations,
    Map<String, DriverLocationModel> drivers,
    Map<String, VehicleModel> vehicles,
  ) {
    final firstPoint = locations.isNotEmpty
        ? LatLng(locations.first.lat, locations.first.lng)
        : _startPoint?.point ?? _defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: firstPoint,
        initialZoom: 11,
        minZoom: 3,
        maxZoom: 18,
        onTap: (_, latLng) {
          if (_simulatorMode && _simulatorTarget != null) {
            final speed = 40.0 + (math.Random().nextDouble() * 60);
            ref.read(vehicleLocationsProvider.notifier).simulateLocation(
                  vehicleId: _simulatorTarget!.id,
                  lat: latLng.latitude,
                  lng: latLng.longitude,
                  speed: speed,
                );
          } else {
            setState(() => _selected = null);
          }
        },
      ),
      children: [
        // Base Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.h2hfleet.app',
        ),

        // Route Polyline Layer (Blue Glow)
        if (_routePolyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Outer Glow Shadow
              Polyline(
                points: _routePolyline,
                strokeWidth: 8.0,
                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
              ),
              // Core Neon Route Line
              Polyline(
                points: _routePolyline,
                strokeWidth: 5.0,
                color: const Color(0xFF2563EB),
              ),
            ],
          ),

        // Waypoint Markers Layer
        if (_isRoutingMode)
          MarkerLayer(
            markers: [
              if (_startPoint != null)
                _buildWaypointMarker(
                  _startPoint!,
                  'จุดเริ่มต้น',
                  const Color(0xFF10B981),
                  Icons.flag_circle_rounded,
                ),
              ..._pickupStops.asMap().entries.map((entry) => _buildWaypointMarker(
                    entry.value,
                    'แวะรับ ${entry.key + 1}',
                    const Color(0xFF0284C7),
                    Icons.inventory_2_rounded,
                  )),
              ..._restStops.map((r) => _buildWaypointMarker(
                    r,
                    'จุดพักรถ',
                    const Color(0xFFD97706),
                    Icons.local_cafe_rounded,
                  )),
              if (_destinationPoint != null)
                _buildWaypointMarker(
                  _destinationPoint!,
                  'ปลายทาง',
                  const Color(0xFFE11D48),
                  Icons.sports_score_rounded,
                ),
            ],
          ),

        // Vehicle Markers (Navy / Blue)
        MarkerLayer(
          markers: locations
              .map((loc) => _buildVehicleMarker(loc, vehicles[loc.vehicleId]))
              .toList(),
        ),

        // Driver Markers (Emerald Green)
        MarkerLayer(
          markers: drivers.values
              .map((d) => _buildDriverMarker(d, vehicles[d.vehicleId]))
              .toList(),
        ),
      ],
    );
  }

  // ─── Waypoint Marker Widget ───────────────────────────────────────────────
  Marker _buildWaypointMarker(
    RouteWaypoint waypoint,
    String label,
    Color color,
    IconData icon,
  ) {
    return Marker(
      point: waypoint.point,
      width: 100,
      height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ],
      ),
    );
  }

  Color _freshnessColor(DateTime updatedAt) {
    final age = DateTime.now().difference(updatedAt);
    if (age.inMinutes < 2) return const Color(0xFF10B981);
    if (age.inMinutes < 10) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Marker _buildVehicleMarker(VehicleLocationModel loc, VehicleModel? vehicle) {
    final isSelected = _selected?.vehicleId == loc.vehicleId;
    final markerColor = isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB);
    final freshnessColor = _freshnessColor(loc.updatedAt);

    return Marker(
      point: LatLng(loc.lat, loc.lng),
      width: 88,
      height: 88,
      child: GestureDetector(
        onTap: () {
          setState(() => _selected = loc);
          _mapController.move(LatLng(loc.lat, loc.lng), 14);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                vehicle?.plateNumber ?? '...',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Stack(
              alignment: Alignment.center,
              children: [
                if (loc.heading != null)
                  Transform.rotate(
                    angle: (loc.heading! * math.pi / 180),
                    child: Icon(
                      Icons.navigation_rounded,
                      color: markerColor.withValues(alpha: 0.4),
                      size: 44,
                    ),
                  ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: markerColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 17),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: freshnessColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildDriverMarker(DriverLocationModel driver, VehicleModel? vehicle) {
    return Marker(
      point: LatLng(driver.lat, driver.lng),
      width: 80,
      height: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_rounded, color: Colors.white, size: 9),
                const SizedBox(width: 2),
                Text(
                  vehicle?.plateNumber ?? 'คนขับ',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

// ─── Route Navigation HUD Widget ────────────────────────────────────────────
class _RouteNavigationHUD extends StatelessWidget {
  final VehicleModel? vehicle;
  final RouteWaypoint? start;
  final List<RouteWaypoint> pickups;
  final List<RouteWaypoint> rests;
  final RouteWaypoint? destination;
  final double distanceKm;
  final double durationMinutes;
  final double fuelCost;
  final bool isCalculating;
  final ValueChanged<WaypointType> onAddStop;
  final ValueChanged<RouteWaypoint> onRemoveStop;
  final VoidCallback onStartGoogleMaps;
  final VoidCallback onDispatchToLine;
  final VoidCallback onTripCompleted;
  final VoidCallback onClearRoute;

  const _RouteNavigationHUD({
    required this.vehicle,
    required this.start,
    required this.pickups,
    required this.rests,
    required this.destination,
    required this.distanceKm,
    required this.durationMinutes,
    required this.fuelCost,
    required this.isCalculating,
    required this.onAddStop,
    required this.onRemoveStop,
    required this.onStartGoogleMaps,
    required this.onDispatchToLine,
    required this.onTripCompleted,
    required this.onClearRoute,
  });

  @override
  Widget build(BuildContext context) {
    final plateStr = vehicle?.plateNumber ?? 'รถประจำงาน';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Summary Header with Specific Vehicle Plate Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.navigation_rounded, color: Color(0xFF0284C7), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'แผนการนำทาง [$plateStr]',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${vehicle?.brand ?? ''} ${vehicle?.model ?? ''} · วิ่งใช้งานอยู่ (Active Trip)',
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                onPressed: onClearRoute,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Route Stats Badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HudKpiItem(
                  icon: Icons.straighten_rounded,
                  color: const Color(0xFF0284C7),
                  label: 'ระยะทาง',
                  value: '${distanceKm.toStringAsFixed(1)} กม.',
                ),
                Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                _HudKpiItem(
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF059669),
                  label: 'เวลาโดยประมาณ',
                  value: durationMinutes >= 60
                      ? '${(durationMinutes / 60).toStringAsFixed(1)} ชม.'
                      : '${durationMinutes.toStringAsFixed(0)} นาที',
                ),
                Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                _HudKpiItem(
                  icon: Icons.local_gas_station_rounded,
                  color: const Color(0xFFE11D48),
                  label: 'ค่าน้ำมันประเมิน',
                  value: '฿${fuelCost.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Waypoints Summary Horizontal Chips
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Add Pickup Stop Action
                ActionChip(
                  avatar: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF0284C7)),
                  label: const Text('+ แวะรับสินค้า', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                  backgroundColor: const Color(0xFFF0F9FF),
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: EdgeInsets.zero,
                  onPressed: () => onAddStop(WaypointType.pickup),
                ),
                const SizedBox(width: 6),

                // Add Rest Stop Action
                ActionChip(
                  avatar: const Icon(Icons.coffee_rounded, size: 14, color: Color(0xFFD97706)),
                  label: const Text('+ จุดพักรถ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                  backgroundColor: const Color(0xFFFFFBEB),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: EdgeInsets.zero,
                  onPressed: () => onAddStop(WaypointType.rest),
                ),
                const SizedBox(width: 6),

                // Existing Pickups Chips
                ...pickups.map((p) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        avatar: const Icon(Icons.inventory_2_rounded, size: 12, color: Color(0xFF0284C7)),
                        label: Text(p.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        deleteIcon: const Icon(Icons.close_rounded, size: 12),
                        onDeleted: () => onRemoveStop(p),
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )),

                // Existing Rest Stops Chips
                ...rests.map((r) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        avatar: const Icon(Icons.local_cafe_rounded, size: 12, color: Color(0xFFD97706)),
                        label: Text(r.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        deleteIcon: const Icon(Icons.close_rounded, size: 12),
                        onDeleted: () => onRemoveStop(r),
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Action Buttons: Google Maps & LINE Broadcast
          Row(
            children: [
              // Google Maps External Nav
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onStartGoogleMaps,
                  icon: const Icon(Icons.navigation_rounded, size: 15),
                  label: const Text('🚀 เริ่มนำทาง (Google Maps)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Dispatch to LINE
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDispatchToLine,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 15),
                  label: const Text('ส่งเข้า LINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06C755),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Arrival & Export Trip Report Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTripCompleted,
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: const Text(
                '🏁 ถึงจุดหมาย · สรุปและ Export รายงานการเดินทาง',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trip Arrival & Export Report Dialog ─────────────────────────────────────
class _TripArrivalReportDialog extends StatefulWidget {
  final VehicleModel? vehicle;
  final RouteWaypoint? start;
  final List<RouteWaypoint> pickups;
  final List<RouteWaypoint> rests;
  final RouteWaypoint? destination;
  final double distanceKm;
  final double durationMinutes;
  final double fuelCost;

  const _TripArrivalReportDialog({
    required this.vehicle,
    required this.start,
    required this.pickups,
    required this.rests,
    required this.destination,
    required this.distanceKm,
    required this.durationMinutes,
    required this.fuelCost,
  });

  @override
  State<_TripArrivalReportDialog> createState() => _TripArrivalReportDialogState();
}

class _TripArrivalReportDialogState extends State<_TripArrivalReportDialog> {
  String _companyName = 'บริษัท ตัวอย่าง จำกัด (มหาชน)';
  String _companyTaxId = '–';

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  Future<void> _loadCompanyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final savedName = prefs.getString('company_name');
        _companyName = (savedName != null && savedName.trim().isNotEmpty)
            ? savedName.trim()
            : 'บริษัท ตัวอย่าง จำกัด (มหาชน)';
        _companyTaxId = prefs.getString('company_tax_id') ?? '–';
      });
    }
  }

  void _exportPrintTripSlip() {
    final nowStr = DateFormat('d MMMM yyyy, HH:mm', 'th_TH').format(DateTime.now());
    final plate = widget.vehicle?.plateNumber ?? 'ไม่ระบุ';
    final brandModel = '${widget.vehicle?.brand ?? ''} ${widget.vehicle?.model ?? ''}'.trim();
    final driverName = widget.vehicle?.nickName ?? 'พนักงานขับรถประจำงาน';

    final stopsHtml = StringBuffer();
    stopsHtml.writeln('<tr><td style="padding:8px; border:1px solid #E2E8F0; font-weight:bold; color:#10B981;">🚩 ต้นทาง (Start)</td><td style="padding:8px; border:1px solid #E2E8F0;">${widget.start?.name ?? 'ไม่ระบุ'} (${widget.start?.address ?? ''})</td></tr>');
    for (int i = 0; i < widget.pickups.length; i++) {
      stopsHtml.writeln('<tr><td style="padding:8px; border:1px solid #E2E8F0; font-weight:bold; color:#0284C7;">📦 จุดแวะรับที่ ${i + 1}</td><td style="padding:8px; border:1px solid #E2E8F0;">${widget.pickups[i].name} (${widget.pickups[i].address ?? ''})</td></tr>');
    }
    for (int i = 0; i < widget.rests.length; i++) {
      stopsHtml.writeln('<tr><td style="padding:8px; border:1px solid #E2E8F0; font-weight:bold; color:#D97706;">☕ จุดพักรถ ${i + 1}</td><td style="padding:8px; border:1px solid #E2E8F0;">${widget.rests[i].name} (${widget.rests[i].address ?? ''})</td></tr>');
    }
    stopsHtml.writeln('<tr><td style="padding:8px; border:1px solid #E2E8F0; font-weight:bold; color:#E11D48;">🏁 ปลายทาง (Destination)</td><td style="padding:8px; border:1px solid #E2E8F0;">${widget.destination?.name ?? 'ไม่ระบุ'} (${widget.destination?.address ?? ''})</td></tr>');

    final html = '''
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <title>ใบสรุปรายงานการเดินทางและส่งมอบงาน - $plate</title>
  <style>
    @page { size: A4; margin: 15mm; }
    body { font-family: 'Sarabun', 'Helvetica Neue', Arial, sans-serif; font-size: 13px; color: #1E293B; margin: 0; padding: 20px; }
    .header { border-bottom: 2px solid #1E3A8A; padding-bottom: 12px; margin-bottom: 16px; }
    .title { font-size: 20px; font-weight: bold; color: #1E3A8A; }
    .subtitle { font-size: 11px; color: #64748B; margin-top: 4px; }
    .kpi-box { display: flex; gap: 12px; margin-bottom: 16px; }
    .kpi-card { flex: 1; border: 1px solid #E2E8F0; background: #F8FAFC; border-radius: 8px; padding: 12px; text-align: center; }
    .kpi-val { font-size: 16px; font-weight: bold; color: #0F172A; margin-top: 4px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
    th { background: #1E3A8A; color: white; padding: 8px; font-size: 12px; text-align: left; }
    td { font-size: 12px; }
    .signatures { display: flex; justify-content: space-between; margin-top: 30px; }
    .sig-block { width: 45%; border-top: 1px dashed #94A3B8; text-align: center; padding-top: 8px; font-size: 11px; color: #64748B; }
  </style>
</head>
<body>
  <div class="header">
    <div class="title">$_companyName</div>
    <div class="subtitle">เลขประจำตัวผู้เสียภาษี: $_companyTaxId · เอกสารใบสรุปการเดินทางกองยานพาหนะ (Trip Dispatch Slip)</div>
    <div class="subtitle">วันที่ออกเอกสาร: $nowStr · ทะเบียนรถ: <strong>$plate</strong> ($brandModel) · พนักงานขับรถ: <strong>$driverName</strong></div>
  </div>

  <div class="kpi-box">
    <div class="kpi-card">
      <div style="font-size:11px; color:#64748B;">📏 ระยะทางรวม</div>
      <div class="kpi-val">${widget.distanceKm.toStringAsFixed(1)} กม.</div>
    </div>
    <div class="kpi-card">
      <div style="font-size:11px; color:#64748B;">⏱️ เวลาเดินทางรวม</div>
      <div class="kpi-val">${widget.durationMinutes >= 60 ? '${(widget.durationMinutes / 60).toStringAsFixed(1)} ชม.' : '${widget.durationMinutes.toStringAsFixed(0)} นาที'}</div>
    </div>
    <div class="kpi-card">
      <div style="font-size:11px; color:#64748B;">⛽ ค่าน้ำมันประเมิน</div>
      <div class="kpi-val">฿${widget.fuelCost.toStringAsFixed(0)}</div>
    </div>
    <div class="kpi-card">
      <div style="font-size:11px; color:#64748B;">📦 จุดแวะรับ/ส่ง</div>
      <div class="kpi-val">${widget.pickups.length} จุด</div>
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th style="width: 30%;">ประเภทจุดแวะ</th>
        <th>รายละเอียดสถานที่ / พิกัด</th>
      </tr>
    </thead>
    <tbody>
      $stopsHtml
    </tbody>
  </table>

  <div style="margin-top:20px; padding:10px; background:#F1F5F9; border-radius:8px; font-size:11px; color:#475569;">
    ✅ <strong>บันทึกสถานะการส่งมอบ:</strong> เดินทางถึงจุดหมายปลายทางเรียบร้อยแล้ว ยืนยันการส่งมอบสินค้าครบถ้วนตามพิกัด
  </div>

  <div class="signatures">
    <div class="sig-block">
      (............................................................)<br>
      ลงชื่อ พนักงานขับรถ ($driverName)<br>
      วันที่ ....../....../............
    </div>
    <div class="sig-block">
      (............................................................)<br>
      ลงชื่อ ผู้รับมอบสินค้า / เจ้าหน้าที่ควบคุมกองรถ<br>
      วันที่ ....../....../............
    </div>
  </div>
</body>
</html>
''';

    printHtmlReport(html);
  }

  @override
  Widget build(BuildContext context) {
    final plate = widget.vehicle?.plateNumber ?? 'ไม่ระบุ';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สรุปรายงานการเดินทาง [$plate]',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'ถึงจุดหมายปลายทางสำเร็จ · พร้อมบันทึก & ออกเอกสาร',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // KPI Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _HudKpiItem(
                    icon: Icons.straighten_rounded,
                    color: const Color(0xFF0284C7),
                    label: 'ระยะทางจริง',
                    value: '${widget.distanceKm.toStringAsFixed(1)} กม.',
                  ),
                  Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
                  _HudKpiItem(
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF059669),
                    label: 'เวลาเดินทาง',
                    value: widget.durationMinutes >= 60
                        ? '${(widget.durationMinutes / 60).toStringAsFixed(1)} ชม.'
                        : '${widget.durationMinutes.toStringAsFixed(0)} นาที',
                  ),
                  Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
                  _HudKpiItem(
                    icon: Icons.local_gas_station_rounded,
                    color: const Color(0xFFE11D48),
                    label: 'ค่าน้ำมันประเมิน',
                    value: '฿${widget.fuelCost.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Route Highlights List
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag_circle_rounded, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ต้นทาง: ${widget.start?.name ?? 'ไม่ระบุ'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (widget.pickups.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_rounded, color: Color(0xFF0284C7), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'จุดแวะรับ: ${widget.pickups.length} จุด (${widget.pickups.map((p) => p.name).join(', ')})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.sports_score_rounded, color: Color(0xFFE11D48), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ปลายทาง: ${widget.destination?.name ?? 'ไม่ระบุ'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Export PDF / Print Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _exportPrintTripSlip,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text(
                  '🖨️ พิมพ์ใบงานวิ่งรถ / บันทึกเป็น PDF (Print Trip Slip)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Close / Done Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('เสร็จสิ้น / ปิดหน้าต่าง'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudKpiItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _HudKpiItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 3),
            Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}

// ─── Location Search Modal ──────────────────────────────────────────────────
class _LocationSearchModal extends StatefulWidget {
  final void Function(LocationSearchResult result, WaypointType type) onSelectLocation;
  final WaypointType defaultType;

  const _LocationSearchModal({
    required this.onSelectLocation,
    required this.defaultType,
  });

  @override
  State<_LocationSearchModal> createState() => _LocationSearchModalState();
}

class _LocationSearchModalState extends State<_LocationSearchModal> {
  final _searchCtrl = TextEditingController();
  List<LocationSearchResult> _results = RouteNavigationService.presetHubs;
  bool _isSearching = false;
  late WaypointType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
  }

  void _onSearch(String query) async {
    setState(() => _isSearching = true);
    final list = await RouteNavigationService.searchLocations(query);
    if (mounted) {
      setState(() {
        _results = list;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modal Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          const Row(
            children: [
              Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 22),
              SizedBox(width: 8),
              Text(
                'ค้นหาพิกัด & วางจุดหมายการนำทาง',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Waypoint Type Selector Pills
          const Text('กำหนดเป็นตำแหน่ง:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Row(
            children: [
              _TypePill(
                label: '🚩 จุดเริ่มต้น',
                isSelected: _selectedType == WaypointType.start,
                color: const Color(0xFF10B981),
                onTap: () => setState(() => _selectedType = WaypointType.start),
              ),
              const SizedBox(width: 6),
              _TypePill(
                label: '📦 แวะรับ/ส่ง',
                isSelected: _selectedType == WaypointType.pickup,
                color: const Color(0xFF0284C7),
                onTap: () => setState(() => _selectedType = WaypointType.pickup),
              ),
              const SizedBox(width: 6),
              _TypePill(
                label: '☕ จุดพักรถ',
                isSelected: _selectedType == WaypointType.rest,
                color: const Color(0xFFD97706),
                onTap: () => setState(() => _selectedType = WaypointType.rest),
              ),
              const SizedBox(width: 6),
              _TypePill(
                label: '🏁 ปลายทาง',
                isSelected: _selectedType == WaypointType.destination,
                color: const Color(0xFFE11D48),
                onTap: () => setState(() => _selectedType = WaypointType.destination),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Text Field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อคลังสินค้า, ท่าเรือ, ถนน หรือจังหวัด...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: _onSearch,
            ),
          ),

          const SizedBox(height: 12),

          if (_isSearching)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
          else ...[
            Text(
              _searchCtrl.text.isEmpty ? 'ศูนย์กระจายสินค้า & คลังหลักแนะนำ' : 'ผลการค้นหา (${_results.length})',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final item = _results[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.warehouse_rounded, color: Color(0xFF0284C7), size: 18),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${item.category} · ${item.subtitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                      trailing: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF0284C7), size: 18),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelectLocation(item, _selectedType);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Map FAB Button ─────────────────────────────────────────────────────────
class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;

  const _MapFab({
    required this.icon,
    required this.onTap,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color ?? const Color(0xFF0F172A), size: 20),
          ),
        ),
      ),
    );
  }
}

// ─── Vehicle Count Badge ────────────────────────────────────────────────────
class _VehicleCountBadge extends StatelessWidget {
  final int vehicleCount;
  final int driverCount;

  const _VehicleCountBadge(this.vehicleCount, this.driverCount);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_shipping_rounded, size: 12, color: const Color(0xFF2563EB)),
        const SizedBox(width: 3),
        Text('รถ $vehicleCount', style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Icon(Icons.person_rounded, size: 12, color: const Color(0xFF10B981)),
        const SizedBox(width: 3),
        Text('คนขับ $driverCount', style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─── Vehicle Detail Bottom Sheet ────────────────────────────────────────────
class _VehicleDetailSheet extends StatelessWidget {
  final VehicleLocationModel location;
  final VehicleModel? vehicle;
  final VoidCallback onClose;
  final BuildContext parentContext;

  const _VehicleDetailSheet({
    required this.location,
    required this.vehicle,
    required this.onClose,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final speed = location.speed ?? 0;
    final timeStr = DateFormat('HH:mm:ss').format(location.updatedAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF1E3A8A), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle?.plateNumber ?? 'ไม่ทราบทะเบียน',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${vehicle?.brand ?? ''} ${vehicle?.model ?? ''} · อัปเดตล่าสุด $timeStr',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: onClose),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text('ความเร็ว', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Text('${speed.toStringAsFixed(0)} กม./ชม.', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text('พิกัด GPS', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Text('${location.lat.toStringAsFixed(3)}, ${location.lng.toStringAsFixed(3)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vehicle != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(
                      builder: (_) => RouteHistoryScreen(
                        vehicle: vehicle!,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history_rounded, size: 16),
                label: const Text('ดูประวัติเส้นทางย้อนหลัง'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Placeholder ────────────────────────────────────────────────────────────
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          SizedBox(height: 12),
          Text('กำลังโหลดแผนที่สด...', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
