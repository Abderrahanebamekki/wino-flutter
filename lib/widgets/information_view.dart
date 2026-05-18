import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/child.dart';
import '../models/child_vitals.dart';
import '../models/child_device.dart';
import '../models/child_gps.dart';

class InformationView extends StatelessWidget {
  final List<Child> children;
  final Map<int, ChildHealth> health;
  final Map<int, ChildDevice> devices;
  final Map<int, ChildGps> locations;

  const InformationView({
    super.key,
    required this.children,
    required this.health,
    required this.devices,
    required this.locations,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const Center(
        child: Text(
          'No children added yet',
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
          Expanded(
            child: ListView.builder(
              itemCount: children.length,
              itemBuilder: (context, index) => _ChildInfoCard(
                child: children[index],
                health: health[children[index].id],
                device: devices[children[index].id],
                location: locations[children[index].id],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildInfoCard extends StatelessWidget {
  final Child child;
  final ChildHealth? health;
  final ChildDevice? device;
  final ChildGps? location;

  const _ChildInfoCard({
    required this.child,
    required this.health,
    required this.device,
    required this.location,
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
                radius: 22,
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.favorite,
                  label: 'Heart Beat',
                  value: health != null ? '${health!.heartBeat} BPM' : '--',
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.monitor_heart,
                  label: 'Oxygen',
                  value: health != null ? '${health!.oxygenLevel}%' : '--',
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.battery_full,
                  label: 'Battery',
                  value: device != null ? '${device!.batteryLevel}%' : '--',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          if (location != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.speed, color: AppColors.warning, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Speed: ${location!.speed.toStringAsFixed(1)} km/h',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
