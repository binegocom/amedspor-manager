import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonType { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? color;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    this.onTap,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color effectiveTextColor = textColor ?? AppColors.white;
    BorderSide border = BorderSide.none;

    switch (type) {
      case AppButtonType.primary:
        bgColor = color ?? AppColors.primaryGreen;
        break;
      case AppButtonType.secondary:
        bgColor = color ?? AppColors.softGreen;
        break;
      case AppButtonType.outline:
        bgColor = Colors.transparent;
        border = BorderSide(color: color ?? Colors.white24);
        break;
      case AppButtonType.danger:
        bgColor = color ?? AppColors.primaryRed;
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double? effectiveWidth = width ?? (constraints.hasBoundedWidth ? double.infinity : null);
        return SizedBox(
          width: effectiveWidth,
          height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: effectiveTextColor,
          elevation: 0,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        style: AppTextStyles.button.copyWith(color: effectiveTextColor),
                      ),
                    ),
                  ),
                ],
              ),
      ),
        );
      },
    );
  }
}
