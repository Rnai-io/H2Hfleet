import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  final _dio = Dio();
  static const _prefKey = 'gemini_api_key';

  static Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key);
  }

  static Future<String> getKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? '';
  }

  Future<String> generateFleetSummary({
    required double totalSpent,
    required Map<String, double> expenses,
    required int vehicleCount,
  }) async {
    final apiKey = await getKey();
    if (apiKey.isEmpty) {
      return _localSummary(totalSpent, expenses, vehicleCount);
    }

    try {
      final prompt = expenses.isEmpty
          ? 'วันนี้ยังไม่มีค่าใช้จ่ายรถ ($vehicleCount คัน) แนะนำสิ่งที่ควรตรวจสอบประจำวันสั้นๆ'
          : 'รถ $vehicleCount คัน ค่าใช้จ่ายวันนี้รวม ${totalSpent.toStringAsFixed(0)} บาท\n'
            '${expenses.entries.map((e) => '- ${e.key}: ${e.value.toStringAsFixed(0)} บาท').join('\n')}\n\n'
            'สรุปสั้นๆ ให้เจ้าของกิจการ: มีอะไรผิดปกติไหม? ควรระวังอะไร?';

      final res = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
        queryParameters: {'key': apiKey},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
        data: {
          'system_instruction': {
            'parts': {
              'text': 'คุณเป็น AI ผู้ช่วยจัดการรถบริษัทสำหรับ SME ไทย ตอบเป็นภาษาไทยเท่านั้น กระชับ ไม่เกิน 60 คำ'
            }
          },
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 200,
            'temperature': 0.7,
          }
        },
      );

      final text = res.data['candidates']?[0]?['content']?['parts']?[0]?['text']
          ?.toString()
          .trim() ?? 'ไม่มีข้อมูลวันนี้';

      return text;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return _localSummary(totalSpent, expenses, vehicleCount);
      }
      return _localSummary(totalSpent, expenses, vehicleCount);
    } catch (e) {
      return _localSummary(totalSpent, expenses, vehicleCount);
    }
  }

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
    if (topEntry.value > 3000) {
      lines.add('⚠️ ${topEntry.key} สูงผิดปกติ ควรตรวจสอบ');
    } else {
      lines.add('✅ ค่าใช้จ่ายอยู่ในเกณฑ์ปกติ');
    }
    return lines.join('\n');
  }
}
