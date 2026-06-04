import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vital_event.dart';
import 'auth_token_service.dart';

class VitalService {
  static const String baseUrl = 'http://zephyr.proxy.rlwy.net:28363';

  static Stream<VitalEvent> listenVitals(int childId) async* {
    final token = await AuthTokenService.getToken();

    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl/daily_tracking/vitals/subscribe/$childId'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'text/event-stream',
    });

    final client = http.Client();

    try {
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        throw Exception(
          'Vitals stream failed: ${streamedResponse.statusCode}',
        );
      }

      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final line = chunk.trim();

        if (line.isEmpty) continue;
        if (!line.startsWith('data:')) continue;

        final body = line.substring(5).trim();
        final json = jsonDecode(body);

        yield VitalEvent(
          heartbeats: json['heartbeats'] as int,
          oxygenLevel: json['oxygenLevel'] as int,
        );
      }
    } finally {
      client.close();
    }
  }
}
