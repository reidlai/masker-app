import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/shad_badge.dart';
import '../atoms/shad_button.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final String planName;
  final bool isPremium;
  final String priceText;
  final String renewalText;
  final List<String> features;
  final VoidCallback? onActionPressed;

  const SubscriptionPlanCard({
    super.key,
    this.planName = "Premium Plan",
    this.isPremium = true,
    this.priceText = "\$12.99 / month",
    this.renewalText = "Renews 6 Oct 2026",
    this.features = const [
      "Nocturnal 0-FPS Sleep Monitoring",
      "Real-time AASM Apnea Event Evaluation",
      "Tier-1 Emergency Siren & Caregiver Alerting",
      "Signed Physician PDF & FHIR Export",
      "Unlimited 7-Day & Monthly Trend Storage",
    ],
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                planName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              ShadBadge(
                label: isPremium ? "Active" : "Free Tier",
                variant: isPremium ? ShadBadgeVariant.normal : ShadBadgeVariant.outline,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Price Row
          if (isPremium) ...[
            Text(
              priceText,
              style: AppTheme.tabularTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              renewalText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 16),
          // Feature List
          Column(
            children: features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.accentGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Primary Action
          ShadButton(
            label: isPremium ? "Manage Subscription" : "Upgrade to Premium",
            variant: isPremium ? ShadButtonVariant.outline : ShadButtonVariant.primary,
            onPressed: onActionPressed,
          ),
        ],
      ),
    );
  }
}
