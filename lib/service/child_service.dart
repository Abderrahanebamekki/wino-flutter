import '../models/child.dart';
import 'api_service.dart';

class ChildService {
  static Future<List<Child>> getChildren() async {
    try {
      print('==============================');
      print('START GET CHILDREN');

      final data = await ApiService.get(
        '/identity/v1/children/',
      );

      print('RAW CHILDREN RESPONSE:');
      print(data);

      final children = (data as List).map((json) {
        print('CHILD JSON: $json');

        return Child(
          id: json['id'],

          firstName: json['firstName'],

          lastName: json['lastName'],

          age: json['age'],
        );
      }).toList();

      print(
        'CHILDREN LOADED SUCCESSFULLY: ${children.length}',
      );

      print('==============================');

      return children;
    } catch (e, stackTrace) {
      print('ERROR IN getChildren()');
      print(e);
      print(stackTrace);

      rethrow;
    }
  }
}