import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onVoiceInputPressed;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onVoiceInputPressed,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHint = hintText ?? hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.headlineSmall.copyWith(
              fontSize: 15.0,
              color: AppColors.soil800,
            ),
          ),
          const SizedBox(height: 6.0),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          enabled: enabled,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: effectiveHint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: onVoiceInputPressed != null
                ? IconButton(
                    icon: const Icon(
                      Icons.mic,
                      color: AppColors.primary500,
                      size: 24.0,
                    ),
                    onPressed: onVoiceInputPressed,
                    tooltip: 'बोलकर लिखें (Voice Input)',
                  )
                : suffixIcon,
            constraints: const BoxConstraints(
              minHeight: AppTheme.minTouchTargetLarge,
            ),
          ),
        ),
      ],
    );
  }
}
