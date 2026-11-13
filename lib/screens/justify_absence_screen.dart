import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_client.dart';
import '../services/ausencia_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../widgets/app_text_field.dart';
import '../widgets/option_card.dart';

class _TipoJustificativa {
  final IconData icon;
  final String label;
  const _TipoJustificativa(this.icon, this.label);
}

const _tipos = [
  _TipoJustificativa(LucideIcons.fileText, 'Atestado médico'),
  _TipoJustificativa(LucideIcons.calendar, 'Falta justificada'),
  _TipoJustificativa(LucideIcons.clock, 'Esquecimento de ponto'),
  _TipoJustificativa(LucideIcons.messageSquare, 'Outro motivo'),
];

/// Tela "Justificar ausência" — formulário completo, empurrado a partir do
/// Início. Retorna `true` via Navigator.pop quando enviado com sucesso.
class JustifyAbsenceScreen extends StatefulWidget {
  final String token;

  /// Chamado se o servidor recusar o token ao enviar.
  final VoidCallback onSessaoExpirada;

  const JustifyAbsenceScreen({super.key, required this.token, required this.onSessaoExpirada});

  @override
  State<JustifyAbsenceScreen> createState() => _JustifyAbsenceScreenState();
}

class _JustifyAbsenceScreenState extends State<JustifyAbsenceScreen> {
  int _tipo = 0;
  DateTime? _data;
  bool _diaInteiro = true;
  bool _comprovanteAnexado = false;
  bool _enviando = false;
  final _descricaoCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  final _ausenciaService = AusenciaService();

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _dataCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data ?? agora,
      firstDate: DateTime(agora.year - 1),
      lastDate: DateTime(agora.year + 1),
      helpText: 'Data da ausência',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (escolhida != null) {
      setState(() {
        _data = escolhida;
        _dataCtrl.text = formatarData(escolhida);
      });
    }
  }

  void _avisar(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sidebarBg,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _enviar() async {
    if (_data == null) {
      _avisar('Selecione a data da ausência.');
      return;
    }
    if (_descricaoCtrl.text.trim().isEmpty) {
      _avisar('Descreva o motivo da ausência.');
      return;
    }

    setState(() => _enviando = true);
    try {
      await _ausenciaService.criar(
        token: widget.token,
        tipo: _tipo,
        data: _data!,
        diaInteiro: _diaInteiro,
        descricao: _descricaoCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on SessaoExpiradaException {
      widget.onSessaoExpirada();
    } on ApiException catch (e) {
      if (mounted) _avisar(e.mensagem);
    } catch (_) {
      if (mounted) _avisar(mensagemErroInesperado);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildBarraInterna(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Envie o motivo da sua ausência para análise do RH. Você será avisado quando houver uma resposta.',
                      style: AppTextStyles.smallRegular14(),
                    ),
                    const SizedBox(height: 22),
                    _campo('Tipo de justificativa', _buildTipos()),
                    const SizedBox(height: 22),
                    _campo(
                      'Data da ausência',
                      AppTextField(
                        controller: _dataCtrl,
                        hint: 'Selecione a data',
                        readOnly: true,
                        onTap: _escolherData,
                        prefixIcon: const Icon(LucideIcons.calendar, size: 18, color: AppColors.mutedForeground),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _campo('Período', _buildPeriodo()),
                    const SizedBox(height: 22),
                    _campo(
                      'Descrição',
                      AppTextField(controller: _descricaoCtrl, hint: 'Descreva o motivo da ausência…', maxLines: 4),
                    ),
                    const SizedBox(height: 22),
                    _campo('Comprovante', _buildAnexo(), opcional: true),
                    const SizedBox(height: 20),
                    _buildAviso(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [BoxShadow(color: AppColors.foreground.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
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
                        Text('Enviar justificativa', style: AppTextStyles.botaoGrande()),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarraInterna() {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Material(
                  color: AppColors.gray100,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(LucideIcons.chevronLeft, size: 24, color: AppColors.foreground),
                    ),
                  ),
                ),
                Expanded(
                  child: Text('Justificar ausência', style: AppTextStyles.bodySemibold16(), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  Widget _campo(String titulo, Widget conteudo, {bool opcional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(titulo, style: AppTextStyles.smallMedium14()),
            if (opcional) ...[
              const SizedBox(width: 6),
              Text('(opcional)', style: AppTextStyles.captionRegular12()),
            ],
          ],
        ),
        const SizedBox(height: 8),
        conteudo,
      ],
    );
  }

  Widget _buildTipos() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tipos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // Altura fixa em vez de childAspectRatio: a proporção largura/altura
        // varia demais entre um celular (~390px) e uma janela de desktop
        // (bem mais larga), deixando os cards espichados verticalmente.
        mainAxisExtent: 104,
      ),
      itemBuilder: (context, i) => OptionCard(
        icon: _tipos[i].icon,
        label: _tipos[i].label,
        selected: _tipo == i,
        onTap: () => setState(() => _tipo = i),
      ),
    );
  }

  Widget _buildPeriodo() {
    Widget opcao(String label, bool selecionado, VoidCallback onTap) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: selecionado ? AppColors.primary5 : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selecionado ? AppColors.primary : AppColors.border, width: selecionado ? 1.5 : 1),
              ),
              child: Text(
                label,
                style: AppTextStyles.bodyMedium16(color: selecionado ? AppColors.primary : AppColors.foreground),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        opcao('Dia inteiro', _diaInteiro, () => setState(() => _diaInteiro = true)),
        const SizedBox(width: 12),
        opcao('Parte do dia', !_diaInteiro, () => setState(() => _diaInteiro = false)),
      ],
    );
  }

  Widget _buildAnexo() {
    if (_comprovanteAnexado) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary5,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary20),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.fileText, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text('comprovante.jpg', style: AppTextStyles.smallMedium14())),
            InkWell(
              onTap: () => setState(() => _comprovanteAnexado = false),
              child: const Icon(LucideIcons.x, size: 18, color: AppColors.mutedForeground),
            ),
          ],
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _comprovanteAnexado = true),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gray300),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primary10, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.paperclip, size: 20, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text('Anexar atestado ou comprovante', style: AppTextStyles.smallMedium14(color: AppColors.primary)),
              const SizedBox(height: 2),
              Text('PDF, JPG ou PNG · até 5 MB', style: AppTextStyles.captionRegular12()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAviso() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.primary5, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Para atestados, envie uma foto legível do documento completo, com data e assinatura do profissional.',
              style: AppTextStyles.captionRegular12(color: AppColors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}
