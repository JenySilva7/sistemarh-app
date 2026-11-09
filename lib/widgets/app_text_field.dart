import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Campo de texto padrão do app — fundo #F8F9FA, borda 1px, radius 12,
/// anel de foco na cor primária. Serve tanto para campo de uma linha quanto
/// para textarea (via [maxLines]).
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.prefixIcon,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    OutlineInputBorder border(Color color, double width) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: color, width: width));

    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: AppTextStyles.bodyRegular16(),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyRegular16(color: AppColors.foreground.withValues(alpha: 0.5)),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: AppColors.background,
        counterStyle: AppTextStyles.captionRegular12(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: border(AppColors.border, 1),
        enabledBorder: border(AppColors.border, 1),
        focusedBorder: border(AppColors.primary, 2),
      ),
    );
  }
}
