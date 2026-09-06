import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../molecules/payment_method_card.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  bool _hasCard = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Payment Method"),
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
              const Text(
                "CARD ON FILE",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.04,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              PaymentMethodCard(
                cardBrand: "Visa",
                lastFour: "4242",
                expiryDate: "08 / 27",
                cardHolder: "David Miller",
                isEmpty: !_hasCard,
                onReplaceCard: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Launching secure card entry sheet..."),
                      backgroundColor: AppColors.accentGreen,
                    ),
                  );
                },
                onRemoveCard: () {
                  setState(() {
                    _hasCard = false;
                  });
                },
                onAddCard: () {
                  setState(() {
                    _hasCard = true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
