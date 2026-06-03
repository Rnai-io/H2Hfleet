import 'package:dio/dio.dart';

class OpenAIService {
  final _dio = Dio();

  // OpenAI Responses API (gpt-5.4-mini)
  // ใส่ API Key จริงที่นี่ (อย่า commit ขึ้น GitHub)
  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const _model = 'gpt-5.4-mini';
  static const _endpoint = 'https://api.openai.com/v1/responses';

  Future<String> generateFleetSummary({
    required double totalSpent,
    required Map<String, double> expenses,
    required int vehicleCount,
  }) async {
    try {
      final prompt = _buildPrompt(
        totalSpent: totalSpent,
        expenses: expenses,
        vehicleCount: vehicleCount,
      );

      final response = await _dio.post(
        _endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'instructions':
              'คุณเป็น AI ผู้ช่วยจัดการรถบริษัทสำหรับ SME ไทย ตอบเป็นภาษาไทยเท่านั้น กระชับ ไม่เกิน 60 คำ',
          'input': prompt,
          'max_output_tokens': 200,
          'temperature': 0.7,
        },
      );

      // Responses API format:
      // response.data['output'][0]['content'][0]['text']
      final output = response.data['output'] as List?;
      if (output == null || output.isEmpty) return 'ไม่มีข้อมูลวันนี้';

      final content = output[0]['content'] as List?;
      if (content == null || content.isEmpty) return 'ไม่มีข้อมูลวันนี้';

      return content[0]['text']?.toString().trim() ?? 'ไม่มีข้อมูลวันนี้';
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final msg = e.response?.data?['error']?['message'] ?? e.message;
      return 'AI Error ($statusCode): $msg';
    } catch (e) {
      return 'ไม่สามารถสร้างสรุปได้ในขณะนี้';
    }
  }

  String _buildPrompt({
    required double totalSpent,
    required Map<String, double> expenses,
    required int vehicleCount,
  }) {
    if (expenses.isEmpty) {
      return 'วันนี้ยังไม่มีค่าใช้จ่ายรถ ($vehicleCount คัน) แนะนำสิ่งที่ควรตรวจสอบประจำวันสั้นๆ';
    }

    final expenseList = expenses.entries
        .map((e) => '- ${e.key}: ${e.value.toStringAsFixed(0)} บาท')
        .join('\n');

    return '''
รถ $vehicleCount คัน ค่าใช้จ่ายวันนี้รวม ${totalSpent.toStringAsFixed(0)} บาท
$expenseList

สรุปสั้นๆ ให้เจ้าของกิจการ: มีค่าใช้จ่ายอะไรผิดปกติไหม? ควรระวังอะไร?''';
   }
}
