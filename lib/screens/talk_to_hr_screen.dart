import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/carregamento_controller.dart';
import '../services/api_client.dart';
import '../services/mensagem_rh_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../utils/validacao.dart';
import '../widgets/aba_header.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';
import '../widgets/subject_chip.dart';

const _assuntosSugeridos = ['Férias', 'Holerite', 'Benefícios', 'Atualizar cadastro'];

/// Tela "Falar com RH" — o colaborador manda uma mensagem pro RH
/// (`POST /api/mensagens-rh`) e acompanha as que já mandou, com o status e a
/// resposta, em "Minhas mensagens" (`GET /api/mensagens-rh/minhas`). A
/// resposta do RH aparece aqui no app; não vai por e-mail.
///
/// Quem busca a lista é o RootShell, ao abrir a aba ([mensagens]); a tela só
/// pede pra buscar de novo depois de um envio, no "puxar pra atualizar" e no
/// "Tentar novamente".
class TalkToHrScreen extends StatefulWidget {
  final String token;
  final String initials;
  final CarregamentoController<List<MensagemRh>> mensagens;

  const TalkToHrScreen({super.key, required this.token, required this.initials, required this.mensagens});

  @override
  State<TalkToHrScreen> createState() => _TalkToHrScreenState();
}

class _TalkToHrScreenState extends State<TalkToHrScreen> {
  final _assuntoCtrl = TextEditingController();
  final _mensagemCtrl = TextEditingController();
  final _service = MensagemRhService();
  String? _chipSelecionado;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _assuntoCtrl.dispose();
    _mensagemCtrl.dispose();
    super.dispose();
  }

  void _selecionarChip(String assunto) {
    setState(() {
      _chipSelecionado = assunto;
      _assuntoCtrl.text = assunto;
      _erro = null;
    });
  }

  Future<void> _enviar() async {
    // Um toque duplo chega aqui duas vezes antes de o botão ser redesenhado
    // desabilitado: só o primeiro envia.
    if (_enviando) return;
    final erro = validarAssuntoMensagemRh(_assuntoCtrl.text) ?? validarTextoMensagemRh(_mensagemCtrl.text);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await _service.enviar(
        token: widget.token,
        assunto: limparTexto(_assuntoCtrl.text, regraAssuntoMensagemRh),
        // A mensagem é texto longo: as quebras de linha vão como foram digitadas.
        mensagem: limparTexto(_mensagemCtrl.text, regraTextoMensagemRh),
      );
      if (!mounted) return;
      // Só limpa o formulário depois que o servidor confirmou: se der erro, o
      // texto continua lá pra tentar de novo.
      setState(() {
        _assuntoCtrl.clear();
        _mensagemCtrl.clear();
        _chipSelecionado = null;
      });
      widget.mensagens.recarregar();
      AppToast.show(
        context,
        title: 'Mensagem enviada ao RH',
        description: 'A resposta aparece aqui, em "Minhas mensagens"',
      );
    } on SessaoExpiradaException {
      // O ApiClient já está levando de volta pro login.
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = mensagemErroInesperado);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.mensagens.recarregar,
      color: AppColors.primary,
      edgeOffset: MediaQuery.of(context).padding.top,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AbaHeader(titulo: 'Falar com RH', subtitulo: 'Atendimento do RH', initials: widget.initials),
          Transform.translate(
            offset: const Offset(0, -60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormulario(),
                  const SizedBox(height: 28),
                  const SectionHeader(title: 'Minhas mensagens'),
                  const SizedBox(height: 10),
                  AnimatedBuilder(animation: widget.mensagens, builder: (context, _) => _buildMinhasMensagens()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 32, offset: const Offset(0, 12), spreadRadius: -10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primary10, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.messageSquare, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Para', style: AppTextStyles.captionRegular12()),
                    Text('Recursos Humanos', style: AppTextStyles.bodyMedium16()),
                    Text('A resposta aparece aqui no app', style: AppTextStyles.captionRegular12()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Text('Assunto', style: AppTextStyles.smallMedium14()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _assuntoCtrl,
            hint: 'Ex.: Solicitação de férias',
            maxLength: regraAssuntoMensagemRh.maximo,
            onChanged: (_) {
              if (_erro != null) setState(() => _erro = null);
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final assunto in _assuntosSugeridos)
                SubjectChip(
                  label: assunto,
                  selected: _chipSelecionado == assunto,
                  onTap: () => _selecionarChip(assunto),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Mensagem', style: AppTextStyles.smallMedium14()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _mensagemCtrl,
            hint: 'Escreva sua mensagem para o RH…',
            maxLines: 5,
            maxLength: regraTextoMensagemRh.maximo,
            onChanged: (_) {
              if (_erro != null) setState(() => _erro = null);
            },
          ),
          if (_erro != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.danger10, borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.circleAlert, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_erro!, style: AppTextStyles.smallMedium14(color: AppColors.danger))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
                disabledForegroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.send, size: 20, color: AppColors.white),
                        const SizedBox(width: 8),
                        Text('Enviar mensagem', style: AppTextStyles.botaoGrande()),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinhasMensagens() {
    final controller = widget.mensagens;
    final itens = controller.dados;
    final falha = controller.falha;

    if (itens == null) {
      if (falha != null) {
        return _Aviso(
          icone: const Icon(LucideIcons.circleAlert, size: 18, color: AppColors.danger),
          texto: falha.mensagem,
          corTexto: AppColors.danger,
          acao: TextButton(
            onPressed: controller.recarregar,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Tentar novamente'),
          ),
        );
      }
      return const _Aviso(
        icone: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
        texto: 'Carregando suas mensagens…',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (falha != null) ...[
          Text(
            'Não foi possível atualizar: ${falha.mensagem}',
            style: AppTextStyles.captionRegular12(color: AppColors.danger),
          ),
          const SizedBox(height: 8),
        ],
        if (itens.isEmpty)
          const _Aviso(
            icone: Icon(LucideIcons.inbox, size: 18, color: AppColors.mutedForeground),
            texto: 'Você ainda não enviou mensagens ao RH',
          ),
        for (final m in itens) ...[
          _MensagemCard(mensagem: m),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}

/// Card branco com ícone e texto, usado pros estados de carregando, vazio e
/// erro da lista.
class _Aviso extends StatelessWidget {
  final Widget icone;
  final String texto;
  final Color? corTexto;
  final Widget? acao;

  const _Aviso({required this.icone, required this.texto, this.corTexto, this.acao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          icone,
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: AppTextStyles.captionRegular12(color: corTexto ?? AppColors.mutedForeground)),
          ),
          ?acao,
        ],
      ),
    );
  }
}

/// Uma mensagem enviada: assunto, quando foi enviada, status, o texto e,
/// se o RH já respondeu, a resposta.
class _MensagemCard extends StatelessWidget {
  final MensagemRh mensagem;

  const _MensagemCard({required this.mensagem});

  static String _quando(DateTime d) => '${formatarData(d)} às ${formatarHora(d)}';

  static StatusChip _chip(StatusMensagemRh? status) {
    final (fundo, cor) = switch (status) {
      StatusMensagemRh.aberta => (AppColors.warning10, AppColors.warningText),
      StatusMensagemRh.respondida => (AppColors.success10, AppColors.successText),
      null => (AppColors.neutro10, AppColors.mutedForeground),
    };
    return StatusChip(label: status?.rotulo ?? 'Indefinido', background: fundo, foreground: cor);
  }

  @override
  Widget build(BuildContext context) {
    final m = mensagem;
    final enviadaEm = m.criadoEm;
    final respondidaEm = m.respondidaEm;
    final resposta = m.resposta;
    final quemRespondeu = [
      if (m.responsavelNome != null) m.responsavelNome!,
      if (respondidaEm != null) _quando(respondidaEm),
    ].join(' · ');

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(m.assunto, style: AppTextStyles.bodyMedium16())),
              const SizedBox(width: 8),
              _chip(m.status),
            ],
          ),
          if (enviadaEm != null) ...[
            const SizedBox(height: 2),
            Text('Enviada em ${_quando(enviadaEm)}', style: AppTextStyles.captionRegular12()),
          ],
          const SizedBox(height: 10),
          Text(
            m.mensagem,
            style: AppTextStyles.smallRegular14(color: AppColors.foreground),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (resposta != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary5, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resposta do RH', style: AppTextStyles.captionMedium12(color: AppColors.primary)),
                  if (quemRespondeu.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(quemRespondeu, style: AppTextStyles.captionRegular12()),
                  ],
                  const SizedBox(height: 6),
                  Text(resposta, style: AppTextStyles.smallRegular14(color: AppColors.foreground)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
