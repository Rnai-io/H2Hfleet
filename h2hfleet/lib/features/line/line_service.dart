import 'package:dio/dio.dart';

class LineService {
  final _dio = Dio();

  Future<bool> sendNotify({required String token, required String message}) async {
    try {
      final response = await _dio.post(
        'https://notify-api.line.me/api/notify',
        data: {'message': message},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String buildDailySummary({
    required int vehicleCount,
    required double todayTotal,
    required double monthTotal,
    required String aiSummary,
  }) {
    final buf = StringBuffer();
    buf.writeln('\n🚛 H2HFleet รายงานประจำวัน');
    buf.writeln('──────────────────');
    buf.writeln('🚘 รถทั้งหมด: $vehicleCount คัน');
    buf.writeln('💰 ค่าใช้จ่ายวันนี้: ฿${todayTotal.toStringAsFixed(0)}');
    buf.writeln('📅 ค่าใช้จ่ายเดือนนี้: ฿${monthTotal.toStringAsFixed(0)}');
    buf.writeln('──────────────────');
    buf.writeln('🤖 AI: $aiSummary');
    return buf.toString();
  }
}
