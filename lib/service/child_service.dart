import '../models/child.dart';
import 'api_service.dart';

class ChildService {
  static Future<Child> addChild({
    required String firstName,
    required String lastName,
    required int age,
  }) async {
    try {
      print('==============================');
      print('START ADD CHILD');

      final data = await ApiService.post(
        '/identity/v1/children/child',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'age': age,
        },
      );

      print('ADD CHILD RESPONSE:');
      print(data);

      final child = Child(
        id: data['id'],
        firstName: data['firstName'],
        lastName: data['lastName'],
        age: data['age'],
      );

      print('CHILD ADDED SUCCESSFULLY: id=${child.id}');
      print('==============================');

      return child;
    } catch (e, stackTrace) {
      print('ERROR IN addChild()');
      print(e);
      print(stackTrace);

      rethrow;
    }
  }

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