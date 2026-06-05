import 'package:winop/models/safe_zone.dart';

import 'api_service.dart';

class SafezoneService {
  static Future<void> createSafeZone({
    required String name,
    required double radius,
    required double longitude,
    required double latitude,
    required int childId,
  }) async {
    try {
      print('==============================');
      print('START CREATE SAFE ZONE');

      await ApiService.post(
        '/geofencing/safezones/',
        body: {
          'name': name,
          'radius': radius,
          'longitude': longitude,
          'latitude': latitude,
          'childId': childId,
        },
      );

      print('SAFE ZONE CREATED SUCCESSFULLY');
      print('==============================');
    } catch (e, stackTrace) {
      print('ERROR IN createSafeZone()');
      print(e);
      print(stackTrace);
      rethrow;
    }
  }

  static Future<List<SafeZone>> getSafeZone(int childId) async {
    try {
      print('==============================');
      print('START GET SAFE ZONES');

      final data = await ApiService.get(
        '/geofencing/safezones/child/$childId'
      );

      print('RAW Safe Zones RESPONSE:');
      print(data);

      final safezones = (data as List).map((json) {
        print('SafeZone JSON: $json');

        return SafeZone(
          id: json['id'] as int,
          name: json['name'] as String,
          latitude: (json['latitude'] as num).toDouble(),
          longitude: (json['longitude'] as num).toDouble(),
          radius: (json['radius'] as num).toDouble(),
        );
      }).toList();

      print(
        'Safe zoes LOADED SUCCESSFULLY: ${safezones.length}',
      );

      print('==============================');

      return safezones;
    } catch (e, stackTrace) {
      print('ERROR IN getChildren()');
      print(e);
      print(stackTrace);

      rethrow;
    }
  }

  static Future<void> updateSafezone({
    required int id,
    required String name,
    required double radius,
    required double longitude,
    required double latitude,
  }) async {
    await ApiService.put(
      '/geofencing/safezones/$id',
      body: {
        'name': name,
        'radius': radius,
        'longitude': longitude,
        'latitude': latitude,
      },
    );
  }

  static Future<void> deleteSafezone(int id) async {
    await ApiService.delete('/geofencing/safezones/$id');
  }
}