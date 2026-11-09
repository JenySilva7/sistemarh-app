import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class InfoField {
  final IconData icon;
  final String label;
  final String valor;
  const InfoField(this.icon, this.label, this.valor);
}

/// Linha de Dado — ícone + rótulo/valor, usada dentro de um [InfoGroup].
class _InfoRow extends StatelessWidget {
  final InfoField field;
  final bool showDivider;

  const _InfoRow({required this.field, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.primary10, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(field.icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field.label, style: AppTextStyles.captionRegular12()),
                    const SizedBox(height: 2),
                    Text(field.valor, style: AppTextStyles.bodyMedium16()),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 64),
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
      ],
    );
  }
}

/// Grupo de dados com um rótulo em versalete acima (ex.: "DADOS PESSOAIS")
/// e um card branco contendo as linhas.
class InfoGroup extends StatelessWidget {
  final String titulo;
  final List<InfoField> campos;

  const InfoGroup({super.key, required this.titulo, required this.campos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            titulo.toUpperCase(),
            style: AppTextStyles.captionRegular12().copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppColors.foreground.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < campos.length; i++)
                _InfoRow(field: campos[i], showDivider: i < campos.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}
