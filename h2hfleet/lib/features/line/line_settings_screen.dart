import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerStatefulWidget, ConsumerState;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import 'line_service.dart';

class LineSettingsScreen extends ConsumerStatefulWidget {
  const LineSettingsScreen({super.key});

  @override
  ConsumerState<LineSettingsScreen> createState() => _LineSettingsScreenState();
}

class _LineSettingsScreenState extends ConsumerState<LineSettingsScreen> {
  final _tokenCtrl = TextEditingController();
  bool _obscure = true;
  bool _isTesting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('line_notify_token') ?? '';
    if (mounted) _tokenCtrl.text = token;
  }

  Future<void> _saveToken() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('line_notify_token', _tokenCtrl.text.trim());
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึก Token สำเร็จ'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _testSend() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาใส่ LINE Notify Token ก่อน')),
      );
      return;
    }
    setState(() => _isTesting = true);
    final ok = await LineService().sendNotify(
      token: token,
      message: '\n✅ H2HFleet: ทดสอบการส่งข้อความสำเร็จ!',
    );
    if (mounted) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'ส่งข้อความทดสอบสำเร็จ! ✅' : 'ส่งไม่สำเร็จ กรุณาตรวจสอบ Token'),
          backgroundColor: ok ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF06C755),
        foregroundColor: Colors.white,
        title: const Text('LINE Notify',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanation card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F9EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF06C755).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.chat_bubble_rounded, color: Color(0xFF06C755), size: 20),
                      SizedBox(width: 8),
                      Text('LINE Notify คืออะไร?',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'LINE Notify ช่วยส่งสรุปรายงานรถของคุณเข้า LINE โดยอัตโนมัติ ทำให้ติดตามค่าใช้จ่ายได้ง่ายขึ้น',
                    style: TextStyle(fontSize: 13, color: Color(0xFF065F46), height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF06C755)),
                    label: const Text('วิธีรับ Token จาก LINE Notify',
                        style: TextStyle(fontSize: 12, color: Color(0xFF06C755))),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('LINE Notify Token',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tokenCtrl,
              obscureText: _obscure,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'วาง Token ที่นี่...',
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
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textSecondary, size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),

            const SizedBox(height: 16),

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
                    onPressed: _isSaving ? null : _saveToken,
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

            const Text('วิธีใช้งาน',
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
  (1, 'เข้าไปที่ notify-bot.line.me แล้ว login ด้วยบัญชี LINE'),
  (2, 'กด "Generate token" แล้วเลือกห้อง LINE ที่ต้องการรับข้อความ'),
  (3, 'Copy Token ที่ได้มาวางในช่องด้านบน'),
  (4, 'กด "ทดสอบส่ง" เพื่อยืนยันว่า Token ถูกต้อง'),
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
