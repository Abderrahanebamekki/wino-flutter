import 'dart:ffi';

class ChildGps {
   int childId;

   double latitude;
   double longitude;

   double speed;

  ChildGps({
    required this.childId,
    required this.latitude,
    required this.longitude,
    required this.speed,
  });
}