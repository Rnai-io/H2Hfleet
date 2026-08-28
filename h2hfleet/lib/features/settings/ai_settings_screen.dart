import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart';
import '../../services/gemini_service.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _saved = false;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;
  String _selectedModel = 'gemini-2.5-flash';

  @override
  void initState() {
    super.initState();
    GeminiService.getKey().then((k) {
      if (mounted) setState(() => _ctrl.text = k);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(strProvider);
    final key = _ctrl.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _saving = true;
      _saved = false;
    });
    await GeminiService.saveKey(key);
    if (mounted) {
      setState(() {
        _saving = false;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.apiKeySaved), backgroundColor: const Color(0xFF059669)),
      );
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _testConnection() async {
    final s = ref.read(strProvider);
    final key = _ctrl.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.isTh ? 'กรุณากรอก API Key ก่อนทดสอบ' : 'Please enter API Key before testing'),
          backgroundColor: const Color(0xFFEA580C),
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
      final dio = Dio();
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$_selectedModel:generateContent?key=$key';
      final res = await dio.post(
        url,
        data: {
          'contents': [
            {
              'parts': [
                {'text': 'ping'}
              ]
            }
          ]
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          _isTesting = false;
          _testSuccess = true;
          _testResult = s.isTh ? 'เชื่อมต่อ Gemini สำเร็จ! Model ตอบสนองปกติ ⚡' : 'Connected to Gemini successfully! Model is active ⚡';
        });
      } else {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Error: Status ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'Connection Failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(strProvider);
    final isTh = s.isTh;

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
                  colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.aiSettings,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                ),
                const Text(
                  'AI Telematics Copilot & Analysis Engine',
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
            // ─── 1. AI Hero Feature Card ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.25),
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
                          color: const Color(0xFFA78BFA).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.psychology_rounded, color: Color(0xFFC4B5FD), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Gemini 2.5 Flash Engine',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              isTh ? 'ระบบประมวลผลกองรถอัจฉริยะแบบเรียลไทม์' : 'Real-time Intelligent Fleet Telematics Engine',
                              style: const TextStyle(color: Color(0xFFDDD6FE), fontSize: 11),
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
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      children: [
                        _FeatureBullet(
                          icon: Icons.analytics_rounded,
                          text: 'สรุปค่าใช้จ่ายและค่าน้ำมันประจำวันอัตโนมัติ',
                        ),
                        const SizedBox(height: 6),
                        _FeatureBullet(
                          icon: Icons.shield_rounded,
                          text: 'Key จะถูกเข้ารหัสและบันทึกเฉพาะในเครื่องอย่างปลอดภัย',
                        ),
                        const SizedBox(height: 6),
                        _FeatureBullet(
                          icon: Icons.bolt_rounded,
                          text: 'ตอบสนองเร็วพิเศษ พร้อมส่งวิเคราะห์เข้า LINE ได้ทันที',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ─── 2. Model Selection Selector ────────────────────────────────
            const Text(
              'เลือกโมเดล AI (AI Model Engine)',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ModelOptionTile(
                    title: 'Gemini 2.5 Flash',
                    subtitle: 'เร็วสุด · แนะนำ (Free)',
                    badge: 'เร็ว & แม่นยำ',
                    isSelected: _selectedModel == 'gemini-2.5-flash',
                    onTap: () => setState(() => _selectedModel = 'gemini-2.5-flash'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModelOptionTile(
                    title: 'Gemini 1.5 Pro',
                    subtitle: 'วิเคราะห์เชิงลึก',
                    badge: 'Pro Tier',
                    isSelected: _selectedModel == 'gemini-1.5-pro',
                    onTap: () => setState(() => _selectedModel = 'gemini-1.5-pro'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ─── 3. API Key Input Section ───────────────────────────────────
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Google Gemini API Key',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'aistudio.google.com',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ],
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
                controller: _ctrl,
                obscureText: _obscure,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF7C3AED), size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 19,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      if (_ctrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () => setState(() => _ctrl.clear()),
                        ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 6),
            const Text(
              '💡 ฟรี! รับ API Key ได้ทันทีโดยไม่ต้องผูกบัตรเครดิตที่ Google AI Studio',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 16),

            // Test Connection Status Alert
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

            // ─── 4. Action Buttons ──────────────────────────────────────────
            Row(
              children: [
                // Test Connection Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                          )
                        : const Icon(Icons.cable_rounded, size: 16),
                    label: Text(_isTesting ? 'กำลังทดสอบ...' : 'ทดสอบการเชื่อมต่อ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
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
                    onPressed: _saving ? null : _save,
                    icon: _saved
                        ? const Icon(Icons.check_circle_rounded, size: 18)
                        : _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      _saved ? 'บันทึกสำเร็จ!' : 'บันทึก API Key',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _saved ? const Color(0xFF10B981) : const Color(0xFF1E3A8A),
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

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 14),
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

class _ModelOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModelOptionTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3E8FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
