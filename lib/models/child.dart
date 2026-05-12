import 'dart:ffi';

class Child {
  final int id;
  final String firstName;
  final String lastName;
  final int age;

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
  });

  String get initials {
    return '${firstName[0]}${lastName[0]}';
  }

  String get fullName {
    return '$firstName $lastName';
  }
}