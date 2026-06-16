import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vehicle_model.dart';
import '../../providers/locale_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/vehicles_provider.dart';
import 'part_categories.dart';

class AddMaintenanceDialog extends ConsumerStatefulWidget {
  final String? initialVehicleId;
  const AddMaintenanceDialog({super.key, this.initialVehicleId});

  @override
  ConsumerState<AddMaintenanceDialog> createState() => _AddMaintenanceDialogState();
}

class _AddMaintenanceDialogState extends ConsumerState<AddMaintenanceDialog> {
  final _partNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  String? _vehicleId;
  String _categoryKey = 'engine';
  DateTime? _dueDate;
  File? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _vehicleId = widget.initialVehicleId;
  }

  @override
  void dispose() {
    _partNameCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _save() async {
    final s = ref.read(strProvider);
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.selectVehicleFirst), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (_partNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.fillRequired), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(maintenanceProvider.notifier);

    String? photoUrl;
    if (_photo != null) {
      photoUrl = await notifier.uploadPhoto(_photo!, _vehicleId!);
    }

    await notifier.addMaintenance(
      vehicleId: _vehicleId!,
      type: partCategoryByKey(_categoryKey).label(s.isTh),
      partCategory: _categoryKey,
      partName: _partNameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      cost: double.tryParse(_costCtrl.text.trim()) ?? 0,
      photoUrl: photoUrl,
      dueDate: _dueDate,
    );

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.maintenanceSaved), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(strProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.build_circle_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.addMaintenance,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle selector
                      Text(s.selectVehicle,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      vehiclesAsync.when(
                        data: (vehicles) => _VehicleDropdown(
                          vehicles: vehicles,
                          value: _vehicleId,
                          onChanged: (v) => setState(() => _vehicleId = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox(),
                      ),
                      const SizedBox(height: 20),

                      // Part category grid (visual parts picker)
                      Text(s.selectPartCategory,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: kPartCategories.length,
                        itemBuilder: (context, i) {
                          final cat = kPartCategories[i];
                          final selected = cat.key == _categoryKey;
                          return GestureDetector(
                            onTap: () => setState(() => _categoryKey = cat.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: selected ? cat.color.withValues(alpha: 0.14) : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected ? cat.color : AppColors.divider,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(cat.icon, color: cat.color, size: 26),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      cat.label(s.isTh),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                        color: selected ? cat.color : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      Text(s.partName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _partNameCtrl,
                        decoration: _decoration(s.partNameHint),
                      ),
                      const SizedBox(height: 16),

                      Text(s.maintenanceDescription,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 2,
                        decoration: _decoration(s.maintenanceDescriptionHint),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.maintenanceCost,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _costCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _decoration('0'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.dueDate,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) setState(() => _dueDate = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.divider),
                                    ),
                                    child: Text(
                                      _dueDate != null
                                          ? DateFormat('d MMM yyyy').format(_dueDate!)
                                          : '–',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text(s.attachPhoto,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      if (_photo != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_photo!, height: 140, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => setState(() => _photo = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54, shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickPhoto(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                label: Text(s.takePhoto, style: const TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickPhoto(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded, size: 16),
                                label: Text(s.chooseFromGallery, style: const TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(s.save, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
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

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _VehicleDropdown extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _VehicleDropdown({required this.vehicles, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vehicles.any((v) => v.id == value) ? value : null,
          isExpanded: true,
          hint: const Text('–', style: TextStyle(color: AppColors.textHint)),
          items: vehicles
              .map((v) => DropdownMenuItem(
                    value: v.id,
                    child: Text('${v.plateNumber} ${v.nickName != null ? '(${v.nickName})' : ''}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
