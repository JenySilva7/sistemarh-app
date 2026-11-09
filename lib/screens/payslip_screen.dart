import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/aba_header.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/section_header.dart';

class _Holerite {
  final String mes;
  final String bruto;
  final String descontos;
  final String liquido;
  const _Holerite(this.mes, this.bruto, this.descontos, this.liquido);
}

const _holerites = [
  _Holerite('Fevereiro 2026', 'R\$ 12.000,00', 'R\$ 2.100,00', 'R\$ 9.900,00'),
  _Holerite('Janeiro 2026', 'R\$ 12.000,00', 'R\$ 2.050,00', 'R\$ 9.950,00'),
  _Holerite('Dezembro 2025', 'R\$ 15.000,00', 'R\$ 2.600,00', 'R\$ 12.400,00'),
];

/// Tela "Holerite" — histórico de contracheques do colaborador.
class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key});

  void _exportar(BuildContext context, String mes) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportando holerite de $mes…'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sidebarBg,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ultimo = _holerites.first;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const AbaHeader(titulo: 'Holerite', subtitulo: 'Seus contracheques'),
        Transform.translate(
          offset: const Offset(0, -60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 32, offset: const Offset(0, 12), spreadRadius: -10),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Último líquido recebido', style: AppTextStyles.captionRegular12()),
                      const SizedBox(height: 4),
                      Text(ultimo.liquido, style: AppTextStyles.relogioSegundos().copyWith(fontSize: 28, color: AppColors.foreground)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Referente a', style: AppTextStyles.captionRegular12()),
                      const SizedBox(height: 4),
                      Text(ultimo.mes, style: AppTextStyles.smallMedium14()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'Histórico de holerites'),
                const SizedBox(height: 10),
                for (final h in _holerites) ...[
                  MonthlySummaryCard(
                    mes: h.mes,
                    valores: [
                      ValorMensal('Salário Bruto', h.bruto),
                      ValorMensal('Descontos', h.descontos, cor: AppColors.red600),
                      ValorMensal('Salário Líquido', h.liquido, cor: AppColors.green600),
                    ],
                    onExportar: () => _exportar(context, h.mes),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
