import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool gradient;
  final bool borderGlow;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.gradient = false,
    this.borderGlow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: borderGlow 
                ? AppColors.primaryAccent.withValues(alpha: 0.15)
                : AppColors.shadowDark.withValues(alpha: 0.3),
            blurRadius: borderGlow ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: gradient
                ? LinearGradient(
                    colors: [
                      AppColors.cardBackground,
                      AppColors.cardBackground.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: gradient ? null : AppColors.cardBackground,
            border: Border.all(
              color: borderGlow
                  ? AppColors.primaryAccent.withValues(alpha: 0.3)
                  : AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            splashColor: AppColors.primaryAccent.withValues(alpha: 0.1),
            highlightColor: AppColors.primaryAccent.withValues(alpha: 0.05),
            child: Container(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
