import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/carregamento_controller.dart';
import '../services/holerite_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../widgets/aba_header.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/section_header.dart';

/// Tela "Holerite" — os contracheques do próprio colaborador, do jeito que o
/// RH lançou a folha de pagamento (`GET /api/me/holerites`), do mês mais
/// recente pro mais antigo. Nada aqui é valor de exemplo: sem holerite
/// lançado, a tela diz isso.
///
/// Quem busca é o RootShell, ao abrir a aba ([holerites]); a tela só pede
/// pra buscar de novo no "puxar pra atualizar" e no "Tentar novamente".
class PayslipScreen extends StatelessWidget {
  final String initials;
  final CarregamentoController<List<Holerite>> holerites;

  const PayslipScreen({super.key, required this.initials, required this.holerites});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: holerites.recarregar,
      color: AppColors.primary,
      edgeOffset: MediaQuery.of(context).padding.top,
      child: AnimatedBuilder(
        animation: holerites,
        builder: (context, _) => ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AbaHeader(titulo: 'Holerite', subtitulo: 'Seus contracheques', initials: initials),
            Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildConteudo(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConteudo() {
    final itens = holerites.dados;
    final falha = holerites.falha;

    if (itens == null) {
      if (falha == null) {
        return [
          _CardDestaque(
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Carregando seus holerites…', style: AppTextStyles.smallRegular14())),
              ],
            ),
          ),
        ];
      }
      // 404: a conta não está ligada a um cadastro de colaborador — não é
      // erro de conexão, então não tem "Tentar novamente".
      final semCadastro = falha.statusCode == 404;
      return [
        _CardDestaque(
          child: _Mensagem(
            icone: semCadastro ? LucideIcons.userX : LucideIcons.circleAlert,
            cor: semCadastro ? AppColors.mutedForeground : AppColors.danger,
            titulo: semCadastro ? 'Holerite indisponível' : 'Não foi possível carregar',
            texto: falha.mensagem,
            acao: semCadastro
                ? null
                : TextButton(
                    onPressed: holerites.recarregar,
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    child: const Text('Tentar novamente'),
                  ),
          ),
        ),
      ];
    }

    final aviso = falha == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Não foi possível atualizar: ${falha.mensagem}',
              style: AppTextStyles.captionRegular12(color: AppColors.danger),
            ),
          );

    if (itens.isEmpty) {
      return [
        const _CardDestaque(
          child: _Mensagem(
            icone: LucideIcons.fileText,
            cor: AppColors.primary,
            titulo: 'Nenhum holerite disponível',
            texto: 'Quando o RH lançar sua folha de pagamento, ela aparece aqui.',
          ),
        ),
        const SizedBox(height: 16),
        ?aviso,
      ];
    }

    final ultimo = itens.first;
    return [
      _CardDestaque(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Líquido do último holerite', style: AppTextStyles.captionRegular12()),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatarMoeda(ultimo.salarioLiquido),
                      style: AppTextStyles.relogioSegundos().copyWith(fontSize: 28, color: AppColors.foreground),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Referente a', style: AppTextStyles.captionRegular12()),
                const SizedBox(height: 4),
                Text(formatarCompetencia(ultimo.competencia), style: AppTextStyles.smallMedium14()),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ?aviso,
      const SectionHeader(title: 'Histórico de holerites'),
      const SizedBox(height: 10),
      for (final h in itens) ...[
        MonthlySummaryCard(
          mes: formatarCompetencia(h.competencia),
          valores: [
            ValorMensal('Salário Bruto', formatarMoeda(h.bruto)),
            ValorMensal('Descontos', formatarMoeda(h.descontos), cor: AppColors.red600),
            ValorMensal('Salário Líquido', formatarMoeda(h.salarioLiquido), cor: AppColors.green600),
          ],
          detalhe: _detalhe(h),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 14),
    ];
  }

  /// Bônus incluído no bruto e data de pagamento, quando houver.
  static String? _detalhe(Holerite h) {
    final partes = [
      if (h.bonus > 0) 'Inclui bônus de ${formatarMoeda(h.bonus)}',
      if (h.dataPagamento != null) 'Pago em ${formatarData(h.dataPagamento!)}',
    ];
    return partes.isEmpty ? null : partes.join(' · ');
  }
}

/// Card branco em destaque, sobreposto ao cabeçalho.
class _CardDestaque extends StatelessWidget {
  final Widget child;

  const _CardDestaque({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 32, offset: const Offset(0, 12), spreadRadius: -10),
        ],
      ),
      child: child,
    );
  }
}

/// Ícone, título e texto — estados de vazio, sem cadastro e erro.
class _Mensagem extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String texto;
  final Widget? acao;

  const _Mensagem({required this.icone, required this.cor, required this.titulo, required this.texto, this.acao});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, size: 28, color: cor),
        const SizedBox(height: 10),
        Text(titulo, style: AppTextStyles.bodySemibold16(), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(texto, style: AppTextStyles.smallRegular14(), textAlign: TextAlign.center),
        if (acao != null) ...[const SizedBox(height: 8), acao!],
      ],
    );
  }
}
