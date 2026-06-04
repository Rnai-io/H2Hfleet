import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenAIService {
  final _dio = Dio();
  static const _prefKey = 'openai_api_key';

  static Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key);
  }

  static Future<String> getKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? '';
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

  Future<String> generateFleetSummary({
    required double totalSpent,
    required Map<String, double> expenses,
    required int vehicleCount,
  }) async {
    final apiKey = await getKey();
    if (apiKey.isEmpty) return 'ยังไม่ได้ตั้งค่า OpenAI API Key\nไปที่ Settings → AI Settings';

    try {
      final prompt = expenses.isEmpty
          ? 'วันนี้ยังไม่มีค่าใช้จ่ายรถ ($vehicleCount คัน) แนะนำสิ่งที่ควรตรวจสอบประจำวันสั้นๆ'
          : 'รถ $vehicleCount คัน ค่าใช้จ่ายวันนี้รวม ${totalSpent.toStringAsFixed(0)} บาท\n'
            '${expenses.entries.map((e) => '- ${e.key}: ${e.value.toStringAsFixed(0)} บาท').join('\n')}\n\n'
            'สรุปสั้นๆ ให้เจ้าของกิจการ: มีอะไรผิดปกติไหม? ควรระวังอะไร?';

      final res = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
        data: {
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'คุณเป็น AI ผู้ช่วยจัดการรถบริษัทสำหรับ SME ไทย ตอบเป็นภาษาไทยเท่านั้น กระชับ ไม่เกิน 60 คำ',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        },
      );

      return res.data['choices'][0]['message']['content']?.toString().trim()
          ?? 'ไม่มีข้อมูลวันนี้';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return _localSummary(totalSpent, expenses, vehicleCount);
      }
      if (e.response?.statusCode == 429) {
        return _localSummary(totalSpent, expenses, vehicleCount);
      }
      return _localSummary(totalSpent, expenses, vehicleCount);
    } catch (e) {
      return _localSummary(totalSpent, expenses, vehicleCount);
    }
  }
}
