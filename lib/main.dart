import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/session_storage.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

void main() {
  runApp(const SistemaRhApp());
}

/// Remove o efeito de "esticar" do overscroll do Android 12+ ao arrastar
/// além do topo/fim da lista — aqui a tela só para de rolar, sem distorcer.
class _SemEsticarScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class SistemaRhApp extends StatelessWidget {
  const SistemaRhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        title: 'Sistema RH',
        debugShowCheckedModeBanner: false,
        scrollBehavior: _SemEsticarScrollBehavior(),
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.gray100,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
          ),
          fontFamily: 'Inter',
          splashFactory: InkRipple.splashFactory,
        ),
        home: const _StartupGate(),
      ),
    );
  }
}

/// Decide, ao abrir o app, se já existe uma sessão salva: se sim, tenta
/// validar o token com o backend (GET /api/auth/me) e abre direto no app
/// (com os dados mais recentes do servidor); se não houver token, ou se o
/// servidor disser que ele não vale mais, cai na tela de login.
///
/// Se o servidor estiver fora do ar, o token é mantido e a tela mostra o
/// erro com a opção de tentar de novo — queda do servidor não desloga ninguém.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  final _sessionStorage = SessionStorage();
  final _authService = AuthService();

  String? _erro;

  @override
  void initState() {
    super.initState();
    _tentarRestaurarSessao();
  }

  Future<void> _tentarRestaurarSessao() async {
    if (_erro != null) setState(() => _erro = null);
    try {
      final token = await _sessionStorage.lerToken();
      if (token == null) {
        _irPara(const LoginScreen());
        return;
      }
      final sessao = await _authService.me(token);
      _irPara(RootShell(sessao: sessao));
    } on ApiException catch (e) {
      // 401 = token expirado/inválido; 403 = acesso desativado pelo RH.
      if (e is SessaoExpiradaException || e.statusCode == 403) {
        await _sessionStorage.limpar();
        _irPara(LoginScreen(mensagemInicial: e.mensagem));
        return;
      }
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = mensagemErroInesperado);
    }
  }

  void _irPara(Widget tela) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    final erro = _erro;
    if (erro == null) {
      return const Scaffold(
        backgroundColor: AppColors.gray100,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: AppColors.danger10, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.cloudOff, size: 30, color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível abrir sua sessão',
                  style: AppTextStyles.tituloSecao(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(erro, style: AppTextStyles.smallRegular14(), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _tentarRestaurarSessao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('Tentar novamente', style: AppTextStyles.botaoGrande()),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _irPara(const LoginScreen()),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  child: const Text('Ir para o login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
