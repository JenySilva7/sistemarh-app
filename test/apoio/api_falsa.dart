import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// API de mentira pros testes: cada rota ("MÉTODO /caminho") devolve a
/// resposta configurada, e toda requisição recebida fica guardada em
/// [requisicoes]. Rota não configurada responde 404.
class ApiFalsa {
  final requisicoes = <http.Request>[];
  final _rotas = <String, FutureOr<http.Response> Function(http.Request)>{};

  late final MockClient cliente = MockClient((requisicao) async {
    requisicoes.add(requisicao);
    final rota = _rotas['${requisicao.method} ${requisicao.url.path}'];
    if (rota == null) return json({'mensagem': 'Rota não configurada no teste.'}, status: 404);
    return rota(requisicao);
  });

  /// Responde sempre com [corpo] em JSON e o [status] informado.
  void responder(String metodo, String caminho, Object? corpo, {int status = 200}) {
    _rotas['$metodo $caminho'] = (_) => json(corpo, status: status);
  }

  /// Responde com o que [resposta] devolver (pra respostas que mudam ou
  /// demoram, com um Completer).
  void responderCom(String metodo, String caminho, FutureOr<http.Response> Function(http.Request) resposta) {
    _rotas['$metodo $caminho'] = resposta;
  }

  /// Quantas requisições chegaram em "MÉTODO /caminho".
  int contar(String metodo, String caminho) =>
      requisicoes.where((r) => r.method == metodo && r.url.path == caminho).length;

  /// Corpo JSON da última requisição em "MÉTODO /caminho".
  Map<String, dynamic> ultimoCorpo(String metodo, String caminho) => jsonDecode(
    requisicoes.lastWhere((r) => r.method == metodo && r.url.path == caminho).body,
  ) as Map<String, dynamic>;

  static http.Response json(Object? corpo, {int status = 200}) => http.Response.bytes(
    corpo == null ? const [] : utf8.encode(jsonEncode(corpo)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
