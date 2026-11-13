import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

const mensagemSemConexao =
    'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.';
const mensagemServidorIndisponivel = 'O servidor está indisponível no momento. Tente novamente em instantes.';
const mensagemSessaoExpirada = 'Sua sessão expirou. Faça login novamente.';
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

/// O servidor recusou o token (401) numa rota autenticada: quem pega isso
/// deve limpar a sessão salva e mandar o usuário de volta pro login.
class SessaoExpiradaException extends ApiException {
  SessaoExpiradaException() : super(mensagemSessaoExpirada, statusCode: 401);
}

/// Cliente HTTP compartilhado pelos serviços. Centraliza o tratamento de
/// erro pra que nenhuma falha (sem internet, túnel fora do ar devolvendo
/// HTML, token expirado...) chegue na tela como exceção "crua".
class ApiClient {
  static const _timeout = Duration(seconds: 15);

  Future<dynamic> get(String caminho, {String? token, required String mensagemPadrao}) =>
      _enviar('GET', caminho, token: token, mensagemPadrao: mensagemPadrao);

  Future<dynamic> post(
    String caminho, {
    String? token,
    Map<String, dynamic>? corpo,
    required String mensagemPadrao,
  }) => _enviar('POST', caminho, token: token, corpo: corpo, mensagemPadrao: mensagemPadrao);

  Future<dynamic> _enviar(
    String metodo,
    String caminho, {
    String? token,
    Map<String, dynamic>? corpo,
    required String mensagemPadrao,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$caminho');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (corpo != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response resposta;
    try {
      final requisicao = metodo == 'GET'
          ? http.get(uri, headers: headers)
          : http.post(uri, headers: headers, body: corpo == null ? null : jsonEncode(corpo));
      resposta = await requisicao.timeout(_timeout);
    } catch (_) {
      throw ApiException(mensagemSemConexao);
    }

    final status = resposta.statusCode;
    // O túnel do Cloudflare responde 502/530 com uma página HTML quando o
    // backend está fora do ar.
    if (status >= 500) throw ApiException(mensagemServidorIndisponivel, statusCode: status);

    final texto = utf8.decode(resposta.bodyBytes, allowMalformed: true);
    dynamic json;
    if (texto.trim().isNotEmpty) {
      try {
        json = jsonDecode(texto);
      } on FormatException {
        throw ApiException(mensagemServidorIndisponivel, statusCode: status);
      }
    }

    if (status >= 200 && status < 300) return json;
    if (status == 401 && token != null) throw SessaoExpiradaException();

    final mensagem = json is Map<String, dynamic> ? json['mensagem'] : null;
    throw ApiException(
      mensagem is String && mensagem.trim().isNotEmpty ? mensagem : mensagemPadrao,
      statusCode: status,
    );
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
