import 'package:http/http.dart' as http;

import 'auth_token_service.dart';

class BatteryService {
  static const String baseUrl = 'http://zephyr.proxy.rlwy.net:28363';

  static Future<String> getBattery(int childId) async {
    final token = await AuthTokenService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/daily_tracking/battery/$childId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.trim();
    }

    throw Exception('Battery request failed: ${response.statusCode}');
  }
}
