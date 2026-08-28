import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/maintenance_model.dart';
import '../../providers/locale_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/vehicles_provider.dart';
import 'add_maintenance_dialog.dart';
import 'part_categories.dart';
import 'vehicle_diagram.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  String? _categoryFilter;
  String? _vehicleFilter;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(strProvider);
    final maintenanceAsync = ref.watch(maintenanceProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicleMap = vehiclesAsync.valueOrNull != null
        ? {for (final v in vehiclesAsync.valueOrNull!) v.id: v}
        : <String, dynamic>{};
    final currencyFormat = NumberFormat('#,##0', 'th_TH');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 54,
        leading: const _ProminentBackButton(),
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.build_circle_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.maintenanceTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  s.isTh ? 'ระบบวิเคราะห์และซ่อมบำรุงเชิงป้องกัน' : 'Preventive Telematics & Service Log',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.isTh ? 'รีเฟรชข้อมูล' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.invalidate(maintenanceProvider),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddMaintenanceDialog(initialVehicleId: _vehicleFilter),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          s.addMaintenance,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1E3A8A),
        onRefresh: () async => ref.invalidate(maintenanceProvider),
        child: maintenanceAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          ),
          error: (e, _) => Center(
            child: Text('${s.error}: $e', style: const TextStyle(color: AppColors.danger)),
          ),
          data: (records) {
            final filtered = records.where((r) {
              if (_categoryFilter != null && r.partCategory != _categoryFilter) return false;
              if (_vehicleFilter != null && r.vehicleId != _vehicleFilter) return false;
              return true;
            }).toList();

            final pendingCount = records.where((r) => r.status == 'pending').length;
            final completedCount = records.where((r) => r.status == 'completed').length;
            final totalCost = records.fold<double>(0, (sum, r) => sum + r.cost);

            final selectedVehicle = _vehicleFilter != null ? vehicleMap[_vehicleFilter] : null;
            final currentArchetype = archetypeFromType(selectedVehicle?.vehicleType as String?);
            final diagramHeaderLabel = selectedVehicle != null
                ? '${selectedVehicle.plateNumber} · ${selectedVehicle.brand ?? ''} ${selectedVehicle.model ?? ''}'
                : (s.isTh ? 'กองรถทั้งหมด · Blueprint กลาง' : 'Fleet Blueprint · Diagnostic HUD');

            final isLargeScreen = MediaQuery.of(context).size.width >= 800;

            if (isLargeScreen) {
              // ═══════════════ iPad & Web Balanced Dual-Pane Layout ═══════════════
              final isDesktop = MediaQuery.of(context).size.width >= 1100;
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Left Column (Blueprint & Controls: 44%) ───
                    Expanded(
                      flex: isDesktop ? 5 : 5,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. KPI Summary Banner
                            _ModernSummaryBanner(
                              pendingCount: pendingCount,
                              completedCount: completedCount,
                              totalCost: totalCost,
                              currencyFormat: currencyFormat,
                              s: s,
                            ),
                            const SizedBox(height: 12),

                            // 2. High-Tech Blueprint (Proportional Height)
                            VehicleDiagram(
                              archetype: currentArchetype,
                              customHeaderTitle: diagramHeaderLabel,
                              selectedCategory: _categoryFilter,
                              aspectRatio: isDesktop ? 16 / 8.2 : 16 / 8.5,
                              onCategorySelected: (key) {
                                setState(() {
                                  _categoryFilter = _categoryFilter == key ? null : key;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // 3. Vehicle Selector Chips
                            if (vehicleMap.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.directions_car_filled_rounded, size: 14, color: Color(0xFF1E3A8A)),
                                  const SizedBox(width: 5),
                                  Text(
                                    s.isTh ? 'เลือกรถเพื่อเปลี่ยนภาพพิมพ์เขียว' : 'Select Vehicle Profile',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 34,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _VehicleSelectorPill(
                                      label: s.isTh ? 'รถทั้งหมด' : 'All Vehicles',
                                      icon: Icons.all_inclusive_rounded,
                                      isSelected: _vehicleFilter == null,
                                      onTap: () => setState(() => _vehicleFilter = null),
                                    ),
                                    ...vehicleMap.values.map((v) {
                                      final isSel = _vehicleFilter == v.id;
                                      return _VehicleSelectorPill(
                                        label: '${v.plateNumber}',
                                        subLabel: v.vehicleType as String?,
                                        icon: Icons.local_shipping_rounded,
                                        isSelected: isSel,
                                        onTap: () => setState(() => _vehicleFilter = isSel ? null : v.id),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 4. Part Category Filter Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.category_rounded, size: 14, color: Color(0xFFD97706)),
                                    const SizedBox(width: 5),
                                    Text(
                                      s.selectPartCategory,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                                if (_categoryFilter != null)
                                  GestureDetector(
                                    onTap: () => setState(() => _categoryFilter = null),
                                    child: Text(
                                      s.isTh ? 'ล้างตัวกรอง' : 'Clear Filter',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _ModernCategoryChipCompact(
                                  icon: Icons.apps_rounded,
                                  label: s.allCategories,
                                  color: const Color(0xFF0F172A),
                                  selected: _categoryFilter == null,
                                  onTap: () => setState(() => _categoryFilter = null),
                                ),
                                ...kPartCategories.map((cat) {
                                  final count = records.where((r) => r.partCategory == cat.key).length;
                                  return _ModernCategoryChipCompact(
                                    icon: cat.icon,
                                    label: cat.label(s.isTh),
                                    color: cat.color,
                                    badgeCount: count > 0 ? count : null,
                                    selected: _categoryFilter == cat.key,
                                    onTap: () => setState(() => _categoryFilter = _categoryFilter == cat.key ? null : cat.key),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // ─── Right Column (Service Records: 56%) ───
                    Expanded(
                      flex: isDesktop ? 6 : 6,
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
                            // Header Bar with Filter Badges
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.history_rounded, size: 18, color: Color(0xFF1E3A8A)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  s.isTh ? 'ประวัติการซ่อมบำรุง' : 'Service Records',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${filtered.length}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                                const Spacer(),
                                if (_categoryFilter != null || _vehicleFilter != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _categoryFilter != null ? 'หมวด: $_categoryFilter' : 'รถ: ${selectedVehicle?.plateNumber}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _categoryFilter = null;
                                            _vehicleFilter = null;
                                          }),
                                          child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0284C7)),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // List of Records or Empty State
                            Expanded(
                              child: filtered.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.build_circle_outlined, size: 32, color: Color(0xFF1E3A8A)),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            s.noMaintenanceRecords,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            s.isTh ? 'กดปุ่ม "+ เพิ่มรายการซ่อมบำรุง" เพื่อบันทึกข้อมูลแรก' : 'Click + Add Maintenance to log your first service',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, i) => Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _ModernMaintenanceCard(
                                          record: filtered[i],
                                          vehicleLabel: vehicleMap[filtered[i].vehicleId]?.plateNumber ?? '–',
                                          currencyFormat: currencyFormat,
                                          s: s,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // ═══════════════ Mobile 1-Screen Compact Layout ═══════════════
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Slim KPI Summary Banner
                  _ModernSummaryBanner(
                    pendingCount: pendingCount,
                    completedCount: completedCount,
                    totalCost: totalCost,
                    currencyFormat: currencyFormat,
                    s: s,
                  ),
                  const SizedBox(height: 8),

                  // 2. Compact Balanced Blueprint Diagram (Height: 125px)
                  VehicleDiagram(
                    archetype: currentArchetype,
                    customHeaderTitle: diagramHeaderLabel,
                    selectedCategory: _categoryFilter,
                    height: 125,
                    onCategorySelected: (key) {
                      setState(() {
                        _categoryFilter = _categoryFilter == key ? null : key;
                      });
                    },
                  ),
                  const SizedBox(height: 6),

                  // 3. Vehicle Selector (Slim Horizontal Bar)
                  if (vehicleMap.isNotEmpty) ...[
                    SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _VehicleSelectorPill(
                            label: s.isTh ? 'รถทั้งหมด' : 'All',
                            icon: Icons.all_inclusive_rounded,
                            isSelected: _vehicleFilter == null,
                            onTap: () => setState(() => _vehicleFilter = null),
                          ),
                          ...vehicleMap.values.map((v) {
                            final isSel = _vehicleFilter == v.id;
                            return _VehicleSelectorPill(
                              label: '${v.plateNumber}',
                              icon: Icons.local_shipping_rounded,
                              isSelected: isSel,
                              onTap: () => setState(() => _vehicleFilter = isSel ? null : v.id),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // 4. Part Categories (Slim Horizontal Bar)
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _ModernCategoryChipCompact(
                          icon: Icons.apps_rounded,
                          label: s.allCategories,
                          color: const Color(0xFF0F172A),
                          selected: _categoryFilter == null,
                          onTap: () => setState(() => _categoryFilter = null),
                        ),
                        ...kPartCategories.map((cat) {
                          final count = records.where((r) => r.partCategory == cat.key).length;
                          return _ModernCategoryChipCompact(
                            icon: cat.icon,
                            label: cat.label(s.isTh),
                            color: cat.color,
                            badgeCount: count > 0 ? count : null,
                            selected: _categoryFilter == cat.key,
                            onTap: () => setState(() => _categoryFilter = _categoryFilter == cat.key ? null : cat.key),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 5. Records Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 15, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 4),
                          Text(
                            s.isTh ? 'รายการซ่อมบำรุง (${filtered.length})' : 'Records (${filtered.length})',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      if (_categoryFilter != null || _vehicleFilter != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _categoryFilter = null;
                            _vehicleFilter = null;
                          }),
                          child: Text(
                            s.isTh ? 'ล้างตัวกรองทั้งหมด' : 'Clear Filters',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 6. Maintenance Records List (fills remaining viewport)
                  Expanded(
                    child: filtered.isEmpty
                        ? _EmptyState(message: s.noMaintenanceRecords)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ModernMaintenanceCard(
                                record: filtered[i],
                                vehicleLabel: vehicleMap[filtered[i].vehicleId]?.plateNumber ?? '–',
                                currencyFormat: currencyFormat,
                                s: s,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── 1. Modern Summary KPI Banner ───────────────────────────────────────────
class _ModernSummaryBanner extends StatelessWidget {
  final int pendingCount;
  final int completedCount;
  final double totalCost;
  final NumberFormat currencyFormat;
  final dynamic s;

  const _ModernSummaryBanner({
    required this.pendingCount,
    required this.completedCount,
    required this.totalCost,
    required this.currencyFormat,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pending
          Expanded(
            flex: 3,
            child: _KpiPill(
              label: s.isTh ? 'รอดำเนินการ' : 'Pending',
              value: '$pendingCount',
              color: const Color(0xFFF59E0B),
              icon: Icons.hourglass_top_rounded,
            ),
          ),
          Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.15)),
          // Completed
          Expanded(
            flex: 3,
            child: _KpiPill(
              label: s.isTh ? 'เสร็จสิ้น' : 'Done',
              value: '$completedCount',
              color: const Color(0xFF10B981),
              icon: Icons.check_circle_rounded,
            ),
          ),
          Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.15)),
          // Total Cost
          Expanded(
            flex: 4,
            child: _KpiPill(
              label: s.isTh ? 'ค่าใช้จ่ายรวม' : 'Total Cost',
              value: '฿${currencyFormat.format(totalCost)}',
              color: const Color(0xFF38BDF8),
              icon: Icons.payments_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _KpiPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 2. Horizontal Vehicle Selector Pill ────────────────────────────────────
class _VehicleSelectorPill extends StatelessWidget {
  final String label;
  final String? subLabel;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleSelectorPill({
    required this.label,
    this.subLabel,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (subLabel != null && subLabel!.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  '($subLabel)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 3. Modern Category Chip (Compact & Standard) ───────────────────────────
class _ModernCategoryChipCompact extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int? badgeCount;
  final bool selected;
  final VoidCallback onTap;

  const _ModernCategoryChipCompact({
    required this.icon,
    required this.label,
    required this.color,
    this.badgeCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.12 : 0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.3) : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// ─── 4. Modern Maintenance Record Card ──────────────────────────────────────
class _ModernMaintenanceCard extends ConsumerWidget {
  final MaintenanceModel record;
  final String vehicleLabel;
  final NumberFormat currencyFormat;
  final dynamic s;

  const _ModernMaintenanceCard({
    required this.record,
    required this.vehicleLabel,
    required this.currencyFormat,
    required this.s,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'overdue':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return s.statusCompleted as String;
      case 'overdue':
        return s.statusOverdue as String;
      default:
        return s.statusPending as String;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = partCategoryByKey(record.partCategory);
    final statusColor = _statusColor(record.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon or Photo
            if (record.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  record.photoUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _CategoryIconBadge(cat: cat),
                ),
              )
            else
              _CategoryIconBadge(cat: cat),
            const SizedBox(width: 12),

            // Content Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.partName?.isNotEmpty == true ? record.partName! : record.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: statusColor, size: 5),
                            const SizedBox(width: 3),
                            Text(
                              _statusLabel(record.status),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.directions_car_rounded, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Text(
                        vehicleLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                      const Text(' · ', style: TextStyle(color: Color(0xFFCBD5E1))),
                      Text(
                        cat.label(s.isTh),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cat.color),
                      ),
                    ],
                  ),
                  if (record.description != null && record.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '฿${currencyFormat.format(record.cost)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      if (record.status != 'completed')
                        ElevatedButton.icon(
                          onPressed: () => ref.read(maintenanceProvider.notifier).markCompleted(record.id),
                          icon: const Icon(Icons.check_rounded, size: 12),
                          label: Text(s.markCompleted as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                        ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(s.confirmDelete as String),
                              content: Text(s.confirmDeleteRecord as String),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(s.cancel as String),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    s.delete as String,
                                    style: const TextStyle(color: Color(0xFFEF4444)),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(maintenanceProvider.notifier).deleteMaintenance(record.id);
                          }
                        },
                      ),
                    ],
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

class _CategoryIconBadge extends StatelessWidget {
  final PartCategory cat;
  const _CategoryIconBadge({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cat.color.withValues(alpha: 0.15), cat.color.withValues(alpha: 0.25)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cat.color.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Icon(cat.icon, color: cat.color, size: 24),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.build_circle_rounded, size: 44, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Prominent Glass Back Button ────────────────────────────────────────────
class _ProminentBackButton extends StatelessWidget {
  const _ProminentBackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
