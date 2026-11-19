import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:app_sistema_final/services/api_client.dart';
import 'package:app_sistema_final/services/api_config.dart';

import 'apoio/api_falsa.dart';

void main() {
  late ApiFalsa api;

  setUp(() {
    api = ApiFalsa();
    ApiClient.clientePadrao = api.cliente;
  });

  tearDown(() {
    ApiClient.clientePadrao = null;
    ApiClient.aoEncerrarSessao = null;
  });

  test('sem --dart-define, aponta pro backend publicado', () {
    if (const bool.hasEnvironment('API_BASE_URL')) return;
    expect(apiBaseUrl, 'https://backend-production-b0a758c2.up.railway.app');
  });

  test('401 sem corpo encerra a sessão com o texto padrão', () async {
    final avisos = <String>[];
    ApiClient.aoEncerrarSessao = avisos.add;
    api.responder('GET', '/api/ponto/hoje', null, status: 401);

    await expectLater(
      ApiClient().get('/api/ponto/hoje', token: 't', mensagemPadrao: 'x'),
      throwsA(
        isA<SessaoExpiradaException>().having((e) => e.mensagem, 'mensagem', 'Sua sessão foi encerrada. Entre novamente.'),
      ),
    );
    expect(avisos, ['Sua sessão foi encerrada. Entre novamente.']);
  });

  test('401 com {mensagem} encerra a sessão mostrando o motivo do backend', () async {
    final avisos = <String>[];
    ApiClient.aoEncerrarSessao = avisos.add;
    api.responder('POST', '/api/ponto', {'mensagem': 'Seu acesso foi desativado. Procure o RH.'}, status: 401);

    await expectLater(
      ApiClient().post('/api/ponto', token: 't', mensagemPadrao: 'x'),
      throwsA(
        isA<SessaoExpiradaException>().having((e) => e.mensagem, 'mensagem', 'Seu acesso foi desativado. Procure o RH.'),
      ),
    );
    expect(avisos, ['Seu acesso foi desativado. Procure o RH.']);
  });

  test('401 com corpo que não é JSON usa o texto padrão', () async {
    final avisos = <String>[];
    ApiClient.aoEncerrarSessao = avisos.add;
    api.responderCom('GET', '/api/ausencias', (_) => http.Response('<html>401</html>', 401));

    await expectLater(
      ApiClient().get('/api/ausencias', token: 't', mensagemPadrao: 'x'),
      throwsA(isA<SessaoExpiradaException>()),
    );
    expect(avisos, [mensagemSessaoExpirada]);
  });

  test('401 sem token (login) não encerra sessão e mostra a mensagem da API', () async {
    final avisos = <String>[];
    ApiClient.aoEncerrarSessao = avisos.add;
    api.responder('POST', '/api/auth/login', {'mensagem': 'E-mail ou senha incorretos.'}, status: 401);

    await expectLater(
      ApiClient().post('/api/auth/login', corpo: {}, mensagemPadrao: 'x'),
      throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', 'E-mail ou senha incorretos.')),
    );
    expect(avisos, isEmpty);
  });

  test('erro com {mensagem} usa o texto do backend; sem ele, o padrão', () async {
    api.responder('POST', '/api/ponto', {'mensagem': 'Aguarde 1 minuto entre registros de ponto.'}, status: 400);
    api.responder('GET', '/api/me/cadastro', null, status: 403);

    await expectLater(
      ApiClient().post('/api/ponto', token: 't', mensagemPadrao: 'padrão'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.mensagem, 'mensagem', 'Aguarde 1 minuto entre registros de ponto.')
            .having((e) => e.statusCode, 'statusCode', 400),
      ),
    );
    await expectLater(
      ApiClient().get('/api/me/cadastro', token: 't', mensagemPadrao: 'padrão'),
      throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', 'padrão')),
    );
  });

  test('500 vira "servidor indisponível"', () async {
    api.responder('GET', '/api/ausencias', {'mensagem': 'detalhe interno'}, status: 500);

    await expectLater(
      ApiClient().get('/api/ausencias', token: 't', mensagemPadrao: 'x'),
      throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', mensagemServidorIndisponivel)),
    );
  });

  test('envia JSON e o token', () async {
    api.responder('POST', '/api/mensagens-rh', {'id': 1}, status: 201);

    await ApiClient().post('/api/mensagens-rh', token: 'abc', corpo: {'assunto': 'Férias'}, mensagemPadrao: 'x');

    final requisicao = api.requisicoes.single;
    expect(requisicao.headers['Authorization'], 'Bearer abc');
    expect(requisicao.headers['Content-Type'], startsWith('application/json'));
    expect(api.ultimoCorpo('POST', '/api/mensagens-rh'), {'assunto': 'Férias'});
  });
}
