import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

const mensagemSemConexao =
    'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.';
const mensagemServidorIndisponivel = 'O servidor está indisponível no momento. Tente novamente em instantes.';
const mensagemSessaoExpirada = 'Sua sessão foi encerrada. Entre novamente.';
const mensagemErroInesperado = 'Ocorreu um erro inesperado. Tente novamente.';

/// Erro ao falar com a API — a [mensagem] já vem pronta pra mostrar na tela.
/// [statusCode] é null quando nem chegou resposta do servidor.
class ApiException implements Exception {
  final String mensagem;
  final int? statusCode;

  ApiException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}

/// O servidor recusou o token (401) numa rota autenticada. A volta pro login
/// já é disparada pelo próprio [ApiClient] (ver [ApiClient.aoEncerrarSessao]);
/// quem recebe essa exceção só precisa parar o que estava fazendo, sem
/// mostrar erro na tela.
///
/// A [mensagem] é a que o backend mandou (ex.: "Seu acesso foi desativado.
/// Procure o RH." pra quem foi desligado), ou [mensagemSessaoExpirada] se
/// não veio nenhuma.
class SessaoExpiradaException extends ApiException {
  SessaoExpiradaException([String? mensagem])
    : super(mensagem == null || mensagem.trim().isEmpty ? mensagemSessaoExpirada : mensagem, statusCode: 401);
}

/// Cliente HTTP compartilhado pelos serviços. Centraliza o tratamento de
/// erro pra que nenhuma falha (sem internet, túnel fora do ar devolvendo
/// HTML, token expirado...) chegue na tela como exceção "crua".
class ApiClient {
  static const _timeoutPadrao = Duration(seconds: 15);

  /// Chamado sempre que uma rota autenticada responde 401: token expirado,
  /// logout feito em outro lugar, senha redefinida pelo RH, colaborador
  /// desligado... A casca do app (RootShell) registra aqui a volta pro
  /// login, então um 401 em qualquer chamada encerra a sessão, sem cada tela
  /// precisar repassar esse aviso. Recebe a mensagem pra mostrar no login
  /// (a do backend, ou [mensagemSessaoExpirada]).
  static void Function(String mensagem)? aoEncerrarSessao;

  /// Só pra testes: cliente HTTP usado no lugar da rede de verdade (ex.: um
  /// `MockClient` do pacote http).
  @visibleForTesting
  static http.Client? clientePadrao;

  Future<dynamic> get(String caminho, {String? token, required String mensagemPadrao}) =>
      _enviar('GET', caminho, token: token, mensagemPadrao: mensagemPadrao);

  Future<dynamic> post(
    String caminho, {
    String? token,
    Map<String, dynamic>? corpo,
    required String mensagemPadrao,
    Duration? timeout,
  }) => _enviar('POST', caminho, token: token, corpo: corpo, mensagemPadrao: mensagemPadrao, timeout: timeout);

  Future<dynamic> put(
    String caminho, {
    String? token,
    Map<String, dynamic>? corpo,
    required String mensagemPadrao,
  }) => _enviar('PUT', caminho, token: token, corpo: corpo, mensagemPadrao: mensagemPadrao);

  Future<dynamic> _enviar(
    String metodo,
    String caminho, {
    String? token,
    Map<String, dynamic>? corpo,
    required String mensagemPadrao,
    Duration? timeout,
  }) async {
    final requisicao = http.Request(metodo, Uri.parse('$apiBaseUrl$caminho'));
    requisicao.headers.addAll({
      'Accept': 'application/json',
      if (corpo != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (corpo != null) requisicao.body = jsonEncode(corpo);

    http.Response resposta;
    try {
      resposta = await _executar(requisicao, timeout ?? _timeoutPadrao);
    } catch (_) {
      throw ApiException(mensagemSemConexao);
    }

    final status = resposta.statusCode;
    final texto = utf8.decode(resposta.bodyBytes, allowMalformed: true);

    // Conferido antes da leitura "obrigatória" do JSON: o 401 pode vir sem
    // corpo (ou com um corpo que não é JSON) e mesmo assim encerra a sessão.
    if (status == 401 && token != null) {
      final sessaoEncerrada = SessaoExpiradaException(_mensagemDoCorpo(texto));
      aoEncerrarSessao?.call(sessaoEncerrada.mensagem);
      throw sessaoEncerrada;
    }

    // O túnel do Cloudflare responde 502/530 com uma página HTML quando o
    // backend está fora do ar.
    if (status >= 500) throw ApiException(mensagemServidorIndisponivel, statusCode: status);

    dynamic json;
    if (texto.trim().isNotEmpty) {
      try {
        json = jsonDecode(texto);
      } on FormatException {
        throw ApiException(mensagemServidorIndisponivel, statusCode: status);
      }
    }

    if (status >= 200 && status < 300) return json;

    final mensagem = json is Map<String, dynamic> ? json['mensagem'] : null;
    throw ApiException(
      mensagem is String && mensagem.trim().isNotEmpty ? mensagem : mensagemPadrao,
      statusCode: status,
    );
  }

  /// O campo `mensagem` de um corpo `{ "mensagem": "..." }`, ou null se o
  /// corpo vier vazio, não for JSON ou não tiver mensagem.
  static String? _mensagemDoCorpo(String texto) {
    if (texto.trim().isEmpty) return null;
    try {
      final json = jsonDecode(texto);
      final mensagem = json is Map<String, dynamic> ? json['mensagem'] : null;
      return mensagem is String && mensagem.trim().isNotEmpty ? mensagem.trim() : null;
    } on FormatException {
      return null;
    }
  }

  /// Envia a requisição e lê a resposta inteira dentro do [timeout]. O
  /// cliente criado aqui é fechado no fim (o que também derruba a conexão se
  /// o tempo estourar); o [clientePadrao] dos testes fica por conta deles.
  Future<http.Response> _executar(http.BaseRequest requisicao, Duration timeout) async {
    final injetado = clientePadrao;
    final cliente = injetado ?? http.Client();
    try {
      return await () async {
        final resposta = await cliente.send(requisicao);
        return http.Response.fromStream(resposta);
      }().timeout(timeout);
    } finally {
      if (injetado == null) cliente.close();
    }
  }
}

/// Converte o JSON de uma resposta de sucesso. Se o formato vier diferente
/// do esperado, vira [ApiException] em vez de um TypeError solto na tela.
T lerResposta<T>(dynamic json, T Function(dynamic json) conversor) {
  try {
    return conversor(json);
  } catch (_) {
    throw ApiException('Recebemos uma resposta inesperada do servidor. Tente novamente em instantes.');
  }
}
