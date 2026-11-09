import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Card de Resumo do Perfil — 3 colunas (tempo de casa, gestor, banco de
/// horas) separadas por divisores verticais, sobreposto ao cabeçalho.
class ResumoPerfilCard extends StatelessWidget {
  final String tempoDeCasa;
  final String gestor;
  final String bancoDeHoras;

  const ResumoPerfilCard({
    super.key,
    required this.tempoDeCasa,
    required this.gestor,
    required this.bancoDeHoras,
  });

  Widget _stat(String label, String valor, {Color cor = AppColors.foreground}) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.captionRegular12(), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(
            valor,
            style: AppTextStyles.valorResumo(color: cor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -6),
        ],
      ),
      child: Row(
        children: [
          _stat('Tempo de casa', tempoDeCasa),
          Container(width: 1, height: 36, color: AppColors.border),
          _stat('Gestor', gestor),
          Container(width: 1, height: 36, color: AppColors.border),
          _stat('Banco de horas', bancoDeHoras, cor: AppColors.primary),
        ],
      ),
    );
  }
}
