import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_token_service.dart';

class ApiService {
  static const String baseUrl = 'http://zephyr.proxy.rlwy.net:28363';

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

  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await headers(),
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return null;
      return jsonDecode(response.body);
    }

    throw Exception('Request failed: ${response.statusCode}');
  }
}