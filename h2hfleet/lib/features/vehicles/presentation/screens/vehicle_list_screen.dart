import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/vehicle_model.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../providers/vehicles_provider.dart';
import '../../../maintenance/vehicle_diagram.dart';
import '../../../map/gps_device_dialog.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_dialog.dart';
import 'edit_vehicle_dialog.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  String? _selectedVehicleId;
  String? _filterType;
  String _searchQuery = '';
  bool _showBlueprintMode = false;

  VehicleArchetype _getArchetype(String type) => archetypeFromType(type);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(strProvider);
    final isTh = s.isTh;
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isTh ? 'รถของฉัน (Fleet Management)' : 'My Vehicles (Fleet Management)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(vehiclesProvider.notifier).fetchVehicles(),
            tooltip: isTh ? 'รีเฟรช' : 'Refresh',
          ),
          if (isLargeScreen)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const AddVehicleDialog(),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(s.addVehicle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_car_rounded,
                        size: 56, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isTh ? 'ยังไม่มีรถในระบบ' : 'No vehicles in system',
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isTh ? 'กดปุ่ม "เพิ่มรถ" เพื่อเริ่มต้นใช้งาน' : 'Tap "Add Vehicle" to get started',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const AddVehicleDialog(),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(s.addVehicle),
                  ),
                ],
              ),
            );
          }

          // Filter vehicles based on search and type
          final filtered = vehicles.where((v) {
            final matchSearch = _searchQuery.isEmpty ||
                v.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (v.brand).toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (v.model).toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (v.nickName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
            final matchType = _filterType == null || v.vehicleType == _filterType;
            return matchSearch && matchType;
          }).toList();

          // Auto-select first vehicle if none selected on large screen
          final activeVehicle = vehicles.firstWhere(
            (v) => v.id == _selectedVehicleId,
            orElse: () => filtered.isNotEmpty ? filtered.first : vehicles.first,
          );

          if (isLargeScreen) {
            // ═══════════════ iPad & Web Dual-Pane Fleet Inspector ═══════════════
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Left Column (Fleet Grid & Search: 48%) ───
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search & Filter Bar
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: isTh ? 'ค้นหาทะเบียน, รุ่น, หรือชื่อเล่น...' : 'Search plate, model, or nickname...',
                                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Vehicle Type Pills
                          SizedBox(
                            height: 32,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _TypeFilterPill(
                                  label: isTh ? 'ทั้งหมด (${vehicles.length})' : 'All (${vehicles.length})',
                                  isSelected: _filterType == null,
                                  onTap: () => setState(() => _filterType = null),
                                ),
                                ...['รถเก๋ง', 'SUV', 'รถกระบะ', 'รถตู้', 'รถบรรทุก', 'รถห้องเย็น', 'VIP'].map((t) {
                                  final count = vehicles.where((v) => v.vehicleType == t).length;
                                  if (count == 0) return const SizedBox.shrink();
                                  return _TypeFilterPill(
                                    label: '$t ($count)',
                                    isSelected: _filterType == t,
                                    onTap: () => setState(() => _filterType = _filterType == t ? null : t),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),

                          // Vehicle List
                          Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      isTh ? 'ไม่พบรถตามตัวกรองที่ระบุ' : 'No vehicles found matching filter',
                                      style: const TextStyle(color: Color(0xFF64748B)),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final v = filtered[index];
                                      final isSelected = v.id == activeVehicle.id;
                                      return _FleetVehicleListTile(
                                        vehicle: v,
                                        isSelected: isSelected,
                                        onTap: () => setState(() => _selectedVehicleId = v.id),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // ─── Right Column (Vehicle Detail & Telemetry Inspector: 52%) ───
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        activeVehicle.plateNumber,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: activeVehicle.status == 'active' ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        activeVehicle.status == 'active'
                                            ? (isTh ? '🟢 พร้อมใช้งาน' : '🟢 Ready / Active')
                                            : (isTh ? '🟡 กำลังซ่อมบำรุง' : '🟡 In Maintenance'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: activeVehicle.status == 'active' ? const Color(0xFF059669) : const Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF0284C7), size: 20),
                                      tooltip: isTh ? 'แก้ไขข้อมูลรถ' : 'Edit Vehicle',
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) => EditVehicleDialog(vehicle: activeVehicle),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.gps_fixed_rounded, color: Color(0xFF059669), size: 20),
                                      tooltip: isTh ? 'ตั้งค่ากล่อง GPS' : 'Configure GPS Device',
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) => GpsDeviceDialog(vehicle: activeVehicle),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Vehicle Visual: Real Photo or 3D Blueprint Toggle
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _showBlueprintMode
                                              ? '📐 CAD Blueprint Spec'
                                              : (isTh ? '📷 ภาพถ่ายรถจริง (Fleet Photo)' : '📷 Fleet Photo'),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => setState(() => _showBlueprintMode = !_showBlueprintMode),
                                          icon: Icon(_showBlueprintMode ? Icons.image_rounded : Icons.architecture_rounded, size: 14, color: const Color(0xFF38BDF8)),
                                          label: Text(
                                            _showBlueprintMode
                                                ? (isTh ? 'สลับดูภาพจริง' : 'View Real Photo')
                                                : (isTh ? 'สลับดูพิมพ์เขียว CAD' : 'View CAD Blueprint'),
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_showBlueprintMode)
                                    VehicleDiagram(
                                      archetype: _getArchetype(activeVehicle.vehicleType),
                                      customHeaderTitle: '${activeVehicle.plateNumber} · ${activeVehicle.brand} ${activeVehicle.model}',
                                      height: 160,
                                    )
                                  else
                                    _buildVehiclePhotoInspector(activeVehicle),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Vehicle Specifications Matrix
                            Text(
                              isTh ? '📋 ข้อมูลจำเพาะของรถ (Specifications)' : '📋 Vehicle Specifications',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                children: [
                                  _SpecRow(label: 'ยี่ห้อ / แบรนด์', value: activeVehicle.brand.isNotEmpty ? activeVehicle.brand : '–'),
                                  const Divider(height: 12, color: Color(0xFFE2E8F0)),
                                  _SpecRow(label: 'รุ่น / Model', value: activeVehicle.model.isNotEmpty ? activeVehicle.model : '–'),
                                  const Divider(height: 12, color: Color(0xFFE2E8F0)),
                                  _SpecRow(label: 'ประเภทรถยนต์', value: activeVehicle.vehicleType),
                                  const Divider(height: 12, color: Color(0xFFE2E8F0)),
                                  _SpecRow(label: 'ประเภทเชื้อเพลิง', value: activeVehicle.fuelType == 'diesel' ? 'ดีเซล (Diesel)' : activeVehicle.fuelType),
                                  const Divider(height: 12, color: Color(0xFFE2E8F0)),
                                  _SpecRow(label: 'ปีที่ผลิต', value: '${activeVehicle.year}'),
                                  if (activeVehicle.nickName != null && activeVehicle.nickName!.isNotEmpty) ...[
                                    const Divider(height: 12, color: Color(0xFFE2E8F0)),
                                    _SpecRow(label: 'ชื่อเรียก / ชื่อเล่น', value: activeVehicle.nickName!),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // GPS Telematics Box
                            const Text('🛰️ อุปกรณ์ติดตาม GPS (Telematics Device)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.router_rounded, color: Color(0xFF059669), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activeVehicle.gpsDeviceImei != null && activeVehicle.gpsDeviceImei!.isNotEmpty
                                              ? 'IMEI: ${activeVehicle.gpsDeviceImei}'
                                              : 'ยังไม่ได้ผูกกล่อง GPS ฮาร์ดแวร์',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          activeVehicle.gpsDeviceType != null
                                              ? 'โปรโตคอล: ${activeVehicle.gpsDeviceType!.toUpperCase()} · ส่งข้อมูลทุก 5 วินาที'
                                              : 'ใช้พิกัดจากแอปคนขับ (Driver Mode Telemetry)',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF059669)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (_) => GpsDeviceDialog(vehicle: activeVehicle),
                                    ),
                                    child: const Text('ตั้งค่า', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // ═══════════════ Mobile Single-Column Layout ═══════════════
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(vehiclesProvider.notifier).fetchVehicles(),
            child: Column(
              children: [
                // Summary bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_car_rounded,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Text('รถทั้งหมด ${vehicles.length} คัน',
                              style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success, shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text('ใช้งาน ${vehicles.where((v) => v.status == 'active').length} คัน',
                              style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => VehicleCard(
                      vehicle: filtered[index],
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => EditVehicleDialog(vehicle: filtered[index]),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('เกิดข้อผิดพลาด', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$error', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.read(vehiclesProvider.notifier).fetchVehicles(),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isLargeScreen ? null : FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddVehicleDialog(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มรถ',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildVehiclePhotoInspector(VehicleModel activeVehicle) {
    final hasImage = activeVehicle.imageUrl != null && activeVehicle.imageUrl!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => EditVehicleDialog(vehicle: activeVehicle),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        child: Container(
          height: 170,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
          ),
          child: Stack(
            children: [
              // Vehicle Photo / Banner
              if (hasImage)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                    child: buildVehicleImageWidget(activeVehicle.imageUrl!),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF38BDF8), size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${activeVehicle.brand.isNotEmpty ? activeVehicle.brand : "รถยนต์"} ${activeVehicle.model} (${activeVehicle.vehicleType})',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.upload_file_rounded, size: 13, color: Color(0xFF38BDF8)),
                              SizedBox(width: 4),
                              Text('แตะเพื่ออัปโหลด / แก้ไขภาพรถ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Glassmorphic Action Bar (Always allows quick edit / change photo)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(hasImage ? Icons.photo_camera_rounded : Icons.add_photo_alternate_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        hasImage ? 'เปลี่ยนภาพถ่าย' : 'เพิ่มภาพถ่าย',
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildVehicleImageWidget(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      } catch (_) {}
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 36),
        ),
      ),
    );
  }
}

class _TypeFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeFilterPill({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}

class _FleetVehicleListTile extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FleetVehicleListTile({required this.vehicle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            // Vehicle Avatar (Image or Icon)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasImage
                    ? _VehicleListScreenState.buildVehicleImageWidget(vehicle.imageUrl!)
                    : Icon(
                        Icons.local_shipping_rounded,
                        color: isSelected ? Colors.white : const Color(0xFF0284C7),
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vehicle.plateNumber,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? const Color(0xFF0284C7) : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        vehicle.vehicleType,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vehicle.brand} ${vehicle.model} · ${vehicle.year}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      ],
    );
  }
}

