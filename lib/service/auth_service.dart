import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'auth_token_service.dart';

class AuthService {
  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/v1/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Sign in failed: ${response.statusCode}');
    }

    final body = response.body.trim();
    String token;

    if (body.startsWith('{')) {
      final decoded = jsonDecode(body);
      token = decoded['token']?.toString() ?? decoded['accessToken']?.toString() ?? body;
    } else {
      token = body;
    }

    await AuthTokenService.saveToken(token);
  }
}
