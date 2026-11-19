import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:app_sistema_final/models/carregamento_controller.dart';
import 'package:app_sistema_final/screens/talk_to_hr_screen.dart';
import 'package:app_sistema_final/services/api_client.dart';
import 'package:app_sistema_final/services/mensagem_rh_service.dart';

import 'apoio/api_falsa.dart';
import 'apoio/tela.dart';

const _rotaEnviar = '/api/mensagens-rh';
const _rotaMinhas = '/api/mensagens-rh/minhas';

Map<String, dynamic> _mensagemJson({
  int id = 1,
  String assunto = 'Férias de julho',
  int status = 0,
  String? resposta,
  String? responsavelNome,
  String? respondidaEm,
}) => {
  'id': id,
  'usuarioId': 8,
  'usuarioNome': 'Zezinho Da Lima',
  'assunto': assunto,
  'mensagem': 'Quero tirar férias em julho.',
  'status': status,
  'resposta': resposta,
  'respondidaEm': respondidaEm,
  'responsavelNome': responsavelNome,
  'criadoEm': '2026-11-18T13:00:00Z',
  'versao': 1,
};

void main() {
  late ApiFalsa api;

  setUp(() {
    api = ApiFalsa();
    ApiClient.clientePadrao = api.cliente;
    api.responder('GET', _rotaMinhas, []);
  });

  tearDown(() => ApiClient.clientePadrao = null);

  Future<CarregamentoController<List<MensagemRh>>> abrir(WidgetTester tester) async {
    usarTelaDeCelular(tester);
    final mensagens = CarregamentoController<List<MensagemRh>>(() => MensagemRhService().listarMinhas('t'));
    addTearDown(mensagens.dispose);
    await tester.pumpWidget(comoAba(TalkToHrScreen(token: 't', initials: 'ZL', mensagens: mensagens)));
    mensagens.recarregar();
    await tester.pumpAndSettle();
    return mensagens;
  }

  Future<void> preencher(WidgetTester tester, {required String assunto, required String mensagem}) async {
    await tester.enterText(find.byType(TextField).at(0), assunto);
    await tester.enterText(find.byType(TextField).at(1), mensagem);
  }

  Finder botaoEnviar() => find.byType(ElevatedButton);

  testWidgets('não promete resposta por e-mail e mostra a lista vazia', (tester) async {
    await abrir(tester);

    expect(find.textContaining('e-mail'), findsNothing);
    expect(find.text('A resposta aparece aqui no app'), findsOneWidget);
    expect(find.text('Minhas mensagens'), findsOneWidget);
    expect(find.text('Você ainda não enviou mensagens ao RH'), findsOneWidget);
  });

  testWidgets('valida o assunto como a API e não envia', (tester) async {
    await abrir(tester);
    await preencher(tester, assunto: ' ab ', mensagem: 'Quero tirar férias em julho.');

    await tester.ensureVisible(botaoEnviar());
    await tester.tap(botaoEnviar());
    await tester.pump();

    expect(find.text('O assunto precisa ter pelo menos 3 caracteres.'), findsOneWidget);
    expect(api.contar('POST', _rotaEnviar), 0);
  });

  testWidgets('envia de verdade, trava o botão durante o envio e mostra a mensagem na lista', (tester) async {
    await abrir(tester);
    final resposta = Completer<http.Response>();
    api.responderCom('POST', _rotaEnviar, (_) => resposta.future);
    // O assunto é de uma linha; a mensagem mantém as quebras (no máximo 2
    // seguidas, \r\n vira \n).
    await preencher(
      tester,
      assunto: '  Férias   de julho ',
      mensagem: '  Bom dia,\r\n\r\n\r\nQuero tirar   férias\nem julho. \n',
    );

    await tester.ensureVisible(botaoEnviar());
    // Toque duplo: os dois chegam antes de o botão ser redesenhado.
    await tester.tap(botaoEnviar());
    await tester.tap(botaoEnviar());
    await tester.pump();

    expect(tester.widget<ElevatedButton>(botaoEnviar()).onPressed, isNull);
    expect(api.contar('POST', _rotaEnviar), 1);
    expect(api.ultimoCorpo('POST', _rotaEnviar), {
      'assunto': 'Férias de julho',
      'mensagem': 'Bom dia,\n\nQuero tirar férias\nem julho.',
    });

    api.responder('GET', _rotaMinhas, [_mensagemJson()]);
    resposta.complete(ApiFalsa.json(_mensagemJson(), status: 201));
    await tester.pumpAndSettle();

    expect(find.text('Mensagem enviada ao RH'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(botaoEnviar()).onPressed, isNotNull);
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, isEmpty);
    expect(find.text('Férias de julho'), findsOneWidget);
    expect(find.text('Aguardando resposta'), findsOneWidget);
    expect(find.text('Enviada em 18/11/2026 às 10:00'), findsOneWidget);
    await esperarToastSumir(tester);
  });

  testWidgets('falha no envio mostra o erro da API e mantém o texto', (tester) async {
    await abrir(tester);
    api.responder(
      'POST',
      _rotaEnviar,
      {'mensagem': 'Sua conta não está ligada a um cadastro de colaborador.'},
      status: 404,
    );
    await preencher(tester, assunto: 'Férias de julho', mensagem: 'Quero tirar férias em julho.');

    await tester.ensureVisible(botaoEnviar());
    await tester.tap(botaoEnviar());
    await tester.pumpAndSettle();

    expect(find.text('Sua conta não está ligada a um cadastro de colaborador.'), findsOneWidget);
    expect(find.text('Mensagem enviada ao RH'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, 'Férias de julho');
  });

  testWidgets('mensagem repetida (409) mostra o aviso do backend e não apaga o texto', (tester) async {
    await abrir(tester);
    const aviso = 'Você acabou de enviar essa mesma mensagem. Aguarde a resposta do RH.';
    api.responder('POST', _rotaEnviar, {'mensagem': aviso}, status: 409);
    await preencher(tester, assunto: 'Férias de julho', mensagem: 'Quero tirar\nférias em julho.');

    await tester.ensureVisible(botaoEnviar());
    await tester.tap(botaoEnviar());
    await tester.pumpAndSettle();

    expect(find.text(aviso), findsOneWidget);
    expect(find.text('Mensagem enviada ao RH'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, 'Férias de julho');
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text, 'Quero tirar\nférias em julho.');
    expect(tester.widget<ElevatedButton>(botaoEnviar()).onPressed, isNotNull);
  });

  testWidgets('aceita emoji no assunto e na mensagem', (tester) async {
    await abrir(tester);
    api.responder('POST', _rotaEnviar, _mensagemJson(), status: 201);
    final coracao = String.fromCharCodes([0x2764, 0xFE0F]);
    final familia = String.fromCharCodes([0x1F468, 0x200D, 0x1F469, 0x200D, 0x1F467]);
    await preencher(tester, assunto: 'Férias $coracao', mensagem: 'Obrigado! $familia');

    await tester.ensureVisible(botaoEnviar());
    await tester.tap(botaoEnviar());
    await tester.pumpAndSettle();

    expect(api.ultimoCorpo('POST', _rotaEnviar), {'assunto': 'Férias $coracao', 'mensagem': 'Obrigado! $familia'});
    await esperarToastSumir(tester);
  });

  testWidgets('mostra o status e a resposta do RH', (tester) async {
    api.responder('GET', _rotaMinhas, [
      _mensagemJson(
        status: 1,
        resposta: 'Pode tirar de 01 a 15/07.',
        responsavelNome: 'Rh Teste',
        respondidaEm: '2026-11-18T15:30:00Z',
      ),
    ]);
    await abrir(tester);

    expect(find.text('Respondida'), findsOneWidget);
    expect(find.text('Resposta do RH'), findsOneWidget);
    expect(find.text('Rh Teste · 18/11/2026 às 12:30'), findsOneWidget);
    expect(find.text('Pode tirar de 01 a 15/07.'), findsOneWidget);
  });

  testWidgets('erro ao carregar a lista oferece tentar de novo', (tester) async {
    api.responder('GET', _rotaMinhas, null, status: 500);
    await abrir(tester);

    expect(find.text(mensagemServidorIndisponivel), findsOneWidget);

    api.responder('GET', _rotaMinhas, [_mensagemJson()]);
    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Férias de julho'), findsOneWidget);
  });
}
