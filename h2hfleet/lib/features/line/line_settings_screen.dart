import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isSaved = false;
  String? _testResult;
  bool? _testSuccess;

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
          content: Text('กรุณากรอก LINE User ID'),
          backgroundColor: Color(0xFFEA580C),
        ),
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _isSaved = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('line_user_id', _userIdCtrl.text.trim());
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSaved = false);
    });
  }

  Future<void> _testSend() async {
    final userId = _userIdCtrl.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอก LINE User ID ก่อนทดสอบ'),
          backgroundColor: Color(0xFFEA580C),
        ),
      );
      return;
    }
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    try {
      const supabaseUrl = 'https://rdobhvuiadmsqdfugrlp.supabase.co';
      const anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkb2JodnVpYWRtc3FkZnVncmxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNjU4MzMsImV4cCI6MjA5NDc0MTgzM30.7pvs8B38unEmBkPmP14lfgDrr59wjd-WroMiqpkIzvY';

      final dio = Dio(BaseOptions(validateStatus: (status) => true));

      final response = await dio.post(
        '$supabaseUrl/functions/v1/line-push-message',
        data: jsonEncode({
          'userId': userId,
          'message': '✅ H2HFleet Telematics: ทดสอบการเชื่อมต่อ LINE สำเร็จ!\n\nระบบพร้อมแจ้งเตือนสรุปรายวันและรายงานด่วนแล้วครับ 🚛⚡',
        }),
        options: Options(headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        }),
      );

      if (mounted) {
        final ok = response.statusCode == 200;
        setState(() {
          _testSuccess = ok;
          _testResult = ok
              ? 'ส่งข้อความทดสอบเข้า LINE สำเร็จแล้ว! กรุณาเช็คในแอป LINE'
              : 'เกิดข้อผิดพลาด: [${response.statusCode}] ${response.data}';
        });
      }
    } on DioException catch (e) {
      final body = e.response?.data?.toString() ?? e.message ?? '$e';
      if (mounted) {
        setState(() {
          _testSuccess = false;
          _testResult = 'LINE Error: $body';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testSuccess = false;
          _testResult = 'Network Error: $e';
        });
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 54,
        titleSpacing: 4,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
          child: Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06C755), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ตั้งค่า LINE Notify',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                ),
                Text(
                  'Automated Broadcast & Daily Summary',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. LINE Hero Banner Card ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.send_rounded, color: Color(0xFFA7F3D0), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LINE Notification Gateway',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'รับรายงานสรุปค่าใช้จ่ายและแจ้งเตือนผ่าน LINE ทันที',
                              style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Column(
                      children: [
                        _LineFeatureBullet(
                          icon: Icons.flash_on_rounded,
                          text: 'ส่งสรุป AI Copilot เข้า LINE ใน 1 คลิก',
                        ),
                        SizedBox(height: 6),
                        _LineFeatureBullet(
                          icon: Icons.notifications_active_rounded,
                          text: 'แจ้งเตือนค่าใช้จ่าย ค่าน้ำมัน และงานซ่อมบำรุง',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ─── 2. How to get LINE User ID Steps ───────────────────────────
            const Text(
              'วิธีรับ LINE User ID (3 ขั้นตอนง่ายๆ)',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            _StepCard(
              stepNumber: '1',
              title: 'เพิ่มเพื่อน LINE Bot ของระบบ',
              desc: 'สแกน QR Code หรือเพิ่มเพื่อน LINE Official ของ H2HFleet',
              icon: Icons.person_add_rounded,
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(height: 8),
            _StepCard(
              stepNumber: '2',
              title: 'พิมพ์คำว่า "id" ในห้องแชท LINE',
              desc: 'บอทจะตอบกลับเป็นรหัส User ID ขึ้นต้นด้วยตัว U (เช่น U4a8...)',
              icon: Icons.chat_rounded,
              color: const Color(0xFF059669),
            ),
            const SizedBox(height: 8),
            _StepCard(
              stepNumber: '3',
              title: 'คัดลอกมาวางในช่องด้านล่างนี้',
              desc: 'กดปุ่ม "ทดสอบส่งข้อความ" เพื่อยืนยันการเชื่อมต่อ',
              icon: Icons.verified_rounded,
              color: const Color(0xFF7C3AED),
            ),

            const SizedBox(height: 22),

            // ─── 3. LINE User ID Input Section ──────────────────────────────
            const Text(
              'LINE User ID (ผู้รับแจ้งเตือน)',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _userIdCtrl,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Uxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: const Icon(Icons.account_circle_rounded, color: Color(0xFF06C755), size: 22),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'วางจากคลิปบอร์ด',
                        icon: const Icon(Icons.paste_rounded, color: Color(0xFF0284C7), size: 19),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null && mounted) {
                            setState(() => _userIdCtrl.text = data!.text!.trim());
                          }
                        },
                      ),
                      if (_userIdCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () => setState(() => _userIdCtrl.clear()),
                        ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Result Alert Banner
            if (_testResult != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _testSuccess == true ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _testSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess == true ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: _testSuccess == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _testSuccess == true ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── 4. Actions Row ─────────────────────────────────────────────
            Row(
              children: [
                // Test Push Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testSend,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06C755)),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(_isTesting ? 'กำลังส่ง...' : 'ทดสอบส่งข้อความ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF059669), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Save Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaved
                        ? const Icon(Icons.check_circle_rounded, size: 18)
                        : _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      _isSaved ? 'บันทึกสำเร็จ!' : 'บันทึก LINE ID',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved ? const Color(0xFF10B981) : const Color(0xFF06C755),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineFeatureBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LineFeatureBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6EE7B7), size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
