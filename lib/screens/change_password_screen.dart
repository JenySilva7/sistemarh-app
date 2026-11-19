import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/validacao.dart';
import '../widgets/app_text_field.dart';

/// Tela "Alterar senha" — empurrada a partir de Meus Dados. Troca a senha
/// pelo `PUT /api/auth/senha` e devolve, via Navigator.pop, o token NOVO que
/// a API manda (o antigo deixa de valer na hora, inclusive neste aparelho).
/// Quem abriu a tela é que salva o token e segue com ele.
class ChangePasswordScreen extends StatefulWidget {
  final String token;

  const ChangePasswordScreen({super.key, required this.token});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _atualCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confirmacaoCtrl = TextEditingController();
  final _authService = AuthService();
  bool _mostrarSenhas = false;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    _confirmacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    // Um toque duplo chega aqui duas vezes antes de o botão ser redesenhado
    // desabilitado: só o primeiro envia.
    if (_enviando) return;
    // As senhas vão como foram digitadas (sem aparar): espaço na ponta é
    // erro, não algo a corrigir em silêncio.
    final erro = validarTrocaDeSenha(
      senhaAtual: _atualCtrl.text,
      novaSenha: _novaCtrl.text,
      confirmacao: _confirmacaoCtrl.text,
    );
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
      final novoToken = await _authService.alterarSenha(
        token: widget.token,
        senhaAtual: _atualCtrl.text,
        novaSenha: _novaCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(novoToken);
      return;
    } on SessaoExpiradaException {
      // O ApiClient já está levando de volta pro login.
    } on ApiException catch (e) {
      // 400 ("Senha atual incorreta.", regras da senha) e 429 (tentativas
      // demais) vêm com a mensagem pronta da API.
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = mensagemErroInesperado);
    }
    if (mounted) setState(() => _enviando = false);
  }

  void _limparErro(String _) {
    if (_erro != null) setState(() => _erro = null);
  }

  @override
  Widget build(BuildContext context) {
    final olho = IconButton(
      tooltip: _mostrarSenhas ? 'Esconder senhas' : 'Mostrar senhas',
      icon: Icon(_mostrarSenhas ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: AppColors.mutedForeground),
      onPressed: () => setState(() => _mostrarSenhas = !_mostrarSenhas),
    );

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
                      'Depois de trocar, você continua conectado neste aparelho. Nos outros, '
                      'vai precisar entrar de novo com a senha nova.',
                      style: AppTextStyles.smallRegular14(),
                    ),
                    const SizedBox(height: 22),
                    _campo(
                      'Senha atual',
                      AppTextField(
                        controller: _atualCtrl,
                        hint: 'Sua senha de hoje',
                        obscureText: !_mostrarSenhas,
                        suffixIcon: olho,
                        onChanged: _limparErro,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _campo(
                      'Nova senha',
                      AppTextField(
                        controller: _novaCtrl,
                        hint: 'De $senhaMinimo a $senhaMaximo caracteres',
                        obscureText: !_mostrarSenhas,
                        suffixIcon: olho,
                        onChanged: _limparErro,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _campo(
                      'Confirme a nova senha',
                      AppTextField(
                        controller: _confirmacaoCtrl,
                        hint: 'Digite a nova senha de novo',
                        obscureText: !_mostrarSenhas,
                        suffixIcon: olho,
                        onChanged: _limparErro,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sem espaço no começo ou no fim, sem emoji e sem caracteres invisíveis.',
                      style: AppTextStyles.captionRegular12(),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.danger10, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.circleAlert, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_erro!, style: AppTextStyles.smallMedium14(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      ),
                    ],
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
            boxShadow: [
              BoxShadow(color: AppColors.foreground.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -4)),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviando ? null : _salvar,
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
                        const Icon(LucideIcons.keyRound, size: 20, color: AppColors.white),
                        const SizedBox(width: 8),
                        Text('Salvar nova senha', style: AppTextStyles.botaoGrande()),
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
                  child: Text('Alterar senha', style: AppTextStyles.bodySemibold16(), textAlign: TextAlign.center),
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

  Widget _campo(String titulo, Widget conteudo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: AppTextStyles.smallMedium14()),
        const SizedBox(height: 8),
        conteudo,
      ],
    );
  }
}
