import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/ponto_controller.dart';
import '../services/auth_service.dart';
import '../services/ponto_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_toast.dart';
import '../widgets/card_acao.dart';
import '../widgets/home_header.dart';
import '../widgets/punch_clock_card.dart';
import '../widgets/registro_linha.dart';
import '../widgets/section_header.dart';

/// Tela "App · Início (Ponto)" — réplica fiel do design do Penpot:
/// cabeçalho com gradiente, card de relógio interativo, registros do dia,
/// atalho do banco de horas e ausências recentes.
///
/// É só o conteúdo da aba — quem fornece o [Scaffold] e a navegação
/// inferior é o [RootShell].
class HomeScreen extends StatefulWidget {
  final Sessao sessao;
  final PontoController ponto;
  final VoidCallback onJustificarAusencia;
  final VoidCallback onBancoDeHoras;

  const HomeScreen({
    super.key,
    required this.sessao,
    required this.ponto,
    required this.onJustificarAusencia,
    required this.onBancoDeHoras,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    } on PontoApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, title: 'Não foi possível registrar', description: e.mensagem);
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  String _ultimoTipoTitulo() {
    final tipo = widget.ponto.ultimoRegistrado;
    return tipo?.titulo ?? 'Ponto';
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
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            HomeHeader(
              greeting: 'Bom dia, ${widget.sessao.nome.split(' ').first}',
              dateLabel: 'Sexta-feira, 23 de outubro',
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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
}
