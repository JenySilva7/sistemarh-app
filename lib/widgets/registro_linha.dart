import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Linha de Registro — um evento de ponto (entrada, saída almoço, volta,
/// saída) com ícone colorido, tipo, detalhe e horário.
class RegistroLinha extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String tipo;
  final String detalhe;
  final String hora;
  final bool pendente;
  final bool showDivider;

  const RegistroLinha({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.tipo,
    required this.detalhe,
    required this.hora,
    this.pendente = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipo,
                      style: AppTextStyles.bodyMedium16(
                        color: pendente ? AppColors.mutedForeground : AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(detalhe, style: AppTextStyles.captionRegular12()),
                  ],
                ),
              ),
              Text(
                hora,
                style: AppTextStyles.valorResumo(
                  color: pendente ? AppColors.gray300 : AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 68),
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
      ],
    );
  }
}
