import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ShadButtonVariant {
  primary,
  outline,
  secondary,
  danger,
  emergency,
}

class ShadButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ShadButtonVariant variant;
  final Widget? icon;
  final bool fullWidth;
  final double? height;

  const ShadButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ShadButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;
    double defaultHeight = 48.0;

    switch (variant) {
      case ShadButtonVariant.primary:
        bgColor = AppColors.accentGreen;
        textColor = AppColors.background;
        break;
      case ShadButtonVariant.outline:
      case ShadButtonVariant.secondary:
        bgColor = Colors.transparent;
        textColor = AppColors.textPrimary;
        borderSide = const BorderSide(color: AppColors.cardBorder, width: 1.0);
        break;
      case ShadButtonVariant.danger:
        bgColor = AppColors.dangerRed;
        textColor = Colors.white;
        break;
      case ShadButtonVariant.emergency:
        bgColor = Colors.white;
        textColor = const Color(0xFFDC2626);
        defaultHeight = 64.0;
        break;
    }

    final double effectiveHeight = height ?? defaultHeight;

    Widget childWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: variant == ShadButtonVariant.emergency ? 16 : 14,
            fontWeight: FontWeight.bold,
            letterSpacing: variant == ShadButtonVariant.emergency ? 0.04 : 0,
          ),
        ),
      ],
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: textColor,
      elevation: 0,
      minimumSize: Size(fullWidth ? double.infinity : 0, effectiveHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: borderSide,
      ),
    );

    return SizedBox(
      height: effectiveHeight,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: onPressed,
        child: childWidget,
      ),
    );
  }
}
