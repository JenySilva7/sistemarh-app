// Teste de integração do app do colaborador: roda o app de verdade num
// emulador Android, falando com a API local (nada de API falsa).
//
// COMO RODAR (na pasta do app, com o emulador já aberto):
//
//   flutter test integration_test/app_test.dart -d <emulador> --dart-define=API_BASE_URL=http://10.0.2.2:5080
//
// O <emulador> é o id que aparece em `flutter devices` (ex.: emulator-5554).
// Dentro do emulador Android, 10.0.2.2 é o computador; o build de debug já
// permite HTTP sem TLS (android/app/src/debug/AndroidManifest.xml).
//
// PRÉ-CONDIÇÕES
// - API local no ar na porta 5080 do computador, já com as rotas do contrato
//   novo: POST /api/auth/logout, PUT /api/auth/senha, GET /api/me/cadastro,
//   GET /api/me/holerites, POST /api/mensagens-rh, GET /api/mensagens-rh/minhas,
//   o 409 de justificativa repetida e a espera de 1 minuto entre registros de
//   ponto.
// - Conta zedalima00@gmail.com / 123456 (Funcionário) ligada a um colaborador
//   ATIVO (no banco local, o colaborador 23). É a conta do login, do Falar com
//   o RH, do Meus dados, da sessão derrubada e do logout.
// - Conta rh.teste@empresa.com / 123456 (RH). Pela API, o teste cria a cada
//   execução um colaborador novo ("IT App ...", e-mail it.app.<horário>@teste.com)
//   com acesso ao app, usa esse colaborador no ponto, na justificativa, no
//   holerite e na troca de senha (o último caso), lança uma folha para ele e,
//   no fim, o desliga. Esses fluxos precisam começar do zero (o dia só tem 4
//   marcações, a justificativa repetida dá 409, o holerite tem de começar
//   vazio) ou mexem na conta (a senha), por isso não usam o zedalima — a senha
//   do zedalima NUNCA é trocada.
// - Pelo menos um departamento e um cargo cadastrados.
// - Menos de 4 logins errados do zedalima nos últimos 15 minutos: o teste erra
//   a senha uma vez de propósito, e com 5 erros a API bloqueia o login.
//
// O que fica no banco a cada execução: o colaborador "IT App ..." (desligado no
// fim, com a senha trocada), 1 marcação de ponto e 1 justificativa dele, 1
// folha de pagamento dele e 1 mensagem ao RH do zedalima ("IT App ...").

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app_sistema_final/main.dart';
import 'package:app_sistema_final/screens/change_password_screen.dart';
import 'package:app_sistema_final/screens/login_screen.dart';
import 'package:app_sistema_final/screens/my_data_screen.dart';
import 'package:app_sistema_final/screens/payslip_screen.dart';
import 'package:app_sistema_final/screens/talk_to_hr_screen.dart';
import 'package:app_sistema_final/services/api_config.dart';
import 'package:app_sistema_final/services/ausencia_service.dart';
import 'package:app_sistema_final/services/session_storage.dart';
import 'package:app_sistema_final/utils/formatters.dart';
import 'package:app_sistema_final/widgets/app_bottom_nav.dart';

const _emailZe = 'zedalima00@gmail.com';
const _emailRh = 'rh.teste@empresa.com';
const _senha = '123456';
const _mensagemSessaoEncerrada = 'Sua sessão foi encerrada. Entre novamente.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String tokenRh;
  late _Conta novo;

  setUpAll(() async {
    tokenRh = await _Api.login(_emailRh, _senha);
    novo = await _criarColaboradorDeTeste(tokenRh);
  });

  tearDownAll(() async {
    // Tira o colaborador de teste das listas de ativos do painel.
    try {
      await _Api.enviar('POST', '/api/funcionarios/${novo.funcionarioId}/desligar', token: tokenRh, corpo: {});
    } catch (_) {}
  });

  testWidgets('login: senha errada mostra o erro e a certa abre o Início', (tester) async {
    await _abrirApp(tester);

    // A senha errada não pode conter "senha": o finder de texto também lê o
    // que está digitado nos campos.
    await _preencherLogin(tester, _emailZe, 'errada-999');
    await tester.tap(find.text('Entrar'));
    final caixaDeErro = find.descendant(of: find.byType(LoginScreen), matching: find.byIcon(LucideIcons.circleAlert));
    await _esperar(tester, caixaDeErro);
    // "E-mail ou senha incorretos." (e nunca o bloqueio por tentativas).
    expect(find.textContaining('senha'), findsOneWidget);
    expect(find.textContaining('Muitas tentativas'), findsNothing);
    expect(find.byType(AppBottomNav), findsNothing);

    await _preencherLogin(tester, _emailZe, _senha);
    await tester.tap(find.text('Entrar'));
    await _esperar(tester, find.byType(AppBottomNav));
    await _esperar(tester, find.text('Registros de hoje'));
    expect(find.textContaining('Zezinho'), findsWidgets);
    expect(await SessionStorage().lerToken(), isNotNull);
  });

  testWidgets('ponto: toque duplo grava 1 registro e o seguinte, antes de 1 minuto, mostra o aviso da API', (
    tester,
  ) async {
    final token = await _Api.login(novo.email, novo.senha);
    final antes = (await _Api.enviar('GET', '/api/ponto/hoje', token: token) as List).length;
    expect(antes, 0, reason: 'o colaborador de teste acabou de ser criado');

    await _abrirApp(tester);
    await _entrar(tester, novo.email, novo.senha);
    await _esperar(tester, find.text('Registrar entrada'));

    await _toqueDuplo(tester, find.text('Registrar entrada'));
    await _esperar(tester, find.text('Entrada registrada'));
    await _esperar(tester, find.text('Registrar saída'));
    await _aguardar(tester, const Duration(seconds: 2));
    expect((await _Api.enviar('GET', '/api/ponto/hoje', token: token) as List).length, 1);

    await _tocar(tester, find.text('Registrar saída'));
    await _esperar(tester, find.textContaining('Aguarde 1 minuto'));
    expect(find.text('Não foi possível registrar'), findsWidgets);
    expect((await _Api.enviar('GET', '/api/ponto/hoje', token: token) as List).length, 1);
  });

  testWidgets('justificativa: envia uma vez (mesmo com toque duplo) e a repetida mostra o aviso de duplicada', (
    tester,
  ) async {
    final token = await _Api.login(novo.email, novo.senha);
    await _abrirApp(tester);
    await _entrar(tester, novo.email, novo.senha);
    await _esperar(tester, find.text('Justificar ausência'));

    await _abrirJustificativa(tester);
    // Validação local, igual à da API, antes de qualquer envio.
    await _tocar(tester, find.text('Enviar justificativa'));
    await _esperar(tester, find.text('Selecione a data da ausência.'));
    await _escolherHoje(tester);
    await _digitar(tester, find.byType(TextField).last, 'IT App: consulta médica de rotina');

    await _toqueDuplo(tester, find.text('Enviar justificativa'));
    await _esperar(tester, find.text('Justificativa enviada'));
    await _esperar(tester, find.text('Enviada'));
    await _aguardar(tester, const Duration(seconds: 2));
    expect((await _Api.enviar('GET', '/api/ausencias', token: token) as List).length, 1);
    // Se o segundo toque cair na barra de navegação do Início (a tela já
    // tinha fechado), volta pra aba certa.
    await _irParaAba(tester, 'Início');

    // Mesma data, mesmo tipo, ainda com o RH: a API recusa com 409.
    await _abrirJustificativa(tester);
    await _escolherHoje(tester);
    await _digitar(tester, find.byType(TextField).last, 'IT App: consulta médica de rotina');
    await _tocar(tester, find.text('Enviar justificativa'));
    await _esperar(tester, find.text(mensagemJustificativaDuplicada));
    expect(find.text('Enviar justificativa'), findsOneWidget, reason: 'continua na tela pra corrigir');
    expect((await _Api.enviar('GET', '/api/ausencias', token: token) as List).length, 1);

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await _esperar(tester, find.byType(AppBottomNav));
  });

  testWidgets('holerite: começa vazio e mostra a folha que o RH lançar', (tester) async {
    await _abrirApp(tester);
    await _entrar(tester, novo.email, novo.senha);
    await _irParaAba(tester, 'Holerite');
    await _esperar(tester, find.text('Nenhum holerite disponível'));
    expect(find.descendant(of: find.byType(PayslipScreen), matching: find.textContaining('R\$')), findsNothing);

    final mesPassado = DateTime(DateTime.now().year, DateTime.now().month - 1);
    final competencia = '${mesPassado.year}-${mesPassado.month.toString().padLeft(2, '0')}';
    await _Api.enviar(
      'POST',
      '/api/folha-pagamento?funcionarioId=${novo.funcionarioId}',
      token: tokenRh,
      corpo: {'competencia': competencia, 'salario': 4321.50, 'bonus': 100, 'descontos': 654.25},
    );

    // Reabrir a aba busca de novo.
    await _irParaAba(tester, 'Início');
    await _irParaAba(tester, 'Holerite');
    await _esperar(tester, find.text(formatarMoeda(3767.25)));
    expect(find.text(formatarCompetencia(competencia)), findsWidgets);
    expect(find.text(formatarMoeda(4421.50)), findsOneWidget);
    expect(find.text(formatarMoeda(654.25)), findsOneWidget);
    expect(find.text('Nenhum holerite disponível'), findsNothing);
  });

  testWidgets('falar com o RH: valida, envia uma vez só e a mensagem aparece em Minhas mensagens', (tester) async {
    final token = await _Api.login(_emailZe, _senha);
    final agora = DateTime.now();
    final assunto =
        'IT App ${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')} '
        '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}:'
        '${agora.second.toString().padLeft(2, '0')}';

    await _abrirApp(tester);
    await _entrar(tester, _emailZe, _senha);
    await _irParaAba(tester, 'Falar com RH');
    await _esperarSumir(tester, find.text('Carregando suas mensagens…'));
    final tela = find.byType(TalkToHrScreen);
    final campos = find.descendant(of: tela, matching: find.byType(TextField));
    expect(find.descendant(of: tela, matching: find.textContaining('e-mail')), findsNothing);

    await _digitar(tester, campos.at(0), 'ab');
    // Texto longo: as quebras de linha têm de chegar ao RH como foram digitadas.
    await _digitar(tester, campos.at(1), 'Bom dia,\n\nGostaria de saber o saldo das minhas férias.\nObrigado!');
    await _tocar(tester, find.text('Enviar mensagem'));
    await _esperar(tester, find.text('O assunto precisa ter pelo menos 3 caracteres.'));

    await _digitar(tester, campos.at(0), assunto);
    await _toqueDuplo(tester, find.text('Enviar mensagem'));
    await _esperar(tester, find.text('Mensagem enviada ao RH'));
    await _esperar(tester, find.text(assunto));
    expect(find.text('Aguardando resposta'), findsWidgets);

    final minhas = await _Api.enviar('GET', '/api/mensagens-rh/minhas', token: token) as List;
    final enviadas = minhas.where((m) => m['assunto'] == assunto).toList();
    expect(enviadas.length, 1);
    expect(enviadas.single['mensagem'], 'Bom dia,\n\nGostaria de saber o saldo das minhas férias.\nObrigado!');
  });

  testWidgets('meus dados: mostra CPF, telefone, nascimento, salário e VA do cadastro', (tester) async {
    final token = await _Api.login(_emailZe, _senha);
    final cadastro = await _Api.enviar('GET', '/api/me/cadastro', token: token) as Map<String, dynamic>;

    await _abrirApp(tester);
    await _entrar(tester, _emailZe, _senha);
    await _irParaAba(tester, 'Meus Dados');
    await _esperar(tester, find.text('CPF'));

    final rolagem = find.descendant(of: find.byType(MyDataScreen), matching: find.byType(Scrollable)).first;
    Future<void> confere(String texto) async {
      await tester.scrollUntilVisible(find.text(texto).first, 150, scrollable: rolagem);
      expect(find.text(texto), findsWidgets);
    }

    await confere(formatarCpf(cadastro['cpf'] as String));
    final telefone = (cadastro['telefone'] as String?)?.trim();
    await confere(telefone == null || telefone.isEmpty ? '—' : telefone);
    final nascimento = cadastro['dataNascimento'] as String?;
    await confere(nascimento == null ? '—' : formatarData(DateTime.parse(nascimento.substring(0, 10))));
    await confere(formatarMoeda(cadastro['salario'] as num));
    await confere(formatarMoeda(cadastro['valeAlimentacao'] as num));
  });

  testWidgets('sessão derrubada no servidor: a próxima chamada leva ao login com o aviso', (tester) async {
    await _abrirApp(tester);
    await _entrar(tester, _emailZe, _senha);
    final token = await SessionStorage().lerToken();
    expect(token, isNotNull);

    // Logout feito "em outro lugar": invalida todos os tokens do zedalima.
    await _Api.enviar('POST', '/api/auth/logout', token: token);
    await _irParaAba(tester, 'Holerite');

    await _esperar(tester, find.text(_mensagemSessaoEncerrada));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(await SessionStorage().lerToken(), isNull);
  });

  testWidgets('logout: Sair volta ao login e o token deixa de valer no servidor', (tester) async {
    await _abrirApp(tester);
    await _entrar(tester, _emailZe, _senha);
    final token = await SessionStorage().lerToken();
    expect(await _Api.status('GET', '/api/auth/me', token: token), 200);

    await _irParaAba(tester, 'Meus Dados');
    // Espera o cadastro chegar: ele muda a altura da tela e mudaria a
    // posição do botão Sair no meio do toque.
    await _esperar(tester, find.text('CPF'));
    await _tocar(tester, find.text('Sair'));

    await _esperar(tester, find.byType(LoginScreen));
    expect(find.text(_mensagemSessaoEncerrada), findsNothing);
    expect(await SessionStorage().lerToken(), isNull);
    expect(await _Api.status('GET', '/api/auth/me', token: token), 401);
  });

  // Fica por último: depois dele, a senha do colaborador de teste já não é
  // mais a de criação.
  testWidgets('alterar senha: o token antigo deixa de valer, o app segue logado e a senha nova entra', (
    tester,
  ) async {
    const senhaNova = 'NovaSenha#2026';
    await _abrirApp(tester);
    await _entrar(tester, novo.email, novo.senha);
    final tokenAntigo = await SessionStorage().lerToken();
    expect(await _Api.status('GET', '/api/auth/me', token: tokenAntigo), 200);

    await _irParaAba(tester, 'Meus Dados');
    await _esperar(tester, find.text('CPF'));
    await _tocar(tester, find.text('Alterar senha'));
    await _esperar(tester, find.text('Salvar nova senha'));
    await _aguardar(tester, const Duration(milliseconds: 600));
    final campos = find.descendant(of: find.byType(ChangePasswordScreen), matching: find.byType(TextField));

    // Validação local antes de enviar: a confirmação precisa bater.
    await _digitar(tester, campos.at(0), novo.senha);
    await _digitar(tester, campos.at(1), senhaNova);
    await _digitar(tester, campos.at(2), '${senhaNova}x');
    await _tocar(tester, find.text('Salvar nova senha'));
    await _esperar(tester, find.text('A confirmação não é igual à nova senha.'));

    await _digitar(tester, campos.at(2), senhaNova);
    await _tocar(tester, find.text('Salvar nova senha'));
    await _esperar(tester, find.text('Senha alterada'));
    await _esperarSumir(tester, find.byType(ChangePasswordScreen));
    expect(find.byType(LoginScreen), findsNothing);

    final tokenNovo = await SessionStorage().lerToken();
    expect(tokenNovo, isNotNull);
    expect(tokenNovo, isNot(tokenAntigo));
    expect(await _Api.status('GET', '/api/auth/me', token: tokenAntigo), 401);
    expect(await _Api.status('GET', '/api/auth/me', token: tokenNovo), 200);

    // O app segue usando o token novo: abrir o Holerite não derruba a sessão.
    await _irParaAba(tester, 'Holerite');
    await _esperarSumir(tester, find.text('Carregando seus holerites…'));
    expect(find.byType(LoginScreen), findsNothing);

    // A senha nova entra; a antiga, não.
    final login = {'email': novo.email, 'senha': senhaNova};
    expect(await _Api.status('POST', '/api/auth/login', corpo: login), 200);
    expect(await _Api.status('POST', '/api/auth/login', corpo: {'email': novo.email, 'senha': novo.senha}), 400);
  });
}

// ── Navegação no app ────────────────────────────────────────────────────

/// Abre o app do zero, sem sessão salva, e espera a tela de login.
Future<void> _abrirApp(WidgetTester tester) async {
  await SessionStorage().limpar();
  await tester.pumpWidget(const SistemaRhApp());
  await _esperar(tester, find.text('Entrar'));
}

Future<void> _preencherLogin(WidgetTester tester, String email, String senha) async {
  await _digitar(tester, find.byType(TextFormField).at(0), email);
  await _digitar(tester, find.byType(TextFormField).at(1), senha);
}

/// Faz login pela tela e espera o Início.
Future<void> _entrar(WidgetTester tester, String email, String senha) async {
  await _preencherLogin(tester, email, senha);
  await _tocar(tester, find.text('Entrar'));
  await _esperar(tester, find.byType(AppBottomNav));
}

/// Toca na aba pela barra de navegação (o mesmo texto aparece dentro das
/// abas, que continuam montadas no IndexedStack).
Future<void> _irParaAba(WidgetTester tester, String aba) async {
  await tester.tap(find.descendant(of: find.byType(AppBottomNav), matching: find.text(aba)));
  await _aguardar(tester, const Duration(milliseconds: 500));
}

Future<void> _abrirJustificativa(WidgetTester tester) async {
  await _tocar(tester, find.text('Justificar ausência'));
  await _esperar(tester, find.text('Enviar justificativa'));
  // Espera a transição terminar: só então o Início sai da árvore visível
  // e os finders enxergam apenas os campos desta tela.
  await _aguardar(tester, const Duration(milliseconds: 600));
}

/// Abre o calendário da data da ausência e confirma o dia já marcado (hoje).
Future<void> _escolherHoje(WidgetTester tester) async {
  await _tocar(tester, find.widgetWithText(TextField, 'Selecione a data'));
  await _esperar(tester, find.text('Confirmar'));
  await _aguardar(tester, const Duration(milliseconds: 400));
  await tester.tap(find.text('Confirmar'));
  await _esperarSumir(tester, find.text('Confirmar'));
}

/// Rola até [alvo] ficar no meio da área visível e espera a tela redesenhar.
///
/// O `tester.ensureVisible` (e o `scrollUntilVisible`) só pulam a rolagem:
/// sem um quadro novo, o toque seguinte usa a posição antiga do widget — que
/// podia estar atrás da barra de navegação ou fora da tela. E ele leva o
/// widget pro topo, onde aparecem os toasts; no meio, fica longe dos dois.
Future<void> _mostrar(WidgetTester tester, Finder alvo) async {
  await Scrollable.ensureVisible(tester.element(alvo), alignment: 0.5);
  await tester.pump();
  await _aguardar(tester, const Duration(milliseconds: 200));
}

/// Digita no campo e tira o foco, pra o teclado do emulador não cobrir os
/// botões de baixo.
///
/// O `enterText` só reconecta o teclado quando o campo muda (o binding guarda
/// o último campo em `focusedEditable`). Como o foco é tirado aqui por fora
/// do binding, digitar de novo no MESMO campo caía num teclado desconectado e
/// o texto se perdia em silêncio — foi o que travou a troca de senha (a
/// confirmação continuava com o valor antigo e o app, corretamente, recusava).
/// Por isso o binding "esquece" o campo junto com o foco, e o valor digitado
/// é conferido na hora.
Future<void> _digitar(WidgetTester tester, Finder campo, String texto) async {
  await _mostrar(tester, campo);
  await tester.enterText(campo, texto);
  FocusManager.instance.primaryFocus?.unfocus();
  tester.binding.focusedEditable = null;
  await _aguardar(tester, const Duration(milliseconds: 400));
  final editavel = find.descendant(of: campo, matching: find.byType(EditableText), matchRoot: true);
  expect(tester.widget<EditableText>(editavel).controller.text, texto, reason: 'o campo não recebeu o texto digitado');
}

/// Dois toques seguidos no mesmo ponto, sem esperar a tela redesenhar —
/// como um toque duplo de verdade. O ponto é calculado uma vez só porque,
/// depois do primeiro toque, o texto do botão pode virar um indicador de
/// progresso.
Future<void> _toqueDuplo(WidgetTester tester, Finder alvo) async {
  await _mostrar(tester, alvo);
  final ponto = tester.getCenter(alvo);
  await tester.tapAt(ponto);
  await tester.tapAt(ponto);
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await _mostrar(tester, alvo);
  await tester.tap(alvo);
  await tester.pump();
}

// ── Espera (tempo real: o app fala com a API de verdade) ────────────────

Future<void> _aguardar(WidgetTester tester, Duration tempo) async {
  final fim = DateTime.now().add(tempo);
  while (DateTime.now().isBefore(fim)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Espera [alvo] aparecer. Não usa pumpAndSettle porque o relógio do ponto e
/// os indicadores de carregamento pedem quadros o tempo todo.
Future<void> _esperar(WidgetTester tester, Finder alvo, {Duration limite = const Duration(seconds: 30)}) async {
  final fim = DateTime.now().add(limite);
  while (alvo.evaluate().isEmpty) {
    if (DateTime.now().isAfter(fim)) fail('Não apareceu em ${limite.inSeconds} s: $alvo');
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _esperarSumir(WidgetTester tester, Finder alvo, {Duration limite = const Duration(seconds: 30)}) async {
  final fim = DateTime.now().add(limite);
  while (alvo.evaluate().isNotEmpty) {
    if (DateTime.now().isAfter(fim)) fail('Não sumiu em ${limite.inSeconds} s: $alvo');
    await tester.pump(const Duration(milliseconds: 200));
  }
}

// ── Chamadas diretas à API (preparar dados e conferir o que foi gravado) ──

class _Conta {
  final String email;
  final String senha;
  final int funcionarioId;

  const _Conta(this.email, this.senha, this.funcionarioId);
}

class _Api {
  static Future<http.Response> _requisitar(String metodo, String caminho, {String? token, Object? corpo}) async {
    final requisicao = http.Request(metodo, Uri.parse('$apiBaseUrl$caminho'));
    requisicao.headers.addAll({
      'Accept': 'application/json',
      if (corpo != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (corpo != null) requisicao.body = jsonEncode(corpo);
    return http.Response.fromStream(await requisicao.send().timeout(const Duration(seconds: 20)));
  }

  /// Faz a chamada e devolve o JSON da resposta; qualquer status fora de
  /// 2xx falha o teste mostrando o que a API respondeu.
  static Future<dynamic> enviar(String metodo, String caminho, {String? token, Object? corpo}) async {
    final resposta = await _requisitar(metodo, caminho, token: token, corpo: corpo);
    final texto = utf8.decode(resposta.bodyBytes, allowMalformed: true);
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw StateError('$metodo $caminho respondeu ${resposta.statusCode}: $texto');
    }
    return texto.trim().isEmpty ? null : jsonDecode(texto);
  }

  static Future<int> status(String metodo, String caminho, {String? token, Object? corpo}) async =>
      (await _requisitar(metodo, caminho, token: token, corpo: corpo)).statusCode;

  static Future<String> login(String email, String senha) async {
    final resposta = await enviar('POST', '/api/auth/login', corpo: {'email': email, 'senha': senha});
    return (resposta as Map<String, dynamic>)['token'] as String;
  }
}

/// Cria, como RH, um colaborador novo com acesso ao app (senha 123456).
Future<_Conta> _criarColaboradorDeTeste(String tokenRh) async {
  final carimbo = DateTime.now().millisecondsSinceEpoch;
  // Nome só com letras (a API exige pelo menos 2 letras): os dígitos do
  // horário viram letras, pra o nome não se repetir entre execuções.
  final sufixo = carimbo.toString().split('').map((d) => 'abcdefghij'[int.parse(d)]).join();
  final email = 'it.app.$carimbo@teste.com';

  final departamentos = await _Api.enviar('GET', '/api/departamentos', token: tokenRh) as List;
  final cargos = await _Api.enviar('GET', '/api/cargos', token: tokenRh) as List;
  if (departamentos.isEmpty || cargos.isEmpty) {
    throw StateError('Pré-condição: cadastre pelo menos um departamento e um cargo.');
  }

  final funcionario = await _Api.enviar(
    'POST',
    '/api/funcionarios',
    token: tokenRh,
    corpo: {
      'nome': 'IT App ${sufixo.substring(sufixo.length - 8)}',
      'cpf': _cpfValido(carimbo),
      'email': email,
      'dataNascimento': '1995-05-10',
      'dataAdmissao': '2025-01-10',
      'departamentoId': departamentos.first['id'],
      'cargoId': cargos.first['id'],
      'salario': 4000,
      'valeAlimentacao': 500,
    },
  ) as Map<String, dynamic>;
  final id = funcionario['id'] as int;
  await _Api.enviar('POST', '/api/funcionarios/$id/acesso-app', token: tokenRh, corpo: {'senha': _senha});
  return _Conta(email, _senha, id);
}

/// CPF com dígitos verificadores válidos, a partir de [semente].
String _cpfValido(int semente) {
  final digitos = (semente % 1000000000).toString().padLeft(9, '0').split('').map(int.parse).toList();
  if (digitos.toSet().length == 1) digitos[0] = (digitos[0] + 1) % 10;
  for (var k = 0; k < 2; k++) {
    var soma = 0;
    for (var i = 0; i < digitos.length; i++) {
      soma += digitos[i] * (digitos.length + 1 - i);
    }
    final resto = (soma * 10) % 11;
    digitos.add(resto == 10 ? 0 : resto);
  }
  final c = digitos.join();
  return '${c.substring(0, 3)}.${c.substring(3, 6)}.${c.substring(6, 9)}-${c.substring(9)}';
}
