import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, danger, emergency }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    double height = 52.0;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.accentGreen;
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.surface;
        fg = AppColors.textPrimary;
        break;
      case AppButtonVariant.danger:
        bg = AppColors.dangerRed;
        fg = Colors.white;
        break;
      case AppButtonVariant.emergency:
        bg = Colors.white;
        fg = const Color(0xFF991B1B);
        height = 64.0;
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: variant == AppButtonVariant.emergency ? 12 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: variant == AppButtonVariant.secondary
                ? const BorderSide(color: AppColors.cardBorder, width: 1)
                : BorderSide.none,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: variant == AppButtonVariant.emergency ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: variant == AppButtonVariant.emergency ? 1.0 : 0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
