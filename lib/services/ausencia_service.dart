import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

const String _baseUrl = apiBaseUrl;

/// Erro "esperado" ao falar com /api/ausencias (mensagem já pronta pra UI,
/// inclusive as de validação que a API devolve com 400).
class AusenciaApiException implements Exception {
  final String mensagem;
  AusenciaApiException(this.mensagem);
}

/// Fala com as rotas /api/ausencias do backend.
class AusenciaService {
  /// [tipo] é o índice 0..3 — mesma ordem da tela (Atestado médico, Falta
  /// justificada, Esquecimento de ponto, Outro motivo) e do enum
  /// TipoAusencia no backend (AtestadoMedico, FaltaJustificada,
  /// EsquecimentoDePonto, Outro).
  Future<void> criar({
    required String token,
    required int tipo,
    required DateTime data,
    required bool diaInteiro,
    required String descricao,
  }) async {
    http.Response resposta;
    try {
      resposta = await http
          .post(
            Uri.parse('$_baseUrl/api/ausencias'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'tipo': tipo,
              'data': data.toIso8601String(),
              'diaInteiro': diaInteiro,
              'descricao': descricao,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw AusenciaApiException('Não foi possível conectar ao servidor.');
    }

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return;

    final corpo = resposta.body.isEmpty ? null : jsonDecode(resposta.body) as Map<String, dynamic>?;
    throw AusenciaApiException(corpo?['mensagem'] as String? ?? 'Não foi possível enviar a justificativa.');
  }
}
