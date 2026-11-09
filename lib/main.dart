import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'services/auth_service.dart';
import 'services/session_storage.dart';
import 'theme/app_colors.dart';

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
/// (com os dados mais recentes do servidor); se não houver token, ou se ele
/// não for mais válido, cai na tela de login normalmente.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  final _sessionStorage = SessionStorage();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tentarRestaurarSessao();
  }

  Future<void> _tentarRestaurarSessao() async {
    final token = await _sessionStorage.lerToken();
    if (token == null) {
      _irPara(const LoginScreen());
      return;
    }
    try {
      final sessao = await _authService.me(token);
      _irPara(RootShell(sessao: sessao));
    } catch (_) {
      await _sessionStorage.limpar();
      _irPara(const LoginScreen());
    }
  }

  void _irPara(Widget tela) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.gray100,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
