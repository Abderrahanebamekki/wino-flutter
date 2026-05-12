import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/child_gps.dart';
import 'auth_token_service.dart';

class ChildLocationService {
  static const String baseUrl = 'http://10.0.2.2:8081';

  static Future<ChildGps> getLocation(int childId) async {
    final stream = listenLocation(childId);

    return await stream.first.timeout(
      const Duration(seconds: 10),
    );
  }

  static Stream<ChildGps> listenLocation(int childId) async* {
    final token = await AuthTokenService.getToken();

    print('==============================');
    print('START GPS STREAM FOR CHILD: $childId');

    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl/geofencing/gps/$childId'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'text/event-stream',
    });

    final client = http.Client();

    try {
      final streamedResponse = await client.send(request);

      print('GPS STATUS: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        throw Exception(
          'GPS stream failed: ${streamedResponse.statusCode}',
        );
      }

      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final line = chunk.trim();

        if (line.isEmpty) continue;

        print('GPS LINE: $line');

        if (!line.startsWith('data:')) {
          continue;
        }

        final body = line.substring(5).trim();

        print('GPS JSON BODY: $body');

        final json = jsonDecode(body);

        final gps = ChildGps(
          childId: childId,

          // Your backend sends:
          // longitude: 6.x
          // latitude: 36.x
          latitude: json['latitude'].toDouble(),
          longitude: json['longitude'].toDouble(),

          speed: json['speed'].toDouble(),
        );

        print(
          'GPS UPDATED: lat=${gps.latitude}, lng=${gps.longitude}, speed=${gps.speed}',
        );

        yield gps;
      }
    } finally {
      client.close();
      print('GPS STREAM CLOSED FOR CHILD: $childId');
    }
  }
}