import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/aba_header.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';
import '../widgets/subject_chip.dart';

const _assuntosSugeridos = ['Férias', 'Holerite', 'Benefícios', 'Atualizar cadastro'];

/// Tela "Falar com RH" — formulário no formato de e-mail para o colaborador
/// enviar uma mensagem ao RH. A resposta chega por e-mail, não pelo app.
class TalkToHrScreen extends StatefulWidget {
  const TalkToHrScreen({super.key});

  @override
  State<TalkToHrScreen> createState() => _TalkToHrScreenState();
}

class _TalkToHrScreenState extends State<TalkToHrScreen> {
  final _assuntoCtrl = TextEditingController();
  final _mensagemCtrl = TextEditingController();
  String? _chipSelecionado;

  @override
  void initState() {
    super.initState();
    _mensagemCtrl.addListener(() => setState(() {}));
  }

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
    });
  }

  void _enviar() {
    final assunto = _assuntoCtrl.text.trim();
    final mensagem = _mensagemCtrl.text.trim();
    if (assunto.isEmpty || mensagem.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            assunto.isEmpty ? 'Preencha o assunto da mensagem.' : 'Escreva sua mensagem antes de enviar.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.sidebarBg,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _assuntoCtrl.clear();
      _mensagemCtrl.clear();
      _chipSelecionado = null;
    });
    FocusScope.of(context).unfocus();
    AppToast.show(
      context,
      title: 'Mensagem enviada ao RH',
      description: 'A resposta chegará no seu e-mail cadastrado',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const AbaHeader(titulo: 'Falar com RH', subtitulo: 'Atendimento do RH'),
        Transform.translate(
          offset: const Offset(0, -60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _buildFormulario(),
          ),
        ),
      ],
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
                child: const Icon(LucideIcons.mail, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Para', style: AppTextStyles.captionRegular12()),
                    Text('Recursos Humanos', style: AppTextStyles.bodyMedium16()),
                    Text('rh@empresa.com', style: AppTextStyles.captionRegular12()),
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
          AppTextField(controller: _assuntoCtrl, hint: 'Ex.: Solicitação de férias'),
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
          AppTextField(controller: _mensagemCtrl, hint: 'Escreva sua mensagem para o RH…', maxLines: 5, maxLength: 1000),
          const SizedBox(height: 18),
          _buildAnexo(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
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

  Widget _buildAnexo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray300, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primary10, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.paperclip, size: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text('Anexar arquivo', style: AppTextStyles.smallMedium14(color: AppColors.primary)),
          const SizedBox(height: 2),
          Text('PDF, JPG ou PNG · até 5 MB', style: AppTextStyles.captionRegular12()),
        ],
      ),
    );
  }
}
