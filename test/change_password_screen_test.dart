import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:app_sistema_final/screens/change_password_screen.dart';
import 'package:app_sistema_final/services/api_client.dart';
import 'package:app_sistema_final/utils/validacao.dart';

import 'apoio/api_falsa.dart';
import 'apoio/tela.dart';

const _rota = '/api/auth/senha';

void main() {
  late ApiFalsa api;
  late List<String?> resultados;

  setUp(() {
    api = ApiFalsa();
    ApiClient.clientePadrao = api.cliente;
    resultados = [];
  });

  tearDown(() => ApiClient.clientePadrao = null);

  /// Abre a tela por cima de uma página, como Meus Dados faz, guardando o
  /// que ela devolve no pop (o token novo).
  Future<void> abrir(WidgetTester tester) async {
    usarTelaDeCelular(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  resultados.add(
                    await Navigator.of(
                      context,
                    ).push<String>(MaterialPageRoute(builder: (_) => const ChangePasswordScreen(token: 't'))),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Finder campo(int i) => find.byType(TextField).at(i);
  Finder botaoSalvar() => find.byType(ElevatedButton);

  Future<void> preencher(WidgetTester tester, {required String atual, required String nova, String? confirmacao}) async {
    await tester.enterText(campo(0), atual);
    await tester.enterText(campo(1), nova);
    await tester.enterText(campo(2), confirmacao ?? nova);
  }

  Future<void> salvar(WidgetTester tester) async {
    await tester.tap(botaoSalvar());
    await tester.pumpAndSettle();
  }

  testWidgets('valida como a API antes de enviar', (tester) async {
    await abrir(tester);
    final casos = <({String atual, String nova, String? confirmacao, String erro})>[
      (atual: '', nova: 'outra123', confirmacao: null, erro: 'Informe a senha atual.'),
      (atual: 'senha123', nova: '123', confirmacao: null, erro: 'A nova senha precisa ter pelo menos 6 caracteres.'),
      (atual: 'senha123', nova: 'senha123', confirmacao: null, erro: 'A nova senha precisa ser diferente da atual.'),
      (
        atual: 'senha123',
        nova: 'Abc${String.fromCharCodes([0x2764, 0xFE0F])}123',
        confirmacao: null,
        erro: mensagemSenhaComEmojiOuInvisivel,
      ),
      (atual: 'senha123', nova: 'outra123 ', confirmacao: null, erro: 'A nova senha não pode começar nem terminar com espaço.'),
      (atual: 'senha123', nova: 'outra123', confirmacao: 'outra124', erro: 'A confirmação não é igual à nova senha.'),
    ];

    for (final caso in casos) {
      await preencher(tester, atual: caso.atual, nova: caso.nova, confirmacao: caso.confirmacao);
      await salvar(tester);
      expect(find.text(caso.erro), findsOneWidget, reason: caso.erro);
    }
    expect(api.contar('PUT', _rota), 0);
    expect(resultados, isEmpty);
  });

  testWidgets('trava o botão durante o envio e devolve o token novo', (tester) async {
    await abrir(tester);
    final resposta = Completer<http.Response>();
    api.responderCom('PUT', _rota, (_) => resposta.future);
    await preencher(tester, atual: 'senha123', nova: 'minha senha nova');

    // Toque duplo: os dois chegam antes de o botão ser redesenhado.
    await tester.tap(botaoSalvar());
    await tester.tap(botaoSalvar());
    await tester.pump();

    expect(tester.widget<ElevatedButton>(botaoSalvar()).onPressed, isNull);
    expect(api.contar('PUT', _rota), 1);
    expect(api.requisicoes.single.headers['Authorization'], 'Bearer t');
    // As senhas vão como foram digitadas, sem aparar.
    expect(api.ultimoCorpo('PUT', _rota), {'senhaAtual': 'senha123', 'novaSenha': 'minha senha nova'});

    resposta.complete(ApiFalsa.json({'token': 'token-novo'}));
    await tester.pumpAndSettle();

    expect(resultados, ['token-novo']);
    expect(find.byType(ChangePasswordScreen), findsNothing);
  });

  testWidgets('senha atual errada (400) mostra a mensagem da API e mantém o que foi digitado', (tester) async {
    await abrir(tester);
    api.responder('PUT', _rota, {'mensagem': 'Senha atual incorreta.'}, status: 400);
    await preencher(tester, atual: 'errada1', nova: 'outra123');

    await salvar(tester);

    expect(find.text('Senha atual incorreta.'), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(tester.widget<TextField>(campo(1)).controller!.text, 'outra123');
    expect(tester.widget<ElevatedButton>(botaoSalvar()).onPressed, isNotNull);
    expect(resultados, isEmpty);
  });

  testWidgets('tentativas demais (429) mostram a mensagem da API', (tester) async {
    await abrir(tester);
    const aviso = 'Muitas tentativas de login. Tente novamente em 15 minuto(s).';
    api.responder('PUT', _rota, {'mensagem': aviso}, status: 429);
    await preencher(tester, atual: 'senha123', nova: 'outra123');

    await salvar(tester);

    expect(find.text(aviso), findsOneWidget);
    expect(resultados, isEmpty);
  });

  testWidgets('resposta sem token não é tratada como sucesso', (tester) async {
    await abrir(tester);
    api.responder('PUT', _rota, {});
    await preencher(tester, atual: 'senha123', nova: 'outra123');

    await salvar(tester);

    expect(find.textContaining('resposta inesperada'), findsOneWidget);
    expect(resultados, isEmpty);
  });

  testWidgets('o olho mostra e esconde as senhas', (tester) async {
    await abrir(tester);
    expect(tester.widget<TextField>(campo(1)).obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar senhas').first);
    await tester.pump();

    expect(tester.widget<TextField>(campo(0)).obscureText, isFalse);
    expect(tester.widget<TextField>(campo(1)).obscureText, isFalse);
    expect(tester.widget<TextField>(campo(2)).obscureText, isFalse);
  });
}
