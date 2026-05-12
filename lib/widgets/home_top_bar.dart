import 'package:flutter/material.dart';

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.grey[800], size: 24),
      ),
    );
  }
}
