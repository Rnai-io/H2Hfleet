import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/vehicle_model.dart';
import '../../../../providers/vehicles_provider.dart';

const _vehicleTypes = [
  'รถเก๋ง', 'SUV', 'รถกระบะ', 'รถตู้', 'VIP', 'รถบัส',
  'รถตุ้ทึบ', 'รถบรรทุก', 'รถปูน', 'รถห้องเย็น', 'อื่นๆ',
];

const _remarkOptions = <String, List<String>>{
  'รถเก๋ง': ['4 ที่นั่ง', '7 ที่นั่ง'],
  'SUV': ['SUV 5 ที่นั่ง', 'SUV 7 ที่นั่ง', 'SUV 4WD', 'PPV (Pick-up Passenger Vehicle)'],
  'รถตู้': ['รถตู้ทั่วไป', 'รถตู้ VIP: 8-10 ที่นั่ง', 'มินิบัส: 15-20 ที่นั่ง'],
  'VIP': ['รถตู้ VIP: 8-10 ที่นั่ง', 'รถบัส VIP ชั้นเดียว: 24-32 ที่นั่ง (เบาะกว้าง)'],
  'รถบัส': [
    'มินิบัส (รถขนาดเล็ก): 15-20 ที่นั่ง',
    'รถบัสขนาดกลาง: 24-32 ที่นั่ง',
    'รถบัสชั้นเดียว: 36-40 ที่นั่ง (ป.1)',
    'รถบัส VIP ชั้นเดียว: 24-32 ที่นั่ง (เบาะกว้าง)',
    'รถบัสสองชั้น: 40-50 ที่นั่ง',
  ],
  'รถกระบะ': ['รถกระบะมาตรฐาน', 'รถกระบะ 4 ประตู', 'รถกระบะเปิดท้าย'],
  'รถตุ้ทึบ': ['รถตุ้ทึบทั่วไป', 'รถตุ้ทึบพ่วง'],
  'รถบรรทุก': ['รถบรรทุก 6 ล้อ', 'รถบรรทุก 10 ล้อ', 'รถบรรทุก 18 ล้อ'],
  'รถปูน': ['รถปูนผสม', 'รถปูนปั๊ม'],
  'รถห้องเย็น': ['ห้องเย็นขนาดเล็ก', 'ห้องเย็นขนาดกลาง', 'ห้องเย็นขนาดใหญ่'],
};

const _fuelTypes = [
  ('diesel', 'ดีเซล'),
  ('petrol', 'เบนซิน'),
  ('lpg', 'LPG/NGV'),
  ('electric', 'ไฟฟ้า'),
];

const _statusOptions = [
  ('active', 'ใช้งาน', AppColors.success),
  ('inactive', 'ปิดใช้งาน', AppColors.warning),
  ('maintenance', 'ซ่อมบำรุง', AppColors.danger),
];

class EditVehicleDialog extends ConsumerStatefulWidget {
  final VehicleModel vehicle;
  const EditVehicleDialog({super.key, required this.vehicle});

  @override
  ConsumerState<EditVehicleDialog> createState() => _EditVehicleDialogState();
}

class _EditVehicleDialogState extends ConsumerState<EditVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plateController;
  late final TextEditingController _nameController;  // ชื่อรถ (ชื่อเล่น)
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _customRemarkController;

  late String _vehicleType;
  late String _fuelType;
  late String _status;
  String? _selectedRemark;
  bool _showCustomRemark = false;
  bool _isLoading = false;
  bool _isDeleting = false;

  List<String> get _currentRemarkOptions => _remarkOptions[_vehicleType] ?? [];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _plateController = TextEditingController(text: v.plateNumber);
    _nameController = TextEditingController(text: v.nickName ?? '');
    _brandController = TextEditingController(text: v.brand);
    _modelController = TextEditingController(text: v.model);
    // แปลง ค.ศ. ให้แสดงเป็น ค.ศ. เสมอ (ถ้า >= 2500 ถือว่าเป็น พ.ศ. ให้แปลงเป็น ค.ศ.)
    final yearCE = v.year >= 2500 ? v.year - 543 : v.year;
    _yearController = TextEditingController(text: yearCE.toString());
    _vehicleType = _vehicleTypes.contains(v.vehicleType) ? v.vehicleType : 'อื่นๆ';
    _fuelType = v.fuelType;
    _status = v.status;

    // ตรวจสอบว่า remark เดิมอยู่ใน preset หรือต้องกรอกเอง
    final existingRemark = v.remark;
    if (existingRemark != null && existingRemark.isNotEmpty) {
      final presets = _remarkOptions[_vehicleType] ?? [];
      if (presets.contains(existingRemark)) {
        _selectedRemark = existingRemark;
        _customRemarkController = TextEditingController();
      } else {
        _showCustomRemark = true;
        _customRemarkController = TextEditingController(text: existingRemark);
      }
    } else {
      _customRemarkController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _customRemarkController.dispose();
    super.dispose();
  }

  void _onVehicleTypeChanged(String type) {
    setState(() {
      _vehicleType = type;
      _selectedRemark = null;
      _showCustomRemark = false;
      _customRemarkController.clear();
    });
  }

  String? get _finalRemark {
    if (_showCustomRemark) return _customRemarkController.text.trim();
    return _selectedRemark;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // แปลงปี: ถ้าผู้ใช้กรอก พ.ศ. (>= 2500) ให้แปลงเป็น ค.ศ. ก่อนบันทึก
      final rawYear = int.tryParse(_yearController.text) ?? DateTime.now().year;
      final yearCE = rawYear >= 2500 ? rawYear - 543 : rawYear;
      await ref.read(vehiclesProvider.notifier).updateVehicle(
            vehicleId: widget.vehicle.id,
            plateNumber: _plateController.text.trim().toUpperCase(),
            nickName: _nameController.text.trim(),
            vehicleType: _vehicleType,
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            year: yearCE,
            fuelType: _fuelType,
            status: _status,
            remark: _finalRemark,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('บันทึกการแก้ไขสำเร็จ'),
            ]),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 8),
            Text('ยืนยันการลบ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            children: [
              const TextSpan(text: 'คุณต้องการลบรถ '),
              TextSpan(
                text: widget.vehicle.plateNumber,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const TextSpan(text: ' ออกจากระบบ?\n\n'),
              const TextSpan(text: 'สิ่งที่จะถูกลบพร้อมกัน:\n'),
              const TextSpan(text: '• ข้อมูลรถทั้งหมด\n'),
              const TextSpan(text: '• ประวัติค่าใช้จ่ายของรถคันนี้\n\n'),
              const TextSpan(
                text: '⚠️ ไม่สามารถกู้คืนข้อมูลได้',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ลบรถ', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(vehiclesProvider.notifier).deleteVehicle(widget.vehicle.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.delete_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('ลบ ${widget.vehicle.plateNumber} สำเร็จ'),
            ]),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('แก้ไขข้อมูลรถ',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text(
                          widget.vehicle.plateNumber,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Form ────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ทะเบียนรถ
                      const _FieldLabel('ทะเบียนรถ *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _plateController,
                        decoration: const InputDecoration(
                          hintText: 'เช่น กข 1234 กรุงเทพฯ',
                          prefixIcon:
                              Icon(Icons.credit_card_rounded, size: 20),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'กรุณากรอกทะเบียนรถ'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // ชื่อรถ (ชื่อเล่น)
                      const _FieldLabel('ชื่อรถ (ชื่อเล่น)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'เช่น รถหัวหน้า, รถส่งของ, รถคันแดง',
                          prefixIcon: Icon(Icons.label_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // สถานะรถ
                      const _FieldLabel('สถานะรถ'),
                      const SizedBox(height: 8),
                      Row(
                        children: _statusOptions.map((s) {
                          final isSelected = _status == s.$1;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: s.$1 == _statusOptions.last.$1
                                      ? 0
                                      : 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _status = s.$1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? s.$3.withValues(alpha: 0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? s.$3
                                          : AppColors.divider,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 7, height: 7,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? s.$3
                                              : AppColors.textHint,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(s.$2,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? s.$3
                                                : AppColors.textSecondary,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // ประเภทรถ
                      const _FieldLabel('ประเภทรถ'),
                      const SizedBox(height: 8),
                      _VehicleTypeGrid(
                        selected: _vehicleType,
                        types: _vehicleTypes,
                        onChanged: _onVehicleTypeChanged,
                      ),
                      const SizedBox(height: 16),

                      // Remark
                      if (_currentRemarkOptions.isNotEmpty) ...[
                        const _FieldLabel('ข้อมูลเพิ่มเติม / ความจุ'),
                        const SizedBox(height: 8),
                        _RemarkSelector(
                          options: _currentRemarkOptions,
                          selected: _showCustomRemark
                              ? 'อื่นๆ'
                              : _selectedRemark,
                          onChanged: (val) {
                            setState(() {
                              if (val == 'อื่นๆ') {
                                _showCustomRemark = true;
                                _selectedRemark = null;
                              } else {
                                _showCustomRemark = false;
                                _selectedRemark = val;
                                _customRemarkController.clear();
                              }
                            });
                          },
                        ),
                        if (_showCustomRemark) ...[
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _customRemarkController,
                            decoration: const InputDecoration(
                              hintText: 'ระบุรายละเอียดเพิ่มเติม...',
                              prefixIcon:
                                  Icon(Icons.edit_note_rounded, size: 20),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // ยี่ห้อ / รุ่น / ปี
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('ยี่ห้อ'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _brandController,
                                  decoration: const InputDecoration(
                                      hintText: 'Toyota, Isuzu...'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('รุ่น'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _modelController,
                                  decoration: const InputDecoration(
                                      hintText: 'Commuter...'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('ปี'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _yearController,
                                  decoration: const InputDecoration(
                                      hintText: 'เช่น 2022 หรือ 2565'),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    final raw = int.tryParse(v ?? '');
                                    if (raw == null) return 'กรุณากรอกปี';
                                    // รับทั้ง ค.ศ. (1990-2027) และ พ.ศ. (2533-2570)
                                    final ce = raw >= 2500 ? raw - 543 : raw;
                                    if (ce < 1990 || ce > DateTime.now().year + 2) {
                                      return 'ปีไม่ถูกต้อง (ค.ศ. หรือ พ.ศ.)';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // เชื้อเพลิง
                      const _FieldLabel('ประเภทเชื้อเพลิง'),
                      const SizedBox(height: 8),
                      Row(
                        children: _fuelTypes.map((fuel) {
                          final isSelected = _fuelType == fuel.$1;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: fuel.$1 == _fuelTypes.last.$1
                                      ? 0
                                      : 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _fuelType = fuel.$1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.divider,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    fuel.$2,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // ── Actions ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // ปุ่มยกเลิก
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('ยกเลิก'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ปุ่มบันทึก
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded, size: 18),
                                    SizedBox(width: 6),
                                    Text('บันทึก'),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ปุ่มลบรถ (แยกแถว เพื่อความชัดเจน)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isDeleting ? null : _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.danger),
                            )
                          : const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(
                        _isDeleting ? 'กำลังลบ...' : 'ลบรถออกจากระบบ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
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

// ── Shared sub-widgets ──────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary));
  }
}

class _VehicleTypeGrid extends StatelessWidget {
  final String selected;
  final List<String> types;
  final ValueChanged<String> onChanged;

  const _VehicleTypeGrid(
      {required this.selected, required this.types, required this.onChanged});

  IconData _iconFor(String type) {
    switch (type) {
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
      default: return Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: types.length,
      itemBuilder: (context, i) {
        final type = types[i];
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_iconFor(type),
                    size: 22,
                    color: isSelected ? Colors.white : AppColors.textSecondary),
                const SizedBox(height: 4),
                Text(type,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      height: 1.2,
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RemarkSelector extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChanged;

  const _RemarkSelector(
      {required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final all = [...options, 'อื่นๆ'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: all.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (opt == 'อื่นๆ') ...[
                  Icon(Icons.edit_rounded,
                      size: 12,
                      color: isSelected ? Colors.white : AppColors.textSecondary),
                  const SizedBox(width: 4),
                ],
                Text(opt,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
