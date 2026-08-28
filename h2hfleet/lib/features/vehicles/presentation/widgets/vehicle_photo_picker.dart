import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';

// Preset HD Vehicle Images for quick selection
const Map<String, String> kPresetVehiclePhotos = {
  'รถเก๋ง (Sedan)': 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=800&q=80',
  'SUV / PPV': 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=800&q=80',
  'รถกระบะ (Pickup)': 'https://images.unsplash.com/photo-1559297434-fae8a1916a79?w=800&q=80',
  'รถตู้ (Van)': 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=800&q=80',
  'VIP Executive': 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=800&q=80',
  'รถบัส (Bus)': 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80',
  'รถตู้ทึบ (Box Van)': 'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=800&q=80',
  'รถบรรทุก (Heavy Truck)': 'https://images.unsplash.com/photo-1519003722824-194d4455a60c?w=800&q=80',
};

class VehiclePhotoPicker extends StatefulWidget {
  final String? initialImageUrl;
  final ValueChanged<String?> onImageChanged;
  final ValueChanged<Uint8List?>? onRawBytesChanged;
  final String vehicleType;

  const VehiclePhotoPicker({
    super.key,
    this.initialImageUrl,
    required this.onImageChanged,
    this.onRawBytesChanged,
    this.vehicleType = 'รถเก๋ง',
  });

  @override
  State<VehiclePhotoPicker> createState() => _VehiclePhotoPickerState();
}

class _VehiclePhotoPickerState extends State<VehiclePhotoPicker> {
  String? _currentImageUrl;
  Uint8List? _previewBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
  }

  @override
  void didUpdateWidget(covariant VehiclePhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImageUrl != widget.initialImageUrl) {
      setState(() => _currentImageUrl = widget.initialImageUrl);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _previewBytes = bytes;
          _currentImageUrl = base64Str;
          _isLoading = false;
        });
        widget.onImageChanged(base64Str);
        widget.onRawBytesChanged?.call(bytes);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเลือกรูปภาพได้: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showUrlOrPresetPicker() {
    final urlCtrl = TextEditingController(text: _currentImageUrl?.startsWith('http') == true ? _currentImageUrl : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 16, left: 16, right: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7), size: 20),
                  SizedBox(width: 8),
                  Text('เลือกรูปภาพประจำตัวรถ / ระบุลิงก์ภาพ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 14),

              // Custom URL Input
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  labelText: 'URL รูปภาพ (https://...)',
                  hintText: 'https://example.com/my-truck.jpg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7)),
                    onPressed: () {
                      final url = urlCtrl.text.trim();
                      if (url.isNotEmpty) {
                        setState(() {
                          _currentImageUrl = url;
                          _previewBytes = null;
                        });
                        widget.onImageChanged(url);
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('หรือเลือกภาพตัวอย่างคุณภาพสูงตามประเภทรถ:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 10),

              // Preset Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                itemCount: kPresetVehiclePhotos.length,
                itemBuilder: (context, index) {
                  final key = kPresetVehiclePhotos.keys.elementAt(index);
                  final url = kPresetVehiclePhotos.values.elementAt(index);
                  final isSelected = _currentImageUrl == url;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _currentImageUrl = url;
                        _previewBytes = null;
                      });
                      widget.onImageChanged(url);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.5 : 1,
                        ),
                        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                        ),
                        child: Text(
                          key,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('อัปโหลดรูปภาพประจำตัวรถ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 14),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0284C7)),
                ),
                title: const Text('ถ่ายรูปภาพสด (Camera)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                subtitle: const Text('เปิดกล้องถ่ายรูปรถจริง', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981)),
                ),
                title: const Text('เลือกจากคลังภาพ / เครื่อง (Photo Library)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                subtitle: const Text('เลือกภาพถ่ายจากแกลเลอรีอุปกรณ์', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.link_rounded, color: Color(0xFF8B5CF6)),
                ),
                title: const Text('ระบุลิงก์ภาพ / คลังภาพสต็อกรถ HD', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                subtitle: const Text('วาง URL หรือเลือกภาพตัวอย่างที่สวยงาม', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _showUrlOrPresetPicker();
                },
              ),
              if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  ),
                  title: const Text('ลบรูปภาพออก', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                  subtitle: const Text('ยกเลิกภาพและใช้พิมพ์เขียว CAD เริ่มต้น', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _currentImageUrl = null;
                      _previewBytes = null;
                    });
                    widget.onImageChanged(null);
                    widget.onRawBytesChanged?.call(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewImage() {
    if (_previewBytes != null) {
      return Image.memory(_previewBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      if (_currentImageUrl!.startsWith('data:image')) {
        try {
          final base64Data = _currentImageUrl!.split(',').last;
          final bytes = base64Decode(base64Data);
          return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
        } catch (_) {}
      }
      return Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, stack) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 36),
              SizedBox(height: 4),
              Text('โหลดภาพไม่สำเร็จ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) || _previewBytes != null;

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasImage ? const Color(0xFF0284C7) : const Color(0xFF334155), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // Background Image / Placeholder
            if (hasImage)
              Positioned.fill(child: _buildPreviewImage())
            else
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF38BDF8), size: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'แนบภาพถ่ายประจำตัวรถ',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'แตะเพื่อถ่ายรูป / เลือกจากเครื่อง / ระบุ URL',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
                ),
              ),

            // Click Overlay to trigger picker
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showImageSourceMenu,
                  child: hasImage
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_camera_rounded, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text('เปลี่ยนภาพถ่าย', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
