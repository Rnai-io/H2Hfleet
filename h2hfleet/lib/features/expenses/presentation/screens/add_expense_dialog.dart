import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/vehicle_model.dart';
import '../../../../providers/vehicles_provider.dart';
import '../../../../providers/expenses_provider.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  final VehicleModel? preselectedVehicle;
  const AddExpenseDialog({super.key, this.preselectedVehicle});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  VehicleModel? _selectedVehicle;
  String _selectedType = 'น้ำมัน';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  static const _expenseTypes = [
    ('น้ำมัน', Icons.local_gas_station_rounded, Color(0xFFD97706)),
    ('ซ่อม', Icons.build_rounded, Color(0xFFDC2626)),
    ('ยาง', Icons.tire_repair_rounded, Color(0xFF059669)),
    ('ค่าเที่ยว', Icons.route_rounded, Color(0xFF2563EB)),
    ('ประกัน', Icons.shield_rounded, Color(0xFF7C3AED)),
    ('อื่นๆ', Icons.more_horiz_rounded, Color(0xFF64748B)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.preselectedVehicle;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรถก่อน')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(expensesProvider.notifier).addExpense(
            vehicleId: _selectedVehicle!.id,
            type: _selectedType,
            amount: double.parse(_amountCtrl.text.replaceAll(',', '')),
            expenseDate: _selectedDate,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.valueOrNull ?? [];
    final dateLabel = DateFormat('d MMM yyyy').format(_selectedDate);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF059669), Color(0xFF047857)],
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
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('บันทึกค่าใช้จ่าย',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle picker
                      _SectionLabel('รถ'),
                      const SizedBox(height: 8),
                      if (vehicles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warningSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                              SizedBox(width: 8),
                              Text('ยังไม่มีรถ กรุณาเพิ่มรถก่อน',
                                  style: TextStyle(color: AppColors.warning, fontSize: 13)),
                            ],
                          ),
                        )
                      else
                        _VehiclePicker(
                          vehicles: vehicles,
                          selected: _selectedVehicle,
                          onChanged: (v) => setState(() => _selectedVehicle = v),
                        ),

                      const SizedBox(height: 20),

                      // Expense type
                      _SectionLabel('ประเภทค่าใช้จ่าย'),
                      const SizedBox(height: 10),
                      _ExpenseTypeGrid(
                        selected: _selectedType,
                        onSelected: (t) => setState(() => _selectedType = t),
                        types: _expenseTypes,
                      ),

                      const SizedBox(height: 20),

                      // Amount
                      _SectionLabel('จำนวนเงิน (บาท)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                        ],
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          prefixText: '฿ ',
                          prefixStyle: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.success,
                          ),
                          hintText: '0.00',
                          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 22),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.success, width: 2),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณาใส่จำนวนเงิน';
                          final num = double.tryParse(v.replaceAll(',', ''));
                          if (num == null || num <= 0) return 'จำนวนเงินต้องมากกว่า 0';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Date
                      _SectionLabel('วันที่'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text(dateLabel,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 18, color: AppColors.textHint),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Note (optional)
                      _SectionLabel('หมายเหตุ (ไม่บังคับ)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteCtrl,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'รายละเอียดเพิ่มเติม...',
                          hintStyle: const TextStyle(color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('บันทึกค่าใช้จ่าย',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary,
            letterSpacing: 0.3));
  }
}

class _VehiclePicker extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final VehicleModel? selected;
  final ValueChanged<VehicleModel?> onChanged;

  const _VehiclePicker({
    required this.vehicles, required this.selected, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VehicleModel>(
          value: selected,
          isExpanded: true,
          hint: const Text('เลือกรถ', style: TextStyle(color: AppColors.textHint)),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          items: vehicles.map((v) {
            final isActive = v.status == 'active';
            return DropdownMenuItem(
              value: v,
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.success : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${v.plateNumber} · ${v.vehicleType}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ExpenseTypeGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final List<(String, IconData, Color)> types;

  const _ExpenseTypeGrid({
    required this.selected, required this.onSelected, required this.types,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: types.map((t) {
        final (label, icon, color) = t;
        final isSelected = selected == label;
        return GestureDetector(
          onTap: () => onSelected(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.12) : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: isSelected ? color : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? color : AppColors.textSecondary,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
