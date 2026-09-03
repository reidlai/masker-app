import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_input_field.dart';

class EmergencyContactOrganism extends StatelessWidget {
  final TextEditingController phoneController;
  final ValueChanged<String>? onChanged;

  const EmergencyContactOrganism({
    super.key,
    required this.phoneController,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tier-2 Caregiver Emergency Contact",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        AppInputField(
          label: "Caregiver Phone Number",
          hint: "+1 555-019-2834",
          controller: phoneController,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
