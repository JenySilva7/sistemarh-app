import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Chip de Status — bolinha + texto, com fundo suave e texto na cor forte
/// correspondente (Registrado = verde, Em intervalo = âmbar).
class StatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const StatusChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  factory StatusChip.registrado(String label) => StatusChip(
    label: label,
    background: AppColors.success10,
    foreground: AppColors.successText,
  );

  factory StatusChip.emIntervalo(String label) => StatusChip(
    label: label,
    background: AppColors.warning10,
    foreground: AppColors.warningText,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.captionMedium12(color: foreground)),
        ],
      ),
    );
  }
}
