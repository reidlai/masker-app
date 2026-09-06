import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/shad_button.dart';

class PaymentMethodCard extends StatelessWidget {
  final String cardBrand;
  final String lastFour;
  final String expiryDate;
  final String cardHolder;
  final bool isEmpty;
  final VoidCallback? onReplaceCard;
  final VoidCallback? onRemoveCard;
  final VoidCallback? onAddCard;

  const PaymentMethodCard({
    super.key,
    this.cardBrand = "Visa",
    this.lastFour = "4242",
    this.expiryDate = "08 / 27",
    this.cardHolder = "David Miller",
    this.isEmpty = false,
    this.onReplaceCard,
    this.onRemoveCard,
    this.onAddCard,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.credit_card_outlined,
              size: 36,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              "No payment method on file.",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ShadButton(
              label: "Add Card",
              variant: ShadButtonVariant.primary,
              onPressed: onAddCard,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Brand mark + Masked number
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B4B),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF4338CA), width: 1),
                        ),
                        child: Text(
                          cardBrand.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "·· ·· ·· $lastFour",
                        style: AppTheme.tabularTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Row 2: Expiry & Cardholder name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Expires $expiryDate",
                    style: AppTheme.tabularTextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    cardHolder,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Management Action Buttons
        Row(
          children: [
            Expanded(
              child: ShadButton(
                label: "Replace Card",
                variant: ShadButtonVariant.outline,
                onPressed: onReplaceCard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ShadButton(
                label: "Remove Card",
                variant: ShadButtonVariant.danger,
                onPressed: onRemoveCard,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
