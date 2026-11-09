import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ValorMensal {
  final String label;
  final String valor;
  final Color cor;
  const ValorMensal(this.label, this.valor, {this.cor = AppColors.foreground});
}

/// Card de Histórico — um mês (holerite ou vale alimentação) com até 3
/// valores lado a lado e um botão "Exportar PDF".
class MonthlySummaryCard extends StatelessWidget {
  final String mes;
  final List<ValorMensal> valores;
  final VoidCallback? onExportar;

  const MonthlySummaryCard({
    super.key,
    required this.mes,
    required this.valores,
    this.onExportar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.foreground.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(mes, style: AppTextStyles.tituloSecao()),
              if (onExportar != null)
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onExportar,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(LucideIcons.download, size: 16, color: AppColors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < valores.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(valores[i].label, style: AppTextStyles.captionRegular12()),
                      const SizedBox(height: 4),
                      Text(
                        valores[i].valor,
                        style: AppTextStyles.smallMedium14(color: valores[i].cor),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
