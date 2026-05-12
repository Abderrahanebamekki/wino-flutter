import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_token_service.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8081';

  static Future<Map<String, String>> headers() async {
    final token = await AuthTokenService.getToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception('Request failed: ${response.statusCode}');
  }
}