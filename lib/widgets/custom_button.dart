import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, gradient, danger }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final bool glow;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
    this.glow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: glow && variant == ButtonVariant.gradient
            ? [
                BoxShadow(
                  color: AppColors.primaryAccent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: variant == ButtonVariant.gradient
                ? AppColors.primaryGradient
                : null,
            color: _getBackgroundColor(),
            border: variant == ButtonVariant.outline
                ? Border.all(
                    color: AppColors.primaryAccent,
                    width: 2,
                  )
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isLoading ? null : onPressed,
            splashColor: AppColors.primaryAccent.withValues(alpha: 0.2),
            highlightColor: AppColors.primaryAccent.withValues(alpha: 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBackground,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: 20,
                            color: _getTextColor(),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getTextColor(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Color? _getBackgroundColor() {
    if (variant == ButtonVariant.gradient) return null;
    
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.primaryAccent;
      case ButtonVariant.secondary:
        return AppColors.cardBackground;
      case ButtonVariant.outline:
        return Colors.transparent;
      case ButtonVariant.danger:
        return AppColors.error;
      case ButtonVariant.gradient:
        return null; // Gradient is handled separately
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.gradient:
      case ButtonVariant.danger:
        return AppColors.primaryBackground;
      case ButtonVariant.secondary:
      case ButtonVariant.outline:
        return AppColors.primaryAccent;
    }
  }
}
