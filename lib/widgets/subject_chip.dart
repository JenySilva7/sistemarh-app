import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Chip de Assunto — sugestão de assunto para a mensagem ao RH
/// (ex.: "Férias", "Holerite"). Selecionado = fundo roxo, texto branco.
class SubjectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SubjectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: AppTextStyles.smallMedium14(
              color: selected ? AppColors.white : AppColors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
