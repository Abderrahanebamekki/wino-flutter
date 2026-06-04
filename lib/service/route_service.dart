import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/gps_log.dart';
import 'auth_token_service.dart';

class RouteService {
  static const String baseUrl = 'http://zephyr.proxy.rlwy.net:28363';

  static Future<List<GpsLog>> getRoute(int childId, String date) async {
    final token = await AuthTokenService.getToken();

    final uri = Uri.parse('$baseUrl/daily_tracking/route/$childId?date=$date');
    print('ROUTE REQUEST: $uri');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    print('ROUTE STATUS: ${response.statusCode}');
    print('ROUTE BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    if (response.body.trim().isEmpty) {
      return [];
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((json) {
        return GpsLog(
          id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
          childId: json['childId'].toString(),
          longitude: (json['longitude'] as num).toDouble(),
          latitude: (json['latitude'] as num).toDouble(),
          speed: (json['speed'] as num).toDouble(),
          timestamp: DateTime.parse(json['timestamp'] as String),
        );
      }).toList();
    }

    if (decoded is Map && decoded['content'] is List) {
      return _parseList(decoded['content'] as List);
    }

    if (decoded is Map && decoded['data'] is List) {
      return _parseList(decoded['data'] as List);
    }

    print('ROUTE UNEXPECTED FORMAT: $decoded');
    return [];
  }

  static List<GpsLog> _parseList(List<dynamic> list) {
    return list.map((json) {
      return GpsLog(
        id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
        childId: json['childId'].toString(),
        longitude: (json['longitude'] as num).toDouble(),
        latitude: (json['latitude'] as num).toDouble(),
        speed: (json['speed'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
    }).toList();
  }
}
