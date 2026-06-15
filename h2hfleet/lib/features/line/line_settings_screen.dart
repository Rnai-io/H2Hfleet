import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerStatefulWidget, ConsumerState;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';

class LineSettingsScreen extends ConsumerStatefulWidget {
  const LineSettingsScreen({super.key});

  @override
  ConsumerState<LineSettingsScreen> createState() => _LineSettingsScreenState();
}

class _LineSettingsScreenState extends ConsumerState<LineSettingsScreen> {
  final _userIdCtrl = TextEditingController();
  bool _isTesting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      _userIdCtrl.text = prefs.getString('line_user_id') ?? '';
    }
  }

  Future<void> _saveSettings() async {
    if (_userIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาใส่ LINE User ID'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('line_user_id', _userIdCtrl.text.trim());
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกการตั้งค่า LINE สำเร็จ ✅'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _testSend() async {
    final userId = _userIdCtrl.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาใส่ LINE User ID ก่อน')),
      );
      return;
    }
    setState(() => _isTesting = true);
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://rdobhvuiadmsqdfugrlp.supabase.co/functions/v1/line-push-message',
        data: {
          'userId': userId,
          'message': '✅ H2HFleet: ทดสอบการส่งข้อความสำเร็จ!\n\nระบบ LINE แจ้งเตือนพร้อมใช้งาน 🚛',
        },
      );
      if (mounted) {
        final ok = response.statusCode == 200;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'ส่งทดสอบไป LINE สำเร็จ! ✅' : 'ส่งไม่สำเร็จ'),
            backgroundColor: ok ? AppColors.success : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF06C755),
        foregroundColor: Colors.white,
        title: const Text('ตั้งค่า LINE แจ้งเตือน',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F9EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF06C755).withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_rounded, color: Color(0xFF06C755), size: 20),
                      SizedBox(width: 8),
                      Text('LINE แจ้งเตือน',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                              fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ใส่แค่ LINE User ID ของคุณ ระบบจะส่งสรุปรายงานรถตรงเข้า LINE โดยอัตโนมัติ',
                    style: TextStyle(fontSize: 13, color: Color(0xFF065F46), height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('LINE User ID',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('รับได้โดยพิมพ์ "id" ใน LINE Bot @655jmtme',
                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _userIdCtrl,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'U xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                hintStyle: const TextStyle(color: AppColors.textHint),
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
                  borderSide: const BorderSide(color: Color(0xFF06C755), width: 2),
                ),
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testSend,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF06C755)))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('ทดสอบส่ง'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF06C755),
                      side: const BorderSide(color: Color(0xFF06C755)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06C755),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('บันทึก',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            const Text('วิธีรับ User ID',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ..._steps.map((s) => _StepItem(number: s.$1, text: s.$2)),
          ],
        ),
      ),
    );
  }
}

const _steps = [
  (1, 'เปิด LINE แล้วค้นหา @655jmtme หรือ H2HFleet Bot'),
  (2, 'พิมพ์ "id" ส่งไปที่ Bot'),
  (3, 'Bot จะตอบกลับ User ID ของคุณ (เริ่มต้นด้วย U...)'),
  (4, 'Copy User ID แล้ววางในช่องด้านบน'),
  (5, 'กด "บันทึก" แล้วกด "ทดสอบส่ง" เพื่อยืนยัน'),
];

class _StepItem extends StatelessWidget {
  final int number;
  final String text;
  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF06C755), shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$number',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
