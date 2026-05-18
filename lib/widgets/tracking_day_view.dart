import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/child.dart';
import '../models/child_gps.dart';
import '../models/child_vitals.dart';
import '../models/child_device.dart';

class TrackingDayView extends StatelessWidget {
  final List<Child> children;
  final Map<int, ChildGps> locations;
  final Map<int, ChildHealth> health;
  final Map<int, ChildDevice> devices;

  const TrackingDayView({
    super.key,
    required this.children,
    required this.locations,
    required this.health,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const Center(
        child: Text(
          'No tracking data available',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          Text(
            'Tracking Day',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Daily GPS tracking and vital signs',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: children.length,
              itemBuilder: (context, index) => _ChildTrackingCard(
                child: children[index],
                location: locations[children[index].id],
                health: health[children[index].id],
                device: devices[children[index].id],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildTrackingCard extends StatelessWidget {
  final Child child;
  final ChildGps? location;
  final ChildHealth? health;
  final ChildDevice? device;

  const _ChildTrackingCard({
    required this.child,
    required this.location,
    required this.health,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.info,
                child: Text(
                  child.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                child.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TrackingStat(
                icon: Icons.favorite,
                label: 'Heart Beat',
                value: health != null ? '${health!.heartBeat} BPM' : '--',
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              _TrackingStat(
                icon: Icons.monitor_heart,
                label: 'Oxygen',
                value: health != null ? '${health!.oxygenLevel}%' : '--',
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              _TrackingStat(
                icon: Icons.battery_full,
                label: 'Battery',
                value: device != null ? '${device!.batteryLevel}%' : '--',
                color: AppColors.success,
              ),
            ],
          ),
          if (location != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.gps_fixed, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Lat: ${location!.latitude.toStringAsFixed(4)}, Lng: ${location!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TrackingStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
