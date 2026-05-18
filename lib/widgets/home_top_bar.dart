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
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _IconButton(icon: Icons.settings, onTap: onSettingsTap),
            Expanded(
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  height: 36,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
          boxShadow: AppColors.softShadow,
        ),
        child: Icon(icon, color: Colors.grey[800], size: 22),
      ),
    );
  }
}
