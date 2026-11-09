import 'package:flutter/material.dart';
import '../models/ponto_controller.dart';
import '../services/auth_service.dart';
import '../services/session_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_toast.dart';
import 'home_screen.dart';
import 'justify_absence_screen.dart';
import 'login_screen.dart';
import 'my_data_screen.dart';
import 'payslip_screen.dart';
import 'talk_to_hr_screen.dart';

/// Casca do app: dono do estado compartilhado (ponto) e da navegação
/// inferior entre as 4 abas. Cada aba fica viva num [IndexedStack], então
/// trocar de aba não perde o que foi digitado.
class RootShell extends StatefulWidget {
  final Sessao sessao;

  const RootShell({super.key, required this.sessao});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late final PontoController _ponto;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _ponto = PontoController(token: widget.sessao.token);
  }

  @override
  void dispose() {
    _ponto.dispose();
    super.dispose();
  }

  Future<void> _abrirJustificarAusencia() async {
    final enviado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => JustifyAbsenceScreen(token: widget.sessao.token)),
    );
    if (enviado != true || !mounted) return;
    AppToast.show(
      context,
      title: 'Justificativa enviada',
      description: 'Você será avisado quando o RH responder',
    );
  }

  void _avisarEmBreve(String recurso) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$recurso — em breve'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sidebarBg,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _sair() async {
    await SessionStorage().limpar();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessao = widget.sessao;
    final abas = [
      HomeScreen(
        sessao: sessao,
        ponto: _ponto,
        onJustificarAusencia: _abrirJustificarAusencia,
        onBancoDeHoras: () => _avisarEmBreve('Extrato do banco de horas'),
      ),
      const TalkToHrScreen(),
      const PayslipScreen(),
      MyDataScreen(sessao: sessao, onSair: _sair),
    ];

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: IndexedStack(index: _index, children: abas),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, onTap: (i) => setState(() => _index = i)),
    );
  }
}
