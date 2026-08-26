import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  final _dio = Dio();
  static const _prefKey = 'gemini_api_key';

  // ─── model ที่ใช้งาน ──────────────────────────────────
  // gemini-2.5-flash-preview-05-20 = Gemini 2.5 Flash (รองรับ free tier)
  static const _model = 'gemini-2.5-flash-preview-05-20';
  static String get _url =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  // ─── Key management ───────────────────────────────────
  static Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key.trim());
  }

  static Future<String> getKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? '';
  }

  // ─── ส่ง request ไปยัง Gemini ─────────────────────────
  Future<Map<String, dynamic>> _callGemini({
    required String apiKey,
    required String systemInstruction,
    required String userPrompt,
    int maxTokens = 400,
  }) async {
    final res = await _dio.post(
      _url,
      queryParameters: {'key': apiKey},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        validateStatus: (_) => true, // ไม่ throw exception ทุก status code
      ),
      data: {
        'system_instruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'contents': [
          {
            'parts': [
              {'text': userPrompt}
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': maxTokens,
          'temperature': 0.7,
        }
      },
    );

    log('[GeminiService] HTTP ${res.statusCode}');
    log('[GeminiService] Body: ${res.data}');

    return {'statusCode': res.statusCode ?? 0, 'data': res.data};
  }

  // ─── ถอด text จาก response ────────────────────────────
  String? _extractText(dynamic data) {
    try {
      return data['candidates']?[0]?['content']?['parts']?[0]?['text']
          ?.toString()
          .trim();
    } catch (_) {
      return null;
    }
  }

  // ─── แปล error code เป็นข้อความภาษาไทย ───────────────
  String _errorMessage(int statusCode, dynamic data) {
    final msg = data?['error']?['message']?.toString() ?? '';
    switch (statusCode) {
      case 429:
        return '⏳ API ถูกใช้งานมากเกินไป กรุณารอ 1 นาทีแล้วลองใหม่ครับ (429 Rate Limit)';
      case 400:
        return '❌ คำขอไม่ถูกต้อง${msg.isNotEmpty ? ": $msg" : ""}';
      case 401:
      case 403:
        return '🔑 API Key ไม่ถูกต้องหรือหมดอายุ กรุณาไปตั้งค่าใหม่ที่ Settings → AI Settings';
      case 404:
        return '❌ ไม่พบ Model ที่ระบุ (404) กรุณาติดต่อผู้พัฒนา';
      case 500:
      case 503:
        return '🔧 เซิร์ฟเวอร์ Gemini มีปัญหาชั่วคราว ลองใหม่ในอีกสักครู่ครับ ($statusCode)';
      default:
        return '❌ เกิดข้อผิดพลาด (HTTP $statusCode)${msg.isNotEmpty ? ": $msg" : ""}';
    }
  }

  // ─── Dashboard summary ────────────────────────────────
  Future<String> generateFleetSummary({
    required double totalSpent,
    required Map<String, double> expenses,
    required int vehicleCount,
  }) async {
    final apiKey = await getKey();
    if (apiKey.isEmpty) return _localSummary(totalSpent, expenses, vehicleCount);

    try {
      final prompt = expenses.isEmpty
          ? 'วันนี้ยังไม่มีค่าใช้จ่ายรถ ($vehicleCount คัน) แนะนำสิ่งที่ควรตรวจสอบประจำวันสั้นๆ'
          : 'รถ $vehicleCount คัน ค่าใช้จ่ายวันนี้รวม ${totalSpent.toStringAsFixed(0)} บาท\n'
            '${expenses.entries.map((e) => '- ${e.key}: ${e.value.toStringAsFixed(0)} บาท').join('\n')}\n\n'
            'สรุปสั้นๆ ให้เจ้าของกิจการ: มีอะไรผิดปกติไหม? ควรระวังอะไร?';

      final result = await _callGemini(
        apiKey: apiKey,
        systemInstruction:
            'คุณเป็น AI ผู้ช่วยจัดการรถบริษัทสำหรับ SME ไทย ตอบเป็นภาษาไทยเท่านั้น กระชับ ไม่เกิน 80 คำ',
        userPrompt: prompt,
        maxTokens: 200,
      );

      final statusCode = result['statusCode'] as int;
      if (statusCode != 200) return _localSummary(totalSpent, expenses, vehicleCount);

      return _extractText(result['data']) ?? _localSummary(totalSpent, expenses, vehicleCount);
    } catch (e) {
      log('[GeminiService] generateFleetSummary error: $e');
      return _localSummary(totalSpent, expenses, vehicleCount);
    }
  }

  // ─── AI Chat ──────────────────────────────────────────
  Future<String> askAi(
    String question, {
    required double totalSpent,
    required Map<String, double> expenses,
    required int vehicleCount,
  }) async {
    final apiKey = await getKey();
    if (apiKey.isEmpty) {
      return 'ยังไม่ได้ตั้งค่า Gemini API Key\nกรุณาไปที่ Settings → AI Settings แล้วใส่ Key ของคุณ\n(หา Key ฟรีได้ที่ aistudio.google.com)';
    }

    try {
      final context = expenses.isEmpty
          ? 'ข้อมูลปัจจุบัน:\n- รถทั้งหมด $vehicleCount คัน\n- วันนี้ยังไม่มีค่าใช้จ่าย'
          : 'ข้อมูลปัจจุบัน:\n'
            '- รถทั้งหมด $vehicleCount คัน\n'
            '- ค่าใช้จ่ายวันนี้รวม ${totalSpent.toStringAsFixed(0)} บาท\n'
            '- รายละเอียด:\n'
            '${expenses.entries.map((e) => '  • ${e.key}: ${e.value.toStringAsFixed(0)} บาท').join('\n')}';

      final result = await _callGemini(
        apiKey: apiKey,
        systemInstruction:
            'คุณเป็น AI ผู้ช่วยจัดการรถบริษัทสำหรับ SME ตอบคำถามผู้ใช้โดยอ้างอิงจากข้อมูลที่ให้ไว้ ตอบเป็นภาษาไทย กระชับ เป็นประโยชน์',
        userPrompt: '$context\n\nคำถาม: $question',
        maxTokens: 500,
      );

      final statusCode = result['statusCode'] as int;
      if (statusCode != 200) {
        return _errorMessage(statusCode, result['data']);
      }

      final answer = _extractText(result['data']);
      if (answer == null || answer.isEmpty) {
        return 'ขออภัย AI ไม่สามารถตอบคำถามนี้ได้ ลองถามใหม่อีกครั้งครับ';
      }

      return answer;
    } on DioException catch (e) {
      log('[GeminiService] DioException: ${e.type} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return '⏱️ หมดเวลารอ AI กรุณาลองใหม่อีกครั้งครับ (Timeout)';
      }
      if (e.type == DioExceptionType.connectionError) {
        return '📶 ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อครับ';
      }
      return '❌ เชื่อมต่อ AI ไม่ได้: ${e.message}';
    } catch (e) {
      log('[GeminiService] Unexpected error: $e');
      return '❌ เกิดข้อผิดพลาดที่ไม่คาดคิด: ${e.toString()}';
    }
  }

  // ─── Fallback (offline) ───────────────────────────────
  String _localSummary(
    double totalSpent,
    Map<String, double> expenses,
    int vehicleCount,
  ) {
    if (expenses.isEmpty) {
      return '🚛 วันนี้ยังไม่มีค่าใช้จ่าย ($vehicleCount คัน)\n✅ อย่าลืมตรวจน้ำมัน ยาง และสภาพรถ';
    }
    final topEntry = expenses.entries.reduce((a, b) => a.value > b.value ? a : b);
    final lines = <String>['📊 สรุปวันนี้: ฿${totalSpent.toStringAsFixed(0)} บาท ($vehicleCount คัน)'];
    for (final e in expenses.entries) {
      lines.add('• ${e.key}: ฿${e.value.toStringAsFixed(0)}');
    }
    lines.add('');
    lines.add(topEntry.value > 3000
        ? '⚠️ ${topEntry.key} สูงผิดปกติ ควรตรวจสอบ'
        : '✅ ค่าใช้จ่ายอยู่ในเกณฑ์ปกติ');
    return lines.join('\n');
  }
}
