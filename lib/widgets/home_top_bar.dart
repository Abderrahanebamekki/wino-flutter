import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HomeTopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onMessagesTap;

  const HomeTopBar({
    super.key,
    required this.onSettingsTap,
    required this.onMessagesTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIconButton(icon: Icons.settings, onTap: onSettingsTap),
            _buildIconButton(icon: Icons.message, onTap: onMessagesTap),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
          boxShadow: AppColors.softShadow,
        ),
        child: Icon(icon, color: Colors.grey[800], size: 24),
      ),
    );
  }
}
