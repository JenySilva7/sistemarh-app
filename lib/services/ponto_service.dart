import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ponto_controller.dart';
import 'api_config.dart';

const String _baseUrl = apiBaseUrl;

/// Erro "esperado" ao falar com /api/ponto (mensagem já pronta pra UI).
class PontoApiException implements Exception {
  final String mensagem;
  PontoApiException(this.mensagem);
}

/// Uma marcação de ponto, do jeito que a API devolve.
class RegistroPontoApi {
  final int id;
  final TipoRegistro tipo;
  final DateTime registradoEm;

  RegistroPontoApi({required this.id, required this.tipo, required this.registradoEm});

  factory RegistroPontoApi.fromJson(Map<String, dynamic> json) {
    return RegistroPontoApi(
      id: json['id'] as int,
      // A ordem do enum TipoRegistro (entrada, saidaAlmoco, voltaAlmoco,
      // saida) é a mesma de TipoRegistroPonto no backend (0..3) — dá pra
      // mapear direto pelo índice.
      tipo: TipoRegistro.values[json['tipo'] as int],
      registradoEm: DateTime.parse(json['registradoEm'] as String).toLocal(),
    );
  }
}

/// Fala com as rotas /api/ponto do backend.
class PontoService {
  Future<List<RegistroPontoApi>> listarDeHoje(String token) async {
    final corpo = await _request('GET', '/api/ponto/hoje', token);
    final lista = corpo as List<dynamic>;
    return lista.map((e) => RegistroPontoApi.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RegistroPontoApi> registrarProximo(String token) async {
    final corpo = await _request('POST', '/api/ponto', token) as Map<String, dynamic>;
    return RegistroPontoApi.fromJson(corpo['registro'] as Map<String, dynamic>);
  }

  Future<dynamic> _request(String metodo, String caminho, String token) async {
    http.Response resposta;
    try {
      final uri = Uri.parse('$_baseUrl$caminho');
      final headers = {'Authorization': 'Bearer $token'};
      resposta = await (metodo == 'GET' ? http.get(uri, headers: headers) : http.post(uri, headers: headers))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw PontoApiException('Não foi possível conectar ao servidor.');
    }

    final corpo = resposta.body.isEmpty ? null : jsonDecode(resposta.body);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return corpo;
    }

    final mensagem = (corpo is Map<String, dynamic>) ? corpo['mensagem'] as String? : null;
    throw PontoApiException(mensagem ?? 'Não foi possível registrar o ponto.');
  }
}
