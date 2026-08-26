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

            return CustomScrollView(
              slivers: [
                // 1. KPI Summary Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _ModernSummaryBanner(
                      pendingCount: pendingCount,
                      completedCount: completedCount,
                      totalCost: totalCost,
                      currencyFormat: currencyFormat,
                      s: s,
                    ),
                  ),
                ),

                // 2. High-Tech Engineering Blueprint Diagram
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: VehicleDiagram(
                      archetype: currentArchetype,
                      customHeaderTitle: diagramHeaderLabel,
                      selectedCategory: _categoryFilter,
                      onCategorySelected: (key) {
                        setState(() {
                          _categoryFilter = _categoryFilter == key ? null : key;
                        });
                      },
                    ),
                  ),
                ),

                // 3. Vehicle Selector Bar (Horizontal Selector Chips)
                if (vehicleMap.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_car_filled_rounded, size: 16, color: Color(0xFF1E3A8A)),
                              const SizedBox(width: 6),
                              Text(
                                s.isTh ? 'เลือกรถเพื่อเปลี่ยนพิมพ์เขียว (CAD View)' : 'Select Vehicle Profile',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 38,
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
                        ],
                      ),
                    ),
                  ),

                // 4. Part Category Visual Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.category_rounded, size: 16, color: Color(0xFFD97706)),
                            const SizedBox(width: 6),
                            Text(
                              s.selectPartCategory,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (_categoryFilter != null)
                          GestureDetector(
                            onTap: () => setState(() => _categoryFilter = null),
                            child: Text(
                              s.isTh ? 'ล้างตัวกรอง' : 'Clear Filter',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 8.0;
                        final cols = constraints.maxWidth < 360 ? 3 : (constraints.maxWidth < 600 ? 4 : 6);
                        final itemWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;

                        final chips = <Widget>[
                          _ModernCategoryChip(
                            icon: Icons.apps_rounded,
                            label: s.allCategories,
                            color: const Color(0xFF0F172A),
                            selected: _categoryFilter == null,
                            onTap: () => setState(() => _categoryFilter = null),
                          ),
                          ...kPartCategories.map((cat) {
                            final count = records.where((r) => r.partCategory == cat.key).length;
                            return _ModernCategoryChip(
                              icon: cat.icon,
                              label: cat.label(s.isTh),
                              color: cat.color,
                              badgeCount: count > 0 ? count : null,
                              selected: _categoryFilter == cat.key,
                              onTap: () => setState(() =>
                                  _categoryFilter = _categoryFilter == cat.key ? null : cat.key),
                            );
                          }),
                        ];

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: chips.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
                        );
                      },
                    ),
                  ),
                ),

                // 5. Maintenance Records Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 16, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 6),
                        Text(
                          s.isTh ? 'รายการซ่อมบำรุง (${filtered.length})' : 'Service Records (${filtered.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 6. Maintenance Records List
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(message: s.noMaintenanceRecords),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ModernMaintenanceCard(
                            record: filtered[i],
                            vehicleLabel: vehicleMap[filtered[i].vehicleId]?.plateNumber ?? '–',
                            currencyFormat: currencyFormat,
                            s: s,
                          ),
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
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
          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
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
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (subLabel != null && subLabel!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '($subLabel)',
                  style: TextStyle(
                    fontSize: 10,
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

// ─── 3. Modern Category Chip ────────────────────────────────────────────────
class _ModernCategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int? badgeCount;
  final bool selected;
  final VoidCallback onTap;

  const _ModernCategoryChip({
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
        height: 64,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.06 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? color : color.withValues(alpha: 0.8), size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? color : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
            if (badgeCount != null)
              Positioned(
                top: 0,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
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
