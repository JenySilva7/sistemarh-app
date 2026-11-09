import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Card de Ação — atalho com ícone, título, descrição e seta, usado para
/// "Saldo do banco de horas" e "Justificar ausência".
class CardAcao extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String titulo;
  final String descricao;
  final VoidCallback? onTap;

  const CardAcao({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.titulo,
    required this.descricao,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.foreground.withValues(alpha: 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: AppTextStyles.valorResumo()),
                    const SizedBox(height: 2),
                    Text(descricao, style: AppTextStyles.captionRegular12()),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
