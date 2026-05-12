import 'package:flutter/material.dart';

import '../models/child.dart';
import '../models/child_gps.dart';
import '../models/child_vitals.dart';
import '../models/child_device.dart';

void showChildDetailSheet(
  BuildContext context,
  Child child,
  ChildGps location,
  ChildHealth health,
  ChildDevice device,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.blue,
              child: Text(
                child.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              child.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(
              Icons.favorite,
              'Heart Beat',
              '${health.heartBeat} BPM',
            ),
            _infoRow(
              Icons.monitor_heart,
              'Oxygen Level',
              '${health.oxygenLevel}%',
            ),
            _infoRow(
              Icons.battery_full,
              'Battery Level',
              '${device.batteryLevel}%',
            ),
            _infoRow(
              Icons.speed,
              'Speed',
              '${location.speed.toStringAsFixed(1)} km/h',
            ),
          ],
        ),
      );
    },
  );
}

Widget _infoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(value),
      ],
    ),
  );
}
