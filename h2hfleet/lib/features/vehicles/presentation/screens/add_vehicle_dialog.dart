import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/vehicles_provider.dart';

// ประเภทรถทั้งหมด
const _vehicleTypes = [
  'รถเก๋ง',
  'SUV',
  'รถกระบะ',
  'รถตู้',
  'VIP',
  'รถบัส',
  'รถตุ้ทึบ',
  'รถบรรทุก',
  'รถปูน',
  'รถห้องเย็น',
  'อื่นๆ',
];

// remark options ตามประเภทรถ
const _remarkOptions = <String, List<String>>{
  'รถเก๋ง': [
    '4 ที่นั่ง',
    '7 ที่นั่ง',
  ],
  'SUV': [
    'SUV 5 ที่นั่ง',
    'SUV 7 ที่นั่ง',
    'SUV 4WD',
    'PPV (Pick-up Passenger Vehicle)',
  ],
  'รถตู้': [
    'รถตู้ทั่วไป',
    'รถตู้ VIP: 8-10 ที่นั่ง',
    'มินิบัส: 15-20 ที่นั่ง',
  ],
  'VIP': [
    'รถตู้ VIP: 8-10 ที่นั่ง',
    'รถบัส VIP ชั้นเดียว: 24-32 ที่นั่ง (เบาะกว้าง)',
  ],
  'รถบัส': [
    'มินิบัส (รถขนาดเล็ก): 15-20 ที่นั่ง',
    'รถบัสขนาดกลาง: 24-32 ที่นั่ง',
    'รถบัสชั้นเดียว: 36-40 ที่นั่ง (ป.1)',
    'รถบัส VIP ชั้นเดียว: 24-32 ที่นั่ง (เบาะกว้าง)',
    'รถบัสสองชั้น: 40-50 ที่นั่ง',
  ],
  'รถกระบะ': [
    'รถกระบะมาตรฐาน',
    'รถกระบะ 4 ประตู',
    'รถกระบะเปิดท้าย',
  ],
  'รถตุ้ทึบ': [
    'รถตุ้ทึบทั่วไป',
    'รถตุ้ทึบพ่วง',
  ],
  'รถบรรทุก': [
    'รถบรรทุก 6 ล้อ',
    'รถบรรทุก 10 ล้อ',
    'รถบรรทุก 18 ล้อ',
  ],
  'รถปูน': [
    'รถปูนผสม',
    'รถปูนปั๊ม',
  ],
  'รถห้องเย็น': [
    'ห้องเย็นขนาดเล็ก',
    'ห้องเย็นขนาดกลาง',
    'ห้องเย็นขนาดใหญ่',
  ],
};

const _fuelTypes = [
  ('diesel', 'ดีเซล'),
  ('petrol', 'เบนซิน'),
  ('lpg', 'LPG/NGV'),
  ('electric', 'ไฟฟ้า'),
];

class AddVehicleDialog extends ConsumerStatefulWidget {
  const AddVehicleDialog({super.key});

  @override
  ConsumerState<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends ConsumerState<AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  final _customRemarkController = TextEditingController();

  String _vehicleType = 'รถเก๋ง';
  String _fuelType = 'diesel';
  String? _selectedRemark;
  bool _showCustomRemark = false;
  bool _isLoading = false;

  List<String> get _currentRemarkOptions => _remarkOptions[_vehicleType] ?? [];

  @override
  void dispose() {
    _plateController.dispose();
    _nickNameController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(vehiclesProvider.notifier).addVehicle(
            plateNumber: _plateController.text.trim().toUpperCase(),
            nickName: _nickNameController.text.trim().isEmpty
                ? null
                : _nickNameController.text.trim(),
            vehicleType: _vehicleType,
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            year: int.tryParse(_yearController.text) ?? DateTime.now().year,
            fuelType: _fuelType,
            remark: _finalRemark,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('เพิ่มรถสำเร็จแล้ว'),
            ]),
            backgroundColor: AppColors.success,
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
      if (mounted) setState(() => _isLoading = false);
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
            // Header
            _DialogHeader(onClose: () => Navigator.pop(context)),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      // ทะเบียนรถ
                      const _FieldLabel('ทะเบียนรถ *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _plateController,
                        decoration: const InputDecoration(
                          hintText: 'เช่น กข 1234 กรุงเทพฯ',
                          prefixIcon: Icon(Icons.credit_card_rounded, size: 20),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'กรุณากรอกทะเบียนรถ' : null,
                      ),
                      const SizedBox(height: 16),

                      // ชื่อรถ (ชื่อเล่น)
                      const _FieldLabel('ชื่อรถ (ชื่อเล่น)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nickNameController,
                        decoration: const InputDecoration(
                          hintText: 'เช่น รถหัวหน้า, รถส่งของ, รถคันแดง',
                          prefixIcon: Icon(Icons.label_rounded, size: 20),
                        ),
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

                      // Remark (capacity/spec)
                      if (_currentRemarkOptions.isNotEmpty) ...[
                        const _FieldLabel('ข้อมูลเพิ่มเติม / ความจุ'),
                        const SizedBox(height: 8),
                        _RemarkSelector(
                          options: _currentRemarkOptions,
                          selected: _showCustomRemark ? 'อื่นๆ' : _selectedRemark,
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
                              prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
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
                                  decoration: const InputDecoration(hintText: 'Toyota, Isuzu...'),
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
                                  decoration: const InputDecoration(hintText: 'Commuter...'),
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
                                  decoration: const InputDecoration(hintText: '2567'),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    final y = int.tryParse(v ?? '');
                                    if (y == null || y < 1990 || y > DateTime.now().year + 1) {
                                      return 'ปีไม่ถูกต้อง';
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
                                  right: fuel.$1 == _fuelTypes.last.$1 ? 0 : 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _fuelType = fuel.$1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.divider,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    fuel.$2,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
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

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, size: 20),
                                SizedBox(width: 6),
                                Text('เพิ่มรถ'),
                              ],
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

// ── Sub-widgets ─────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _DialogHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
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
            child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('เพิ่มรถใหม่',
                  style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Text('กรอกข้อมูลรถให้ครบถ้วน',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
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
      case 'รถเก๋ง':
        return Icons.directions_car_rounded;
      case 'รถกระบะ':
        return Icons.fire_truck_rounded;
      case 'รถตู้':
        return Icons.airport_shuttle_rounded;
      case 'VIP':
        return Icons.star_rounded;
      case 'รถบัส':
        return Icons.directions_bus_rounded;
      case 'รถตุ้ทึบ':
        return Icons.local_shipping_rounded;
      case 'รถบรรทุก':
        return Icons.rv_hookup_rounded;
      case 'รถปูน':
        return Icons.agriculture_rounded;
      case 'รถห้องเย็น':
        return Icons.ac_unit_rounded;
      default:
        return Icons.more_horiz_rounded;
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
                Text(
                  type,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
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
    final allOptions = [...options, 'อื่นๆ'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allOptions.map((opt) {
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
                if (opt == 'อื่นๆ')
                  Icon(Icons.edit_rounded,
                      size: 12,
                      color: isSelected ? Colors.white : AppColors.textSecondary),
                if (opt == 'อื่นๆ') const SizedBox(width: 4),
                Text(
                  opt,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
