import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            _IconButton(icon: Icons.settings, onTap: onSettingsTap),
            Expanded(
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            _IconButton(icon: Icons.message, onTap: onMessagesTap),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        ),
        child: Icon(icon, color: Colors.grey[800], size: 24),
      ),
    );
  }
}
