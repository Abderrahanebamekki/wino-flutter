import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vitals_log.dart';
import 'auth_token_service.dart';

class VitalHistoryService {
  static const String baseUrl = 'http://zephyr.proxy.rlwy.net:28363';

  static Future<List<VitalsLog>> getVitalsHistory(int childId, String day) async {
    final token = await AuthTokenService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/daily_tracking/vitals/$childId?day=$day'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('VITALS STATUS: ${response.statusCode} for child $childId day $day');
    print('VITALS BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return [];
    }

    if (response.body.trim().isEmpty) {
      return [];
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> list;

    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['content'] is List) {
      list = decoded['content'] as List<dynamic>;
    } else if (decoded is Map && decoded['data'] is List) {
      list = decoded['data'] as List<dynamic>;
    } else {
      return [];
    }

    return list.map((json) {
      return VitalsLog(
        id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
        childId: json['childId'].toString(),
        heartbeats: json['heartbeats'] is int
            ? json['heartbeats'] as int
            : int.parse(json['heartbeats'].toString()),
        oxygenLevel: json['oxygenLevel'] is int
            ? json['oxygenLevel'] as int
            : int.parse(json['oxygenLevel'].toString()),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
    }).toList();
  }
}
