import 'package:flutter/material.dart';
import '../models/justificativas_controller.dart';
import '../models/ponto_controller.dart';
import '../services/api_client.dart';
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

/// Casca do app: dono do estado compartilhado (ponto e justificativas) e da
/// navegação inferior entre as 4 abas. Cada aba fica viva num
/// [IndexedStack], então trocar de aba não perde o que foi digitado.
class RootShell extends StatefulWidget {
  final Sessao sessao;

  const RootShell({super.key, required this.sessao});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late final PontoController _ponto;
  late final JustificativasController _justificativas;
  int _index = 0;
  bool _encerrandoSessao = false;

  @override
  void initState() {
    super.initState();
    _ponto = PontoController(token: widget.sessao.token, onSessaoExpirada: _sessaoExpirada);
    _justificativas = JustificativasController(token: widget.sessao.token, onSessaoExpirada: _sessaoExpirada);
  }

  @override
  void dispose() {
    _ponto.dispose();
    _justificativas.dispose();
    super.dispose();
  }

  Future<void> _abrirJustificarAusencia() async {
    final enviado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JustifyAbsenceScreen(token: widget.sessao.token, onSessaoExpirada: _sessaoExpirada),
      ),
    );
    if (enviado != true || !mounted) return;
    _justificativas.recarregar();
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

  Future<void> _sair() => _encerrarSessao();

  /// O token foi recusado (401) por alguma das chamadas: volta pro login
  /// avisando o motivo.
  void _sessaoExpirada() => _encerrarSessao(mensagem: mensagemSessaoExpirada);

  Future<void> _encerrarSessao({String? mensagem}) async {
    // Várias chamadas podem dar 401 ao mesmo tempo (ponto + justificativas).
    if (_encerrandoSessao) return;
    _encerrandoSessao = true;
    await SessionStorage().limpar();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(mensagemInicial: mensagem)),
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
        justificativas: _justificativas,
        onJustificarAusencia: _abrirJustificarAusencia,
        onBancoDeHoras: () => _avisarEmBreve('Extrato do banco de horas'),
        onSessaoExpirada: _sessaoExpirada,
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
