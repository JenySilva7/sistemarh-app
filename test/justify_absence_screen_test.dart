import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:app_sistema_final/screens/justify_absence_screen.dart';
import 'package:app_sistema_final/services/api_client.dart';
import 'package:app_sistema_final/services/ausencia_service.dart';
import 'package:app_sistema_final/utils/horario_brasilia.dart';

import 'apoio/api_falsa.dart';
import 'apoio/tela.dart';

const _rota = '/api/ausencias';

void main() {
  late ApiFalsa api;
  late List<bool?> resultados;

  setUp(() {
    api = ApiFalsa();
    ApiClient.clientePadrao = api.cliente;
    resultados = [];
  });

  tearDown(() => ApiClient.clientePadrao = null);

  /// Abre a tela por cima de uma página, como o Início faz, guardando o
  /// resultado do pop.
  Future<void> abrir(WidgetTester tester) async {
    usarTelaDeCelular(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultados.add(
                    await Navigator.of(
                      context,
                    ).push<bool>(MaterialPageRoute(builder: (_) => const JustifyAbsenceScreen(token: 't'))),
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

  Future<void> escolherHoje(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextField, 'Selecione a data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
  }

  // Durante o envio o texto do botão vira um indicador de progresso, então
  // o botão é achado pelo tipo (a página de baixo fica fora da tela).
  Finder botaoEnviar() => find.byType(ElevatedButton);

  /// Toca em enviar e espera o aviso (SnackBar) anterior sair e o novo entrar.
  Future<void> tocarEnviar(WidgetTester tester) async {
    await tester.tap(find.text('Enviar justificativa'));
    await tester.pumpAndSettle();
  }

  testWidgets('valida data e descrição como a API antes de enviar', (tester) async {
    await abrir(tester);

    await tocarEnviar(tester);
    expect(find.text('Selecione a data da ausência.'), findsOneWidget);

    await escolherHoje(tester);
    await tester.enterText(find.byType(TextField).last, '  a  ');
    await tocarEnviar(tester);
    expect(find.text('A descrição precisa ter pelo menos 3 caracteres.'), findsOneWidget);
    expect(api.contar('POST', _rota), 0);
  });

  testWidgets('trava o botão durante o envio: toque duplo vira um envio só', (tester) async {
    await abrir(tester);
    final resposta = Completer<http.Response>();
    api.responderCom('POST', _rota, (_) => resposta.future);
    await escolherHoje(tester);
    await tester.enterText(find.byType(TextField).last, '  Consulta   médica\r\n\n\n\nAtestado com o RH. ');

    await tester.tap(find.text('Enviar justificativa'));
    await tester.tap(find.text('Enviar justificativa'));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(botaoEnviar()).onPressed, isNull);
    expect(api.contar('POST', _rota), 1);
    final agora = agoraBrasilia();
    final hoje =
        '${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}';
    expect(api.ultimoCorpo('POST', _rota), {
      'tipo': 0,
      'data': hoje,
      'diaInteiro': true,
      // Quebras de linha preservadas (no máximo 2 seguidas).
      'descricao': 'Consulta médica\n\nAtestado com o RH.',
    });

    resposta.complete(ApiFalsa.json({'id': 10, 'status': 0, 'versao': 1}, status: 201));
    await tester.pumpAndSettle();

    expect(resultados, [true]);
  });

  testWidgets('justificativa repetida (409) mostra mensagem clara e fica na tela', (tester) async {
    await abrir(tester);
    api.responder('POST', _rota, {'mensagem': 'Conflict'}, status: 409);
    await escolherHoje(tester);
    await tester.enterText(find.byType(TextField).last, 'Consulta médica');

    await tocarEnviar(tester);

    expect(find.text(mensagemJustificativaDuplicada), findsOneWidget);
    expect(resultados, isEmpty);
    expect(tester.widget<ElevatedButton>(botaoEnviar()).onPressed, isNotNull);
  });

  testWidgets('outros erros mostram a mensagem do backend', (tester) async {
    await abrir(tester);
    api.responder('POST', _rota, {'mensagem': 'Informe a data da ausência.'}, status: 400);
    await escolherHoje(tester);
    await tester.enterText(find.byType(TextField).last, 'Consulta médica');

    await tocarEnviar(tester);

    expect(find.text('Informe a data da ausência.'), findsOneWidget);
  });
}
