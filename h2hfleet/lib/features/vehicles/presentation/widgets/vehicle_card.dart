import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/vehicle_model.dart';
import '../../../../providers/vehicles_provider.dart';
import '../screens/edit_vehicle_dialog.dart';
import '../../../map/gps_device_dialog.dart';

class VehicleCard extends ConsumerWidget {
  final VehicleModel vehicle;
  final VoidCallback onTap;

  const VehicleCard({super.key, required this.vehicle, required this.onTap});

  IconData get _typeIcon {
    switch (vehicle.vehicleType) {
      case 'รถเก๋ง': return Icons.directions_car_rounded;
      case 'SUV': return Icons.directions_car_filled_rounded;
      case 'รถกระบะ': return Icons.fire_truck_rounded;
      case 'รถตู้': return Icons.airport_shuttle_rounded;
      case 'VIP': return Icons.star_rounded;
      case 'รถบัส': return Icons.directions_bus_rounded;
      case 'รถตุ้ทึบ': return Icons.local_shipping_rounded;
      case 'รถบรรทุก': return Icons.rv_hookup_rounded;
      case 'รถปูน': return Icons.agriculture_rounded;
      case 'รถห้องเย็น': return Icons.ac_unit_rounded;
      default: return Icons.directions_car_rounded;
    }
  }

  Color get _typeColor {
    switch (vehicle.vehicleType) {
      case 'รถเก๋ง': return const Color(0xFF2563EB);
      case 'SUV': return const Color(0xFF7C3AED);
      case 'รถกระบะ': return const Color(0xFFD97706);
      case 'รถตู้': return const Color(0xFF059669);
      case 'VIP': return const Color(0xFF7C3AED);
      case 'รถบัส': return const Color(0xFFDC2626);
      case 'รถตุ้ทึบ': return const Color(0xFF0891B2);
      case 'รถบรรทุก': return const Color(0xFF1E40AF);
      case 'รถปูน': return const Color(0xFF92400E);
      case 'รถห้องเย็น': return const Color(0xFF0369A1);
      default: return AppColors.textSecondary;
    }
  }

  String get _fuelLabel {
    switch (vehicle.fuelType) {
      case 'diesel': return 'ดีเซล';
      case 'petrol': return 'เบนซิน';
      case 'lpg': return 'LPG/NGV';
      case 'electric': return 'ไฟฟ้า';
      default: return vehicle.fuelType;
    }
  }

  void _openEdit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EditVehicleDialog(vehicle: vehicle),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _VehicleOptionsSheet(
        vehicle: vehicle,
        onEdit: () {
          Navigator.pop(context);
          _openEdit(context);
        },
        onGps: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (_) => GpsDeviceDialog(vehicle: vehicle),
          );
        },
        onDelete: () async {
          Navigator.pop(context);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
                  SizedBox(width: 8),
                  Text('ยืนยันการลบ',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ],
              ),
              content: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  children: [
                    const TextSpan(text: 'ต้องการลบรถ '),
                    TextSpan(
                      text: vehicle.plateNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const TextSpan(text: ' ออกจากระบบ?\n\n'),
                    const TextSpan(text: 'สิ่งที่จะถูกลบพร้อมกัน:\n'),
                    const TextSpan(text: '• ข้อมูลรถทั้งหมด\n'),
                    const TextSpan(text: '• ประวัติค่าใช้จ่ายของรถคันนี้\n\n'),
                    const TextSpan(
                      text: '⚠️ ไม่สามารถกู้คืนข้อมูลได้',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ยกเลิก',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('ลบรถ',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(Icons.delete_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('ลบ ${vehicle.plateNumber} สำเร็จ'),
                  ]),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMaintenance = vehicle.status == 'maintenance';
    final color = _typeColor;
    final hasRemark = vehicle.remark != null && vehicle.remark!.isNotEmpty;

    return Dismissible(
      key: ValueKey(vehicle.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, color: AppColors.success, size: 26),
            const SizedBox(height: 4),
            const Text('แก้ไข',
                style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        _openEdit(context);
        return false; // ไม่ dismiss จริง — แค่เปิด dialog
      },
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showOptions(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMaintenance
                    ? AppColors.danger.withValues(alpha: 0.4)
                    : AppColors.divider,
                width: isMaintenance ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                // Color top bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isMaintenance ? AppColors.danger : color,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_typeIcon, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Plate + status
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle.plateNumber,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      if (vehicle.nickName != null && vehicle.nickName!.isNotEmpty)
                                        Text(
                                          vehicle.nickName!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: color,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                _StatusPill(status: vehicle.status),
                              ],
                            ),
                            const SizedBox(height: 3),

                            // Brand / model / year
                            if (vehicle.brand.isNotEmpty)
                              Text(
                                '${vehicle.brand} ${vehicle.model} · ${vehicle.year}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),

                            // Remark badge
                            if (hasRemark) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: color.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event_seat_rounded,
                                        size: 11, color: color),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        vehicle.remark!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            // Tags
                            Wrap(
                              spacing: 6,
                              children: [
                                _Tag(label: vehicle.vehicleType, color: color),
                                _Tag(
                                    label: _fuelLabel,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action buttons column
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _openEdit(context),
                            icon: const Icon(Icons.edit_rounded,
                                size: 18, color: AppColors.textSecondary),
                            tooltip: 'แก้ไข',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppColors.success.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                    color: AppColors.success
                                        .withValues(alpha: 0.2)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          IconButton(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) =>
                                  GpsDeviceDialog(vehicle: vehicle),
                            ),
                            icon: const Icon(Icons.gps_fixed_rounded,
                                size: 18, color: Color(0xFF0EA5E9)),
                            tooltip: 'ตั้งค่า GPS',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                    color: const Color(0xFF0EA5E9)
                                        .withValues(alpha: 0.2)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Maintenance warning bar
                if (isMaintenance)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSurface,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.build_rounded,
                            size: 13, color: AppColors.danger),
                        SizedBox(width: 6),
                        Text('อยู่ระหว่างซ่อมบำรุง',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      'active' => ('ใช้งาน', AppColors.success, AppColors.successSurface),
      'maintenance' => ('ซ่อมบำรุง', AppColors.danger, AppColors.dangerSurface),
      _ => ('ปิดใช้งาน', AppColors.warning, AppColors.warningSurface),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Bottom Sheet เมนูตัวเลือก ─────────────────────────────────
class _VehicleOptionsSheet extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onEdit;
  final VoidCallback onGps;
  final VoidCallback onDelete;

  const _VehicleOptionsSheet({
    required this.vehicle,
    required this.onEdit,
    required this.onGps,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Vehicle info header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.plateNumber,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    Text('${vehicle.vehicleType} · ${vehicle.brand} ${vehicle.model}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(indent: 20, endIndent: 20),

          // แก้ไข
          ListTile(
            onTap: onEdit,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, color: AppColors.success, size: 20),
            ),
            title: const Text('แก้ไขข้อมูลรถ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('เปลี่ยนทะเบียน ยี่ห้อ รุ่น สถานะ',
                style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ),

          // GPS Device
          ListTile(
            onTap: onGps,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.gps_fixed_rounded,
                  color: Color(0xFF0EA5E9), size: 20),
            ),
            title: const Text('ตั้งค่าอุปกรณ์ GPS',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('ผูก IMEI กับรถสำหรับติดตาม GPS',
                style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ),

          // ลบ
          ListTile(
            onTap: onDelete,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 20),
            ),
            title: const Text('ลบรถออกจากระบบ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                    color: AppColors.danger)),
            subtitle: const Text('ลบข้อมูลรถและประวัติค่าใช้จ่ายทั้งหมด',
                style: TextStyle(fontSize: 12, color: AppColors.danger)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.danger),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.divider),
                  ),
                ),
                child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
