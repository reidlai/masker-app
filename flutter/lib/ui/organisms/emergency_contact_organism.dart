import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_input_field.dart';

class EmergencyContactOrganism extends StatelessWidget {
  final TextEditingController? nameController;
  final TextEditingController phoneController;
  final ValueChanged<String>? onChanged;

  // Optional per-field inline error text (Story 1.11). Null → no error shown.
  final String? nameError;
  final String? phoneError;

  const EmergencyContactOrganism({
    super.key,
    this.nameController,
    required this.phoneController,
    this.onChanged,
    this.nameError,
    this.phoneError,
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
        if (nameController != null) ...[
          AppInputField(
            label: "Caregiver Name",
            hint: "Maria Chen",
            controller: nameController!,
            onChanged: onChanged,
            errorText: nameError,
          ),
          const SizedBox(height: 12),
        ],
        AppInputField(
          label: "Caregiver Phone Number",
          hint: "(555) 019-2244",
          controller: phoneController,
          onChanged: onChanged,
          errorText: phoneError,
        ),
      ],
    );
  }
}
