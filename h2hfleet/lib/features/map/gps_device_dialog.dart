import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vehicle_model.dart';
import '../../services/supabase_service.dart';

class GpsDeviceDialog extends ConsumerStatefulWidget {
  final VehicleModel vehicle;
  const GpsDeviceDialog({super.key, required this.vehicle});

  @override
  ConsumerState<GpsDeviceDialog> createState() => _GpsDeviceDialogState();
}

class _GpsDeviceDialogState extends ConsumerState<GpsDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _imeiCtrl = TextEditingController();
  String _deviceType = 'teltonika';
  bool _saving = false;
  String? _currentImei;

  final _deviceTypes = [
    ('teltonika', 'Teltonika (FM1010/FM2200)'),
    ('ruptela', 'Ruptela (FM2125)'),
    ('other', 'อื่นๆ'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentDevice();
  }

  Future<void> _loadCurrentDevice() async {
    final row = await SupabaseService().client
        .from('vehicles')
        .select('gps_device_imei, gps_device_type')
        .eq('id', widget.vehicle.id)
        .maybeSingle();
    if (mounted && row != null) {
      setState(() {
        _currentImei = row['gps_device_imei'] as String?;
        _imeiCtrl.text = _currentImei ?? '';
        _deviceType = row['gps_device_type'] as String? ?? 'teltonika';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await SupabaseService().client.from('vehicles').update({
        'gps_device_imei': _imeiCtrl.text.trim(),
        'gps_device_type': _deviceType,
      }).eq('id', widget.vehicle.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกไม่สำเร็จ: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _imeiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.gps_fixed_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ตั้งค่าอุปกรณ์ GPS',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          widget.vehicle.plateNumber,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Current status
              if (_currentImei != null && _currentImei!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ผูกอยู่กับ IMEI: $_currentImei',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Device type
              const Text(
                'ประเภทอุปกรณ์',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ...(_deviceTypes.map((t) => InkWell(
                    onTap: () => setState(() => _deviceType = t.$1),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: t.$1,
                            groupValue: _deviceType,
                            activeColor: AppColors.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) =>
                                setState(() => _deviceType = v!),
                          ),
                          Text(t.$2,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ))),
              const SizedBox(height: 12),

              // IMEI field
              const Text(
                'IMEI / Device ID',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imeiCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'เช่น 123456789012345',
                  hintStyle:
                      const TextStyle(color: AppColors.textHint, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'กรุณากรอก IMEI' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'หา IMEI ได้ที่ฉลากหลังอุปกรณ์ หรือ *#06# บนโทรศัพท์',
                style:
                    TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side:
                            const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('ยกเลิก',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('บันทึก',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
