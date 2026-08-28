import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/expenses_provider.dart';
import '../../../../providers/vehicles_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../services/gemini_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class PromptTemplate {
  final String category;
  final String title;
  final String prompt;
  final IconData icon;
  final Color color;

  const PromptTemplate({
    required this.category,
    required this.title,
    required this.prompt,
    required this.icon,
    required this.color,
  });
}

const List<PromptTemplate> kPromptTemplates = [
  // 1. การเงินและค่าใช้จ่าย
  PromptTemplate(
    category: 'ค่าใช้จ่าย & น้ำมัน',
    title: 'สรุปค่าน้ำมันวันนี้',
    prompt: 'ช่วยสรุปยอดค่าใช้จ่ายและค่าน้ำมันของวันนี้ให้หน่อย มีรายการอะไรเด่นๆ บ้าง?',
    icon: Icons.local_gas_station_rounded,
    color: Color(0xFFE11D48),
  ),
  PromptTemplate(
    category: 'ค่าใช้จ่าย & น้ำมัน',
    title: 'วิเคราะห์วิธีลดต้นทุน',
    prompt: 'ในฐานะที่ปรึกษากองรถ แนะนำ 3 กลยุทธ์ลดค่าน้ำมันและค่าซ่อมบำรุงที่ทำได้ทันที',
    icon: Icons.savings_rounded,
    color: Color(0xFF059669),
  ),

  // 2. ข้อมูลกองรถและพิกัด
  PromptTemplate(
    category: 'ยานพาหนะ & GPS',
    title: 'สรุปสถานะรถทั้งหมด',
    prompt: 'ในระบบมีรถกี่คัน และมีคำแนะนำการตรวจเช็คสภาพรถรายสัปดาห์อย่างไรบ้าง?',
    icon: Icons.local_shipping_rounded,
    color: Color(0xFF1E3A8A),
  ),
  PromptTemplate(
    category: 'ยานพาหนะ & GPS',
    title: 'วิธีใช้โหมดคนขับ GPS',
    prompt: 'อธิบายขั้นตอนการใช้ "โหมดคนขับ" บนมือถือเพื่อส่งพิกัด GPS ขึ้นแผนที่สด',
    icon: Icons.navigation_rounded,
    color: Color(0xFF0284C7),
  ),

  // 3. ซ่อมบำรุงเชิงป้องกัน
  PromptTemplate(
    category: 'ซ่อมบำรุง',
    title: 'รอบเปลี่ยนน้ำมันเครื่อง',
    prompt: 'รถกระบะและรถบรรทุกดีเซล ควรเปลี่ยนถ่ายน้ำมันเครื่องและไส้กรองทุกกี่กิโลเมตร?',
    icon: Icons.opacity_rounded,
    color: Color(0xFFD97706),
  ),
  PromptTemplate(
    category: 'ซ่อมบำรุง',
    title: 'ตรวจเช็คผ้าเบรก & ยาง',
    prompt: 'สัญญาณเตือนอะไรบ้างที่บ่งบอกว่าควรเปลี่ยนผ้าเบรกและสลับยางรถฟลีต?',
    icon: Icons.build_circle_rounded,
    color: Color(0xFF7C3AED),
  ),

  // 4. ระบบและการแจ้งเตือน
  PromptTemplate(
    category: 'ระบบ & LINE',
    title: 'ส่งสรุปเข้า LINE Bot',
    prompt: 'ระบบส่งสรุปรายวันเข้า LINE Bot ทำงานอย่างไร และตั้งค่าอย่างไร?',
    icon: Icons.chat_bubble_rounded,
    color: Color(0xFF06C755),
  ),
  PromptTemplate(
    category: 'ระบบ & LINE',
    title: 'พิมพ์เขียว CAD View',
    prompt: 'หน้าซ่อมบำรุงมีพิมพ์เขียว CAD View ช่วยวิเคราะห์ชิ้นส่วนรถอย่างไร?',
    icon: Icons.layers_rounded,
    color: Color(0xFF4F46E5),
  ),
];

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final GeminiService _geminiService = GeminiService();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customPrompt]) async {
    final text = (customPrompt ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    if (customPrompt == null) {
      _controller.clear();
    }
    _scrollToBottom();

    // Prepare context data from providers
    final vehiclesAsync = ref.read(vehiclesProvider);
    final expensesAsync = ref.read(expensesProvider);

    final vehicleCount = vehiclesAsync.valueOrNull?.length ?? 0;
    final expenseList = expensesAsync.valueOrNull ?? [];

    final today = DateTime.now();
    final todayExpenses = expenseList
        .where((e) =>
            e.expenseDate.year == today.year &&
            e.expenseDate.month == today.month &&
            e.expenseDate.day == today.day)
        .toList();

    final byType = <String, double>{};
    for (final expense in todayExpenses) {
      byType[expense.type] = (byType[expense.type] ?? 0) + expense.amount;
    }
    final totalSpent = todayExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    try {
      final aiResponse = await _geminiService.askAi(
        text,
        totalSpent: totalSpent,
        expenses: byType,
        vehicleCount: vehicleCount,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: aiResponse, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '⚠️ ไม่สามารถเชื่อมต่อกับ Gemini AI ได้ กรุณาตรวจสอบ API Key ในหน้าตั้งค่า AI',
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(strProvider);
    final timeFormat = DateFormat('HH:mm');
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;

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
                const Text(
                  'H2HFleet Copilot & AI Telematics',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Colors.white),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Gemini 2.5 Enterprise Flash Online',
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'ล้างประวัติการสนทนา',
              icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white70, size: 20),
              onPressed: () => setState(() => _messages.clear()),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: isLargeScreen
          ? _buildLargeScreenAiWorkspace(context, timeFormat)
          : _buildMobileAiChat(context, timeFormat),
    );
  }

  // ═══════════════ iPad & Web Dual-Pane AI Workspace ═══════════════
  Widget _buildLargeScreenAiWorkspace(BuildContext context, DateFormat timeFormat) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Left Column (AI Fleet Diagnostics & Prompts: 38%) ───
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. AI Fleet Diagnostics Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.analytics_rounded, color: Color(0xFF38BDF8), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'AI Fleet Health Audit',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'สุขภาพดีเยี่ยม 98%',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF34D399)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'AI ทำหน้าที่วิเคราะห์ค่าน้ำมัน, ตรวจสอบรอบซ่อมบำรุง และให้คำปรึกษาการบริหารกองรถแบบเรียลไทม์',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Quick Prompt Template Hub
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF7C3AED)),
                            SizedBox(width: 6),
                            Text(
                              'คำถามแนะนำ (1-Click Prompt)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...kPromptTemplates.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _sendMessage(t.prompt),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: t.color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(t.icon, size: 16, color: t.color),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                            Text(t.category, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // ─── Right Column (Interactive Chat Stream: 62%) ───
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Chat Stream
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.auto_awesome_rounded, size: 48, color: Color(0xFF7C3AED)),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'H2HFleet Copilot พร้อมตอบทุกคำถาม',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'คลิกเลือกหัวข้อทางซ้าย หรือพิมพ์คำถามของคุณด้านล่างได้เลย',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              return _MessageBubble(
                                message: msg,
                                timeStr: timeFormat.format(msg.timestamp),
                              );
                            },
                          ),
                  ),

                  // Typing Indicator
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED))),
                            SizedBox(width: 8),
                            Text('AI กำลังวิเคราะห์...', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),

                  // Chat Input Field
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'พิมพ์คำถามเกี่ยวกับกองรถ ค่าใช้จ่าย หรือพิมพ์เขียว...',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _sendMessage(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Icon(Icons.send_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════ Mobile Layout ═══════════════
  Widget _buildMobileAiChat(BuildContext context, DateFormat timeFormat) {
    return Column(
      children: [
        // Chat Stream or Welcome Template Hub
        Expanded(
          child: _messages.isEmpty
              ? _WelcomeTemplateHub(
                  onSelectTemplate: (prompt) => _sendMessage(prompt),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _MessageBubble(
                      message: msg,
                      timeStr: timeFormat.format(msg.timestamp),
                    );
                  },
                ),
        ),

        // Loading Typing Indicator
        if (_isLoading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI กำลังวิเคราะห์ข้อมูลกองรถ...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Quick Prompt Pill Bar (Always accessible above input)
        if (_messages.isNotEmpty)
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: kPromptTemplates.length,
              itemBuilder: (context, i) {
                final t = kPromptTemplates[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: Icon(t.icon, size: 14, color: t.color),
                    label: Text(
                      t.title,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.color),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: t.color.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _sendMessage(t.prompt),
                  ),
                );
              },
            ),
          ),

        // Chat Input Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom + 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'พิมพ์คำถามเกี่ยวกับกองรถ...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isLoading ? null : () => _sendMessage(),
                icon: const Icon(Icons.send_rounded, color: Color(0xFF7C3AED)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Welcome Template Hub ───────────────────────────────────────────────────
class _WelcomeTemplateHub extends StatelessWidget {
  final ValueChanged<String> onSelectTemplate;

  const _WelcomeTemplateHub({required this.onSelectTemplate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Hero Card
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA78BFA).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC4B5FD), size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ผู้ช่วย AI อัจฉริยะ (Fleet Copilot)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'สอบถามข้อมูล สรุปยอดค่าน้ำมัน รอบซ่อมบำรุง หรือวิธีใช้งานระบบได้ตลอด 24 ชม.',
                        style: TextStyle(color: Color(0xFFDDD6FE), fontSize: 11.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Template Category Header
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 6),
              Text(
                'คำถามแนะนำด่วน (คลิกเพื่อถาม AI ทันที)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2-Column Template Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kPromptTemplates.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, i) {
              final t = kPromptTemplates[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onSelectTemplate(t.prompt),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: t.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(t.icon, color: t.color, size: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.category,
                                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.prompt,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), height: 1.2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ─────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String timeStr;

  const _MessageBubble({
    required this.message,
    required this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1E3A8A) : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(3) : const Radius.circular(16),
                      bottomLeft: !isUser ? const Radius.circular(3) : const Radius.circular(16),
                    ),
                    border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isUser ? 0.08 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        message.text,
                        style: TextStyle(
                          color: isUser ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: message.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('คัดลอกข้อความแล้ว ✅'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 3),
                                  Text(
                                    'คัดลอก',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
