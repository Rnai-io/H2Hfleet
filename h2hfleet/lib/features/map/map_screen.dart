import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vehicle_location_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/driver_location_model.dart';
import '../../providers/driver_location_provider.dart';
import '../../providers/vehicle_location_provider.dart';
import '../../providers/vehicles_provider.dart';
import 'route_history_screen.dart';

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

  static const _defaultCenter = LatLng(13.7563, 100.5018); // Bangkok

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
    // นับ unique vehicles (รถ 1 คันมีได้ทั้ง vehicle marker และ driver marker)
    final uniqueVehicleIds = {
      ...vehicleLocs.map((l) => l.vehicleId),
      ...driverLocs.map((d) => d.vehicleId),
    };
    final vehicleCount = uniqueVehicleIds.length;
    final activeDriverCount = driverLocs.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Map
          locationsAsync.when(
            data: (locations) => _buildMap(locations, driverMap, vehicleMap),
            loading: () => const _MapPlaceholder(),
            error: (e, _) => _buildMap([], driverMap, vehicleMap),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  // Back button
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_back_rounded,
                            color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.map_rounded,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'สถานะ Online',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _VehicleCountBadge(vehicleCount, activeDriverCount),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fit all button
          Positioned(
            right: 12,
            bottom: _selected != null ? 220 : 130,
            child: _MapFab(
              icon: Icons.fit_screen_rounded,
              onTap: () {
                final locs = locationsAsync.valueOrNull ?? [];
                if (locs.isEmpty) return;
                if (locs.length == 1) {
                  _mapController.move(
                    LatLng(locs.first.lat, locs.first.lng),
                    14,
                  );
                  return;
                }
                final bounds = LatLngBounds.fromPoints(
                  locs.map((l) => LatLng(l.lat, l.lng)).toList(),
                );
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(60),
                  ),
                );
              },
            ),
          ),

          // Refresh button
          Positioned(
            right: 12,
            bottom: _selected != null ? 170 : 78,
            child: _MapFab(
              icon: Icons.refresh_rounded,
              onTap: () => ref.read(vehicleLocationsProvider.notifier).refresh(),
            ),
          ),

          // Simulator toggle button
          Positioned(
            right: 12,
            bottom: _selected != null ? 120 : 26,
            child: _simulatorMode
                ? Material(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 3,
                    child: InkWell(
                      onTap: () => setState(() {
                        _simulatorMode = false;
                        _simulatorTarget = null;
                      }),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.science_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('ออกจาก Simulator',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  )
                : _MapFab(
                    icon: Icons.science_rounded,
                    onTap: () => _showSimulatorDialog(context, vehicleMap),
                  ),
          ),

          // Simulator hint banner
          if (_simulatorMode)
            Positioned(
              left: 12,
              right: 12,
              bottom: _selected != null ? 280 : 140,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _simulatorTarget != null
                            ? 'แตะแผนที่เพื่อย้าย ${_simulatorTarget!.plateNumber}'
                            : 'กรุณาเลือกรถก่อน',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Vehicle detail bottom sheet
          if (_selected != null)
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

  Widget _buildMap(
    List<VehicleLocationModel> locations,
    Map<String, DriverLocationModel> drivers,
    Map<String, VehicleModel> vehicles,
  ) {
    final firstPoint = locations.isNotEmpty
        ? LatLng(locations.first.lat, locations.first.lng)
        : drivers.isNotEmpty
            ? LatLng(drivers.values.first.lat, drivers.values.first.lng)
            : _defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: firstPoint,
        initialZoom: 12,
        onTap: (_, latLng) {
          if (_simulatorMode && _simulatorTarget != null) {
            // Simulator: ย้ายรถไปยังจุดที่แตะ
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
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.h2hfleet.app',
        ),
        // Vehicle markers (สีน้ำเงิน)
        MarkerLayer(
          markers: locations
              .map((loc) => _buildVehicleMarker(loc, vehicles[loc.vehicleId]))
              .toList(),
        ),
        // Driver markers (สีเขียว)
        MarkerLayer(
          markers: drivers.values
              .map((d) => _buildDriverMarker(d, vehicles[d.vehicleId]))
              .toList(),
        ),
      ],
    );
  }

  // สีตามความสดใหม่ของข้อมูล
  Color _freshnessColor(DateTime updatedAt) {
    final age = DateTime.now().difference(updatedAt);
    if (age.inMinutes < 2) return AppColors.success;
    if (age.inMinutes < 10) return AppColors.warning;
    return AppColors.danger;
  }

  Marker _buildVehicleMarker(VehicleLocationModel loc, VehicleModel? vehicle) {
    final isSelected = _selected?.vehicleId == loc.vehicleId;
    final isSimTarget = _simulatorMode && _simulatorTarget?.id == loc.vehicleId;
    final markerColor = isSimTarget
        ? AppColors.warning
        : isSelected
            ? AppColors.primary
            : const Color(0xFF2563EB);
    final freshnessColor = _freshnessColor(loc.updatedAt);

    return Marker(
      point: LatLng(loc.lat, loc.lng),
      width: 88,
      height: 88,
      child: GestureDetector(
        onTap: () {
          if (_simulatorMode) {
            setState(() => _simulatorTarget = vehicle);
          } else {
            setState(() => _selected = loc);
            _mapController.move(LatLng(loc.lat, loc.lng), 15);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Plate label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
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
            // Marker icon with heading arrow
            Stack(
              alignment: Alignment.center,
              children: [
                // Heading arrow (ถ้ามี)
                if (loc.heading != null)
                  Transform.rotate(
                    angle: (loc.heading! * math.pi / 180),
                    child: Icon(
                      Icons.navigation_rounded,
                      color: markerColor.withValues(alpha: 0.5),
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
                  child: const Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 17),
                ),
                // สถานะจุดเล็ก (freshness indicator)
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
          // Label คนขับ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success,
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
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Driver icon circle
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
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

  // Dialog เลือกรถสำหรับ Simulator
  void _showSimulatorDialog(BuildContext context, Map<String, VehicleModel> vehicleMap) {
    if (vehicleMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีรถในระบบ กรุณาเพิ่มรถก่อน')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science_rounded, color: AppColors.warning, size: 20),
                SizedBox(width: 8),
                Text('GPS Simulator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            Text('เลือกรถที่ต้องการ simulate แล้วแตะบนแผนที่เพื่อย้ายตำแหน่ง',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ...vehicleMap.values.map((v) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.local_shipping_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(v.plateNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(v.nickName ?? '${v.brand} ${v.model}'.trim()),
                  onTap: () {
                    setState(() {
                      _simulatorMode = true;
                      _simulatorTarget = v;
                    });
                    Navigator.of(context).pop();
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F0F8),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _VehicleCountBadge extends StatelessWidget {
  final int vehicleCount;
  final int driverCount;
  const _VehicleCountBadge(this.vehicleCount, this.driverCount);

  Widget _chip(String label, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );

  @override
  Widget build(BuildContext context) {
    if (vehicleCount == 0 && driverCount == 0) {
      return _chip('ไม่มีออนไลน์', AppColors.textHint, AppColors.surface);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (vehicleCount > 0)
          _chip('🚛 รถ $vehicleCount', AppColors.primary, AppColors.primarySurface),
        if (vehicleCount > 0 && driverCount > 0)
          const SizedBox(width: 6),
        if (driverCount > 0)
          _chip('👤 คนขับ $driverCount', AppColors.success, AppColors.successSurface),
      ],
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}

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
    final timeFmt = DateFormat('d MMM HH:mm');
    final updatedAgo = DateTime.now().difference(location.updatedAt);
    final agoText = updatedAgo.inMinutes < 1
        ? 'เมื่อกี้'
        : '${updatedAgo.inMinutes} นาทีที่แล้ว';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
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
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle?.plateNumber ?? 'ไม่ทราบ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      vehicle?.nickName ??
                          '${vehicle?.brand ?? ''} ${vehicle?.model ?? ''}'.trim(),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textHint, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ปุ่มดูเส้นทาง
          if (vehicle != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  onClose();
                  Navigator.of(parentContext).push(MaterialPageRoute(
                    builder: (_) => RouteHistoryScreen(vehicle: vehicle!),
                  ));
                },
                icon: const Icon(Icons.route_rounded, size: 18),
                label: const Text('ดูเส้นทาง & วิเคราะห์',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoTile(
                icon: Icons.speed_rounded,
                label: 'ความเร็ว',
                value: location.speed != null
                    ? '${location.speed!.toStringAsFixed(0)} กม./ชม.'
                    : '-',
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              _InfoTile(
                icon: Icons.location_on_rounded,
                label: 'พิกัด',
                value:
                    '${location.lat.toStringAsFixed(4)}, ${location.lng.toStringAsFixed(4)}',
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              _InfoTile(
                icon: Icons.access_time_rounded,
                label: 'อัปเดต',
                value: '$agoText\n${timeFmt.format(location.updatedAt.toLocal())}',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
