import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppColors.formPadding,
    this.borderRadius = AppColors.radiusXLarge,
    this.margin,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
      ),
      child: child,
    );
  }
}
