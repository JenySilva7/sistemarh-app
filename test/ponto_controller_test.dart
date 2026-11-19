import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:app_sistema_final/models/ponto_controller.dart';
import 'package:app_sistema_final/services/api_client.dart';

import 'apoio/api_falsa.dart';

void main() {
  late ApiFalsa api;
  late PontoController ponto;

  setUp(() async {
    api = ApiFalsa();
    ApiClient.clientePadrao = api.cliente;
    api.responder('GET', '/api/ponto/hoje', []);
    ponto = PontoController(token: 't');
    await pumpEventQueue();
  });

  tearDown(() {
    ponto.dispose();
    ApiClient.clientePadrao = null;
  });

  test('toque duplo envia um registro só', () async {
    final resposta = Completer<http.Response>();
    api.responderCom('POST', '/api/ponto', (_) => resposta.future);

    final primeiro = ponto.registrarProximo();
    final segundo = ponto.registrarProximo();
    expect(ponto.registrando, isTrue);
    expect(await segundo, isNull);

    resposta.complete(
      ApiFalsa.json({
        'registro': {'id': 1, 'tipo': 0, 'registradoEm': '2026-11-18T11:00:00Z'},
        'proximo': 1,
      }, status: 201),
    );
    expect(await primeiro, 'Entrada registrada às 08:00');
    expect(api.contar('POST', '/api/ponto'), 1);
    expect(ponto.registrando, isFalse);
    expect(ponto.proximo, TipoRegistro.saidaAlmoco);
  });

  test('400 do intervalo de 1 minuto chega com a mensagem do backend e destrava o botão', () async {
    api.responder('POST', '/api/ponto', {'mensagem': 'Aguarde 1 minuto entre registros de ponto.'}, status: 400);

    await expectLater(
      ponto.registrarProximo(),
      throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', 'Aguarde 1 minuto entre registros de ponto.')),
    );
    expect(ponto.registrando, isFalse);
    expect(ponto.proximo, TipoRegistro.entrada);
  });
}
