import 'package:flutter/material.dart';
import '../models/carregamento_controller.dart';
import '../models/justificativas_controller.dart';
import '../models/ponto_controller.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/cadastro_service.dart';
import '../services/holerite_service.dart';
import '../services/mensagem_rh_service.dart';
import '../services/session_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_toast.dart';
import 'change_password_screen.dart';
import 'home_screen.dart';
import 'justify_absence_screen.dart';
import 'login_screen.dart';
import 'my_data_screen.dart';
import 'payslip_screen.dart';
import 'talk_to_hr_screen.dart';

/// Casca do app: dono do estado compartilhado (ponto, justificativas,
/// mensagens ao RH, holerites e cadastro) e da navegação inferior entre as 4
/// abas. Cada aba fica viva num [IndexedStack], então trocar de aba não perde
/// o que foi digitado.
///
/// Também é quem encerra a sessão: no "Sair" e quando qualquer chamada à API
/// responde 401 (ver [ApiClient.aoEncerrarSessao]).
class RootShell extends StatefulWidget {
  final Sessao sessao;

  /// Aba que aparece ao abrir (0 = Início).
  final int abaInicial;

  /// Toast mostrado assim que a casca abre (ex.: "Senha alterada").
  final ({String titulo, String descricao})? avisoAoAbrir;

  const RootShell({super.key, required this.sessao, this.abaInicial = 0, this.avisoAoAbrir});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const _abaMensagens = 1;
  static const _abaHolerite = 2;
  static const _abaMeusDados = 3;

  late final PontoController _ponto;
  late final JustificativasController _justificativas;
  late final CarregamentoController<List<MensagemRh>> _mensagens;
  late final CarregamentoController<List<Holerite>> _holerites;
  late final CarregamentoController<CadastroColaborador> _cadastro;
  final _authService = AuthService();
  int _index = 0;
  bool _encerrandoSessao = false;

  /// true depois que a senha foi trocada: o token desta casca já não vale, e
  /// um 401 que chegue com ele não pode derrubar a sessão nova.
  bool _trocandoToken = false;

  @override
  void initState() {
    super.initState();
    ApiClient.aoEncerrarSessao = _sessaoExpirada;
    final token = widget.sessao.token;
    _ponto = PontoController(token: token);
    _justificativas = JustificativasController(token: token);
    // Estas três só buscam quando a aba é aberta (ver _selecionarAba).
    _mensagens = CarregamentoController(() => MensagemRhService().listarMinhas(token));
    _holerites = CarregamentoController(() => HoleriteService().listarMeus(token));
    _cadastro = CarregamentoController(() => CadastroService().obterMeu(token));

    _index = widget.abaInicial;
    _atualizarAba(_index);
    final aviso = widget.avisoAoAbrir;
    if (aviso != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppToast.show(context, title: aviso.titulo, description: aviso.descricao);
      });
    }
  }

  @override
  void dispose() {
    if (ApiClient.aoEncerrarSessao == _sessaoExpirada) ApiClient.aoEncerrarSessao = null;
    _ponto.dispose();
    _justificativas.dispose();
    _mensagens.dispose();
    _holerites.dispose();
    _cadastro.dispose();
    super.dispose();
  }

  /// Troca de aba e atualiza os dados dela a cada abertura — assim uma
  /// resposta do RH ou um holerite novo aparecem sem precisar puxar a tela.
  void _selecionarAba(int i) {
    setState(() => _index = i);
    _atualizarAba(i);
  }

  void _atualizarAba(int i) {
    final controller = switch (i) {
      _abaMensagens => _mensagens,
      _abaHolerite => _holerites,
      _abaMeusDados => _cadastro,
      _ => null,
    };
    if (controller != null && !controller.carregando) controller.recarregar();
  }

  Future<void> _abrirJustificarAusencia() async {
    final enviado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => JustifyAbsenceScreen(token: widget.sessao.token)),
    );
    if (enviado != true || !mounted) return;
    _justificativas.recarregar();
    AppToast.show(
      context,
      title: 'Justificativa enviada',
      description: 'Acompanhe a resposta do RH em "Minhas justificativas"',
    );
  }

  /// Abre "Alterar senha". Se a troca der certo, a API invalida o token de
  /// agora e manda um novo: ele é salvo e a casca é recriada com ele (todos
  /// os controllers guardam o token), de volta em Meus Dados.
  Future<void> _abrirAlterarSenha() async {
    final novoToken = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ChangePasswordScreen(token: widget.sessao.token)),
    );
    if (novoToken == null || !mounted) return;
    _trocandoToken = true;
    await SessionStorage().salvarToken(novoToken);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => RootShell(
          sessao: widget.sessao.comToken(novoToken),
          abaInicial: _abaMeusDados,
          avisoAoAbrir: (
            titulo: 'Senha alterada',
            descricao: 'Nos outros aparelhos, entre de novo com a senha nova.',
          ),
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
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

  /// "Sair": encerra a sessão no servidor (o token deixa de valer em qualquer
  /// aparelho) e volta pro login.
  Future<void> _sair() async {
    if (_encerrandoSessao) return;
    setState(() => _encerrandoSessao = true);
    try {
      await _authService.logout(widget.sessao.token);
    } catch (_) {
      // Sem conexão ou servidor fora do ar: o token é apagado do aparelho do
      // mesmo jeito, e o servidor deixa de aceitá-lo quando ele expirar.
    }
    await _irParaLogin();
  }

  /// O token foi recusado (401) por alguma chamada: volta pro login com o
  /// motivo que o backend deu (ex.: "Seu acesso foi desativado. Procure o
  /// RH."). Várias chamadas podem dar 401 ao mesmo tempo (ponto +
  /// justificativas), e o "Sair" também pode receber um — só a primeira vale.
  void _sessaoExpirada(String mensagem) {
    if (_encerrandoSessao || _trocandoToken) return;
    _encerrandoSessao = true;
    _irParaLogin(mensagem: mensagem);
  }

  Future<void> _irParaLogin({String? mensagem}) async {
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
      ),
      TalkToHrScreen(token: sessao.token, initials: sessao.iniciais, mensagens: _mensagens),
      PayslipScreen(initials: sessao.iniciais, holerites: _holerites),
      MyDataScreen(
        sessao: sessao,
        cadastro: _cadastro,
        onAlterarSenha: _abrirAlterarSenha,
        onSair: _sair,
        saindo: _encerrandoSessao,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.gray100,
      // O IndexedStack mantém as abas escondidas vivas, inclusive as
      // animações (ex.: o "Carregando…" de uma aba ainda não aberta). O
      // TickerMode pausa essas animações enquanto a aba não está na tela.
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < abas.length; i++) TickerMode(enabled: i == _index, child: abas[i]),
        ],
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, onTap: _selecionarAba),
    );
  }
}
