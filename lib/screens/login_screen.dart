import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/session_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'root_shell.dart';

/// Tela de login: autentica contra o backend (.NET) e, em caso de sucesso,
/// abre o app de verdade ([RootShell]) com os dados do usuário logado.
class LoginScreen extends StatefulWidget {
  /// Aviso exibido ao abrir a tela (ex.: sessão expirada, acesso desativado).
  final String? mensagemInicial;

  const LoginScreen({super.key, this.mensagemInicial});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _authService = AuthService();

  bool _carregando = false;
  String? _erro;
  bool _mostrarSenha = false;

  @override
  void initState() {
    super.initState();
    _erro = widget.mensagemInicial;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final sessao = await _authService.login(
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );
      await SessionStorage().salvarToken(sessao.token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RootShell(sessao: sessao)),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = mensagemErroInesperado);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          Positioned(
            right: -50,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(color: AppColors.whiteOverlay10, shape: BoxShape.circle),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.whiteOverlay15, width: 4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset('assets/images/logo_humanconnect.jpg', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Entre com sua conta para continuar',
                      style: AppTextStyles.smallRegular14(color: AppColors.whiteOverlay80),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                            spreadRadius: -8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_erro != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger10,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.circleAlert, color: AppColors.danger, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _erro!,
                                      style: AppTextStyles.smallMedium14(color: AppColors.danger),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text('E-mail', style: AppTextStyles.smallMedium14()),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              hint: 'seu.email@empresa.com',
                              icon: LucideIcons.mail,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                              if (!v.contains('@')) return 'E-mail inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text('Senha', style: AppTextStyles.smallMedium14()),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _senhaController,
                            obscureText: !_mostrarSenha,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _entrar(),
                            decoration: _inputDecoration(
                              hint: '••••••••',
                              icon: LucideIcons.lock,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _mostrarSenha ? LucideIcons.eyeOff : LucideIcons.eye,
                                  color: AppColors.mutedForeground,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Informe a senha';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _carregando ? null : _entrar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _carregando
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                                    )
                                  : Text('Entrar', style: AppTextStyles.botaoGrande()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyRegular16(color: AppColors.mutedForeground),
      prefixIcon: Icon(icon, color: AppColors.mutedForeground, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.gray100,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: borda,
      enabledBorder: borda,
      focusedBorder: borda.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: borda.copyWith(borderSide: const BorderSide(color: AppColors.danger)),
      focusedErrorBorder: borda.copyWith(borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
    );
  }
}
