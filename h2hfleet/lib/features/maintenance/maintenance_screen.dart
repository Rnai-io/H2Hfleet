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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(s.maintenanceTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.invalidate(maintenanceProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddMaintenanceDialog(initialVehicleId: _vehicleFilter),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addMaintenance, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(maintenanceProvider),
        child: maintenanceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _SummaryBanner(
                      pendingCount: pendingCount,
                      completedCount: completedCount,
                      totalCost: totalCost,
                      currencyFormat: currencyFormat,
                    ),
                  ),
                ),

                // Vehicle diagram — tap a zone to filter by part category
                // เปลี่ยนรูปตามรถที่เลือกในตัวกรองด้านล่าง (ถ้าไม่เลือก = แบบเริ่มต้น)
                SliverToBoxAdapter(
                  child: Builder(builder: (context) {
                    final selectedVehicle =
                        _vehicleFilter != null ? vehicleMap[_vehicleFilter] : null;
                    final diagramLabel = selectedVehicle != null
                        ? '${selectedVehicle.plateNumber}'
                            '${(selectedVehicle.vehicleType as String?)?.isNotEmpty == true ? ' · ${selectedVehicle.vehicleType}' : ''}'
                        : null;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: VehicleDiagram(
                          vehicleType: selectedVehicle?.vehicleType as String?,
                          label: diagramLabel,
                          selectedCategory: _categoryFilter,
                          onCategorySelected: (key) => setState(() => _categoryFilter = key),
                        ),
                      ),
                    );
                  }),
                ),

                // Part category visual picker / filter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(s.selectPartCategory,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 92,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _CategoryChip(
                          icon: Icons.apps_rounded,
                          label: s.allCategories,
                          color: AppColors.textSecondary,
                          selected: _categoryFilter == null,
                          onTap: () => setState(() => _categoryFilter = null),
                        ),
                        ...kPartCategories.map((cat) => _CategoryChip(
                              icon: cat.icon,
                              label: cat.label(s.isTh),
                              color: cat.color,
                              selected: _categoryFilter == cat.key,
                              onTap: () => setState(
                                  () => _categoryFilter = _categoryFilter == cat.key ? null : cat.key),
                            )),
                      ],
                    ),
                  ),
                ),

                // Vehicle filter chips
                if (vehicleMap.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(s.allCategories, style: const TextStyle(fontSize: 12)),
                            selected: _vehicleFilter == null,
                            onSelected: (_) => setState(() => _vehicleFilter = null),
                          ),
                          ...vehicleMap.values.map((v) => ChoiceChip(
                                label: Text(v.plateNumber as String, style: const TextStyle(fontSize: 12)),
                                selected: _vehicleFilter == v.id,
                                onSelected: (_) =>
                                    setState(() => _vehicleFilter = _vehicleFilter == v.id ? null : v.id),
                              )),
                        ],
                      ),
                    ),
                  ),

                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(message: s.noMaintenanceRecords),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MaintenanceCard(
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

class _SummaryBanner extends StatelessWidget {
  final int pendingCount;
  final int completedCount;
  final double totalCost;
  final NumberFormat currencyFormat;

  const _SummaryBanner({
    required this.pendingCount, required this.completedCount,
    required this.totalCost, required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _Stat(label: 'รอดำเนินการ', value: '$pendingCount')),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
          Expanded(child: _Stat(label: 'เสร็จแล้ว', value: '$completedCount')),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
          Expanded(child: _Stat(label: 'ค่าใช้จ่ายรวม', value: '฿${currencyFormat.format(totalCost)}')),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon, required this.label, required this.color,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : AppColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceCard extends ConsumerWidget {
  final MaintenanceModel record;
  final String vehicleLabel;
  final NumberFormat currencyFormat;
  final dynamic s;

  const _MaintenanceCard({
    required this.record, required this.vehicleLabel,
    required this.currencyFormat, required this.s,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'overdue': return AppColors.danger;
      default: return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed': return s.statusCompleted as String;
      case 'overdue': return s.statusOverdue as String;
      default: return s.statusPending as String;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = partCategoryByKey(record.partCategory);
    final statusColor = _statusColor(record.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(record.photoUrl!,
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _CategoryIconBox(cat: cat)),
              )
            else
              _CategoryIconBox(cat: cat),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(record.partName?.isNotEmpty == true ? record.partName! : record.type,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_statusLabel(record.status),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.directions_car_rounded, size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(vehicleLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const Text(' · ', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                      Text(cat.label(s.isTh), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  if (record.description != null && record.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(record.description!,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('฿${currencyFormat.format(record.cost)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const Spacer(),
                      if (record.status != 'completed')
                        TextButton(
                          onPressed: () => ref.read(maintenanceProvider.notifier).markCompleted(record.id),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: Text(s.markCompleted as String,
                              style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textHint),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(s.confirmDelete as String),
                              content: Text(s.confirmDeleteRecord as String),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel as String)),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: Text(s.delete as String)),
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

class _CategoryIconBox extends StatelessWidget {
  final PartCategory cat;
  const _CategoryIconBox({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: cat.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(cat.icon, color: cat.color, size: 26),
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
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
              child: const Icon(Icons.build_circle_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
