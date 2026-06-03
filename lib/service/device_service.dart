import 'api_service.dart';

class DeviceService {
  static Future<void> linkChildToDevice({
    required int childId,
    required String deviceId,
  }) async {
    try {
      print('==============================');
      print('START LINK CHILD TO DEVICE');

      await ApiService.post(
        '/device/link_child_to_device?child_id=$childId&device_id=$deviceId',
      );

      print('CHILD LINKED TO DEVICE SUCCESSFULLY');
      print('==============================');
    } catch (e, stackTrace) {
      print('ERROR IN linkChildToDevice()');
      print(e);
      print(stackTrace);

      rethrow;
    }
  }
}
