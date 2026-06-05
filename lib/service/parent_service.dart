import 'package:http/http.dart' as http;

import 'auth_token_service.dart';
import 'api_service.dart';

class ParentService {
  static Future<String> getFullName() async {
    final token = await AuthTokenService.getToken();

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/identity/v1/parents/fullname'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.trim();
    }

    throw Exception('Failed to get parent name: ${response.statusCode}');
  }
}
