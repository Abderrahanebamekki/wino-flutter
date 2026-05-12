import 'dart:ffi';

class ChildHealth {
   int childId;

   int heartBeat;
   int oxygenLevel;

  ChildHealth({
    required this.childId,
    required this.heartBeat,
    required this.oxygenLevel,
  });
}