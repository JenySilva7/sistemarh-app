import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/justificativas_controller.dart';
import '../models/ponto_controller.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/ausencia_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../utils/horario_brasilia.dart';
import '../widgets/app_toast.dart';
import '../widgets/card_acao.dart';
import '../widgets/home_header.dart';
import '../widgets/punch_clock_card.dart';
import '../widgets/registro_linha.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

/// Tela "App · Início (Ponto)" — réplica fiel do design do Penpot:
/// cabeçalho com gradiente, card de relógio interativo, registros do dia,
/// atalho do banco de horas e ausências recentes.
///
/// É só o conteúdo da aba — quem fornece o [Scaffold] e a navegação
/// inferior é o [RootShell].
class HomeScreen extends StatefulWidget {
  final Sessao sessao;
  final PontoController ponto;
  final JustificativasController justificativas;
  final VoidCallback onJustificarAusencia;
  final VoidCallback onBancoDeHoras;
  final VoidCallback onSessaoExpirada;

  const HomeScreen({
    super.key,
    required this.sessao,
    required this.ponto,
    required this.justificativas,
    required this.onJustificarAusencia,
    required this.onBancoDeHoras,
    required this.onSessaoExpirada,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _maxJustificativas = 5;

  bool _registrando = false;

  Future<void> _registrarPonto() async {
    if (_registrando || widget.ponto.proximo == null) return;
    setState(() => _registrando = true);
    try {
      final msg = await widget.ponto.registrarProximo();
      if (msg == null || !mounted) return;
      final concluida = widget.ponto.jornadaConcluida;
      AppToast.show(
        context,
        title: concluida ? 'Jornada concluída' : '${_ultimoTipoTitulo()} registrada',
        description: msg,
      );
    } on SessaoExpiradaException {
      widget.onSessaoExpirada();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, title: 'Não foi possível registrar', description: e.mensagem);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, title: 'Não foi possível registrar', description: mensagemErroInesperado);
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  Future<void> _atualizar() async {
    await Future.wait([widget.ponto.recarregar(), widget.justificativas.recarregar()]);
  }

  String _ultimoTipoTitulo() {
    final tipo = widget.ponto.ultimoRegistrado;
    return tipo?.titulo ?? 'Ponto';
  }

  static String _saudacao(int hora) {
    if (hora >= 5 && hora < 12) return 'Bom dia';
    if (hora >= 12 && hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.ponto,
      builder: (context, _) {
        if (widget.ponto.carregando) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 160),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        // Recalculado a cada rebuild (o controller do ponto notifica todo
        // segundo), então data e saudação viram sozinhas à meia-noite.
        final agora = agoraBrasilia();
        final primeiroNome = widget.sessao.nome.trim().split(' ').first;
        return RefreshIndicator(
          onRefresh: _atualizar,
          color: AppColors.primary,
          edgeOffset: MediaQuery.of(context).padding.top,
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              HomeHeader(
                greeting: '${_saudacao(agora.hour)}, $primeiroNome',
                dateLabel: formatarDataPorExtenso(agora),
                initials: widget.sessao.iniciais,
              ),
              Transform.translate(
                offset: const Offset(0, -60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PunchClockCard(controller: widget.ponto, onRegistrar: _registrarPonto),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.ponto.erroCarregamento != null) ...[
                        Text(
                          'Não foi possível carregar os registros de hoje: ${widget.ponto.erroCarregamento}',
                          style: AppTextStyles.captionRegular12(color: AppColors.danger),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SectionHeader(title: 'Registros de hoje'),
                      const SizedBox(height: 10),
                      _buildRegistros(),
                      const SizedBox(height: 12),
                      Builder(builder: (context) {
                        final negativo = widget.sessao.saldoBancoHorasMinutos < 0;
                        return CardAcao(
                          icon: LucideIcons.clock,
                          iconBg: negativo ? AppColors.danger10 : AppColors.primary10,
                          iconColor: negativo ? AppColors.danger : AppColors.primary,
                          titulo: 'Saldo do banco de horas',
                          descricao: '${widget.sessao.bancoDeHorasFormatado} acumuladas · ver extrato',
                          onTap: widget.onBancoDeHoras,
                        );
                      }),
                      const SizedBox(height: 28),
                      const SectionHeader(title: 'Ausências e justificativas'),
                      const SizedBox(height: 10),
                      CardAcao(
                        icon: LucideIcons.circleAlert,
                        iconBg: AppColors.warning10,
                        iconColor: AppColors.warning,
                        titulo: 'Justificar ausência',
                        descricao: 'Atestado, falta ou esquecimento de ponto',
                        onTap: widget.onJustificarAusencia,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text('Minhas justificativas', style: AppTextStyles.smallMedium14()),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: widget.justificativas,
                        builder: (context, _) => _buildJustificativas(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegistros() {
    final ponto = widget.ponto;

    String hora(DateTime? d) => d == null
        ? '--:--'
        : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    Widget linha(TipoRegistro tipo, {bool showDivider = true}) {
      final registrado = ponto.registroDe(tipo);
      final isEntrada = tipo.isEntrada;
      return RegistroLinha(
        icon: isEntrada ? LucideIcons.logIn : LucideIcons.logOut,
        iconBg: registrado == null
            ? AppColors.neutro10
            : isEntrada
            ? AppColors.success10
            : AppColors.danger10,
        iconColor: registrado == null
            ? AppColors.mutedForeground
            : isEntrada
            ? AppColors.success
            : AppColors.red600,
        tipo: tipo.titulo,
        detalhe: registrado == null ? 'Aguardando registro' : 'Registrado',
        hora: hora(registrado),
        pendente: registrado == null,
        showDivider: showDivider,
      );
    }

    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          linha(TipoRegistro.entrada),
          linha(TipoRegistro.saidaAlmoco),
          linha(TipoRegistro.voltaAlmoco),
          linha(TipoRegistro.saida, showDivider: false),
        ],
      ),
    );
  }

  Widget _buildJustificativas() {
    final controller = widget.justificativas;

    Widget card(Widget child) => Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    Widget aviso({required Widget icone, required String texto, Color? corTexto, Widget? acao}) => card(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            icone,
            const SizedBox(width: 10),
            Expanded(child: Text(texto, style: AppTextStyles.captionRegular12(color: corTexto ?? AppColors.mutedForeground))),
            ?acao,
          ],
        ),
      ),
    );

    if (controller.erro != null) {
      return aviso(
        icone: const Icon(LucideIcons.circleAlert, size: 18, color: AppColors.danger),
        texto: controller.erro!,
        corTexto: AppColors.danger,
        acao: TextButton(
          onPressed: controller.recarregar,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text('Tentar novamente'),
        ),
      );
    }

    if (controller.itens.isEmpty) {
      if (controller.carregando) {
        return aviso(
          icone: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          texto: 'Carregando suas justificativas…',
        );
      }
      return aviso(
        icone: const Icon(LucideIcons.inbox, size: 18, color: AppColors.mutedForeground),
        texto: 'Nenhuma justificativa enviada ainda',
      );
    }

    final recentes = controller.itens.take(_maxJustificativas).toList();
    return card(
      Column(
        children: [
          for (var i = 0; i < recentes.length; i++)
            _JustificativaLinha(justificativa: recentes[i], showDivider: i < recentes.length - 1),
        ],
      ),
    );
  }
}

/// Uma justificativa enviada: tipo, data da ausência e status da análise.
class _JustificativaLinha extends StatelessWidget {
  final Justificativa justificativa;
  final bool showDivider;

  const _JustificativaLinha({required this.justificativa, required this.showDivider});

  static IconData _icone(TipoAusencia tipo) => switch (tipo) {
    TipoAusencia.atestadoMedico => LucideIcons.fileText,
    TipoAusencia.faltaJustificada => LucideIcons.calendar,
    TipoAusencia.esquecimentoDePonto => LucideIcons.clock,
    TipoAusencia.outro => LucideIcons.messageSquare,
  };

  static StatusChip _chip(StatusJustificativa? status) {
    final (fundo, cor) = switch (status) {
      StatusJustificativa.enviada => (AppColors.primary10, AppColors.primary),
      StatusJustificativa.emAnalise => (AppColors.warning10, AppColors.warningText),
      StatusJustificativa.aprovada => (AppColors.success10, AppColors.successText),
      StatusJustificativa.recusada => (AppColors.danger10, AppColors.red600),
      null => (AppColors.neutro10, AppColors.mutedForeground),
    };
    return StatusChip(label: status?.rotulo ?? 'Indefinido', background: fundo, foreground: cor);
  }

  @override
  Widget build(BuildContext context) {
    final j = justificativa;
    final data = j.data == null ? 'Data não informada' : formatarData(j.data!);
    final periodo = j.diaInteiro ? 'Dia inteiro' : 'Parte do dia';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primary10, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Icon(_icone(j.tipo), size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      j.tipo.rotulo,
                      style: AppTextStyles.bodyMedium16(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('$data · $periodo', style: AppTextStyles.captionRegular12()),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _chip(j.status),
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
