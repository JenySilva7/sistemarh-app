import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_sistema_final/screens/change_password_screen.dart';
import 'package:app_sistema_final/screens/login_screen.dart';
import 'package:app_sistema_final/screens/my_data_screen.dart';
import 'package:app_sistema_final/screens/root_shell.dart';
import 'package:app_sistema_final/services/api_client.dart';
import 'package:app_sistema_final/services/session_storage.dart';
import 'package:app_sistema_final/widgets/app_bottom_nav.dart';

import 'apoio/api_falsa.dart';
import 'apoio/tela.dart';

void main() {
  late ApiFalsa api;

  setUp(() {
    api = ApiFalsa();
    ApiClient.clientePadrao = api.cliente;
    SharedPreferences.setMockInitialValues({'token_sessao': sessaoDeTeste.token});
    api.responder('GET', '/api/ponto/hoje', []);
    api.responder('GET', '/api/ausencias', []);
  });

  tearDown(() {
    ApiClient.clientePadrao = null;
    ApiClient.aoEncerrarSessao = null;
  });

  Future<void> abrir(WidgetTester tester) async {
    usarTelaDeCelular(tester);
    await tester.pumpWidget(const MaterialApp(home: RootShell(sessao: sessaoDeTeste)));
    await tester.pumpAndSettle();
  }

  /// Toca na aba pela barra de navegação (o mesmo texto pode aparecer dentro
  /// das abas, que continuam montadas no IndexedStack).
  Future<void> irParaAba(WidgetTester tester, String aba) async {
    await tester.tap(find.descendant(of: find.byType(AppBottomNav), matching: find.text(aba)));
    await tester.pumpAndSettle();
  }

  testWidgets('401 ao carregar o Início leva ao login com o aviso de sessão encerrada', (tester) async {
    api.responder('GET', '/api/ponto/hoje', null, status: 401);
    await abrir(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sua sessão foi encerrada. Entre novamente.'), findsOneWidget);
    expect(await SessionStorage().lerToken(), isNull);
  });

  testWidgets('401 em qualquer outra chamada (Holerite) leva ao login com a mensagem do backend', (tester) async {
    api.responder('GET', '/api/me/holerites', {'mensagem': 'Seu acesso foi desativado. Procure o RH.'}, status: 401);
    await abrir(tester);
    expect(find.byType(LoginScreen), findsNothing);

    await irParaAba(tester, 'Holerite');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Seu acesso foi desativado. Procure o RH.'), findsOneWidget);
    expect(find.text('Sua sessão foi encerrada. Entre novamente.'), findsNothing);
  });

  testWidgets('cada aba busca os próprios dados ao ser aberta', (tester) async {
    api.responder('GET', '/api/mensagens-rh/minhas', []);
    api.responder('GET', '/api/me/holerites', []);
    api.responder('GET', '/api/me/cadastro', null, status: 404);
    await abrir(tester);
    expect(api.contar('GET', '/api/me/holerites'), 0);

    await irParaAba(tester, 'Falar com RH');
    await irParaAba(tester, 'Holerite');
    await irParaAba(tester, 'Meus Dados');
    await irParaAba(tester, 'Holerite');

    expect(api.contar('GET', '/api/mensagens-rh/minhas'), 1);
    expect(api.contar('GET', '/api/me/holerites'), 2);
    expect(api.contar('GET', '/api/me/cadastro'), 1);
  });

  testWidgets('Sair chama POST /api/auth/logout, apaga o token e volta ao login', (tester) async {
    api.responder('GET', '/api/me/cadastro', null, status: 404);
    api.responder('POST', '/api/auth/logout', null, status: 204);
    await abrir(tester);
    await irParaAba(tester, 'Meus Dados');

    await tester.ensureVisible(find.text('Sair'));
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(api.contar('POST', '/api/auth/logout'), 1);
    expect(api.requisicoes.last.headers['Authorization'], 'Bearer ${sessaoDeTeste.token}');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sua sessão foi encerrada. Entre novamente.'), findsNothing);
    expect(await SessionStorage().lerToken(), isNull);
  });

  testWidgets('Sair funciona mesmo com o servidor fora do ar', (tester) async {
    api.responder('GET', '/api/me/cadastro', null, status: 404);
    api.responder('POST', '/api/auth/logout', null, status: 502);
    await abrir(tester);
    await irParaAba(tester, 'Meus Dados');

    await tester.ensureVisible(find.text('Sair'));
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(await SessionStorage().lerToken(), isNull);
  });

  Future<void> trocarSenha(WidgetTester tester) async {
    await irParaAba(tester, 'Meus Dados');
    await tester.ensureVisible(find.text('Alterar senha'));
    await tester.tap(find.text('Alterar senha'));
    await tester.pumpAndSettle();
    final campos = find.descendant(of: find.byType(ChangePasswordScreen), matching: find.byType(TextField));
    await tester.enterText(campos.at(0), 'senha123');
    await tester.enterText(campos.at(1), 'outra123');
    await tester.enterText(campos.at(2), 'outra123');
    await tester.tap(find.text('Salvar nova senha'));
    await tester.pumpAndSettle();
  }

  testWidgets('alterar senha: salva o token novo, segue logado e passa a usar só ele', (tester) async {
    api.responder('GET', '/api/me/cadastro', null, status: 404);
    api.responder('PUT', '/api/auth/senha', {'token': 'token-novo'});
    await abrir(tester);
    final antes = api.requisicoes.length;

    await trocarSenha(tester);

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.byType(RootShell), findsOneWidget);
    expect(find.text('Senha alterada'), findsOneWidget);
    expect(await SessionStorage().lerToken(), 'token-novo');
    // Volta em Meus Dados, e tudo o que veio depois da troca usa o token novo.
    expect(find.byType(MyDataScreen), findsOneWidget);
    final depois = api.requisicoes.skip(antes).where((r) => r.url.path != '/api/auth/senha').toList();
    expect(depois.map((r) => r.url.path), containsAll(['/api/ponto/hoje', '/api/me/cadastro']));
    final ultimaLeva = depois.skipWhile((r) => r.headers['Authorization'] != 'Bearer token-novo').toList();
    expect(ultimaLeva, isNotEmpty);
    expect(ultimaLeva.every((r) => r.headers['Authorization'] == 'Bearer token-novo'), isTrue);
    await esperarToastSumir(tester);

    // A casca nova também encerra a sessão num 401 (o aviso global é dela).
    api.responder('GET', '/api/me/holerites', {'mensagem': 'Seu acesso foi desativado. Procure o RH.'}, status: 401);
    await irParaAba(tester, 'Holerite');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Seu acesso foi desativado. Procure o RH.'), findsOneWidget);
  });

  testWidgets('alterar senha com a sessão já encerrada (401) leva ao login', (tester) async {
    api.responder('GET', '/api/me/cadastro', null, status: 404);
    api.responder('PUT', '/api/auth/senha', {'mensagem': 'Sua sessão foi encerrada. Entre novamente.'}, status: 401);
    await abrir(tester);

    await trocarSenha(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sua sessão foi encerrada. Entre novamente.'), findsOneWidget);
    expect(await SessionStorage().lerToken(), isNull);
  });

  testWidgets('ponto: botão travado durante o envio e mensagem do backend no 400', (tester) async {
    final resposta = Completer<http.Response>();
    api.responderCom('POST', '/api/ponto', (_) => resposta.future);
    await abrir(tester);

    await tester.tap(find.text('Registrar entrada'));
    await tester.tap(find.text('Registrar entrada'));
    await tester.pump();

    final botao = find.ancestor(of: find.text('Registrar entrada'), matching: find.byType(ElevatedButton));
    expect(tester.widget<ElevatedButton>(botao).onPressed, isNull);
    expect(api.contar('POST', '/api/ponto'), 1);

    resposta.complete(ApiFalsa.json({'mensagem': 'Aguarde 1 minuto entre registros de ponto.'}, status: 400));
    await tester.pump();
    await tester.pump();

    expect(find.text('Não foi possível registrar'), findsOneWidget);
    expect(find.text('Aguarde 1 minuto entre registros de ponto.'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(botao).onPressed, isNotNull);
    await esperarToastSumir(tester);
  });
}
