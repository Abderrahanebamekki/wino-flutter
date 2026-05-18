import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MembershipView extends StatelessWidget {
  const MembershipView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          Text(
            'Membership',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exclusive plans and offers for your family',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _MembershipCard(
                  title: 'Basic Plan',
                  price: 'Free',
                  features: ['Track up to 2 children', 'Basic safe zones', 'Email support'],
                  color: AppColors.info,
                ),
                const SizedBox(height: 14),
                _MembershipCard(
                  title: 'Premium Plan',
                  price: '\$9.99/mo',
                  features: ['Unlimited children', 'Advanced safe zones', 'Real-time alerts', 'Priority support', 'Health monitoring'],
                  color: AppColors.primary,
                ),
                const SizedBox(height: 14),
                _MembershipCard(
                  title: 'Family Plan',
                  price: '\$19.99/mo',
                  features: ['Unlimited children', 'All premium features', 'Multi-parent access', 'Extended tracking history', '24/7 support'],
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final Color color;

  const _MembershipCard({
    required this.title,
    required this.price,
    required this.features,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
