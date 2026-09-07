import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../molecules/settings_menu_row.dart';
import '../molecules/subscription_plan_card.dart';
import 'payment_method_page.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Billing & Subscription"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Subscription Plan Card
              SubscriptionPlanCard(
                planName: "Premium Plan",
                isPremium: true,
                priceText: "\$12.99 / month",
                renewalText: "Renews 6 Oct 2026",
                onActionPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Opening subscription management portal..."),
                      backgroundColor: AppColors.purpleAnalytics,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Payment Method Summary Card
              const Text(
                "PAYMENT METHOD ON FILE",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.04,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
                child: SettingsMenuRow(
                  leadingIcon: Icons.credit_card,
                  label: "Payment Method",
                  valueText: "Visa ·· 4242",
                  hasStatusDot: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PaymentMethodPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Billing History Section
              const Text(
                "BILLING HISTORY",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.04,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
                child: Column(
                  children: [
                    _buildInvoiceRow("6 Sep 2026", "\$12.99", "Paid"),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    _buildInvoiceRow("6 Aug 2026", "\$12.99", "Paid"),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    _buildInvoiceRow("6 Jul 2026", "\$12.99", "Paid"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String date, String amount, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Premium Monthly — $date",
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: const TextStyle(fontSize: 12, color: AppColors.accentGreen),
              ),
            ],
          ),
          Text(
            amount,
            style: AppTheme.tabularTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
