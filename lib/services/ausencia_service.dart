import '../utils/horario_brasilia.dart';
import 'api_client.dart';

/// Mesma ordem do enum TipoAusencia no backend (0..3) e da tela de
/// justificar ausência.
enum TipoAusencia {
  atestadoMedico('Atestado médico'),
  faltaJustificada('Falta justificada'),
  esquecimentoDePonto('Esquecimento de ponto'),
  outro('Outro motivo');

  const TipoAusencia(this.rotulo);
  final String rotulo;
}

/// Mesma ordem do enum StatusAusencia no backend (0..3).
enum StatusJustificativa {
  enviada('Enviada'),
  emAnalise('Em análise'),
  aprovada('Aprovada'),
  recusada('Recusada');

  const StatusJustificativa(this.rotulo);
  final String rotulo;
}

/// Uma justificativa de ausência enviada pelo próprio colaborador.
class Justificativa {
  final int id;
  final TipoAusencia tipo;

  /// Data de calendário da ausência (sem fuso).
  final DateTime? data;
  final bool diaInteiro;
  final String descricao;

  /// Null se o servidor mandar um status que o app ainda não conhece.
  final StatusJustificativa? status;
  final DateTime? criadoEm;

  const Justificativa({
    required this.id,
    required this.tipo,
    required this.data,
    required this.diaInteiro,
    required this.descricao,
    required this.status,
    required this.criadoEm,
  });

  factory Justificativa.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo'];
    final status = json['status'];
    final criadoEm = json['criadoEm'];
    return Justificativa(
      id: json['id'] as int,
      tipo: tipo is int && tipo >= 0 && tipo < TipoAusencia.values.length
          ? TipoAusencia.values[tipo]
          : TipoAusencia.outro,
      data: lerDataApi(json['data']),
      diaInteiro: json['diaInteiro'] as bool? ?? true,
      descricao: json['descricao'] as String? ?? '',
      status: status is int && status >= 0 && status < StatusJustificativa.values.length
          ? StatusJustificativa.values[status]
          : null,
      criadoEm: criadoEm is String ? paraBrasilia(lerInstanteApi(criadoEm)) : null,
    );
  }
}

/// Fala com as rotas /api/ausencias do backend. Erros chegam como
/// [ApiException] (inclusive as validações que a API devolve com 400) ou
/// [SessaoExpiradaException].
class AusenciaService {
  final ApiClient _api = ApiClient();

  /// [tipo] é o índice 0..3 — mesma ordem da tela (Atestado médico, Falta
  /// justificada, Esquecimento de ponto, Outro motivo) e de [TipoAusencia].
  Future<void> criar({
    required String token,
    required int tipo,
    required DateTime data,
    required bool diaInteiro,
    required String descricao,
  }) async {
    await _api.post(
      '/api/ausencias',
      token: token,
      corpo: {
        'tipo': tipo,
        'data': data.toIso8601String(),
        'diaInteiro': diaInteiro,
        'descricao': descricao,
      },
      mensagemPadrao: 'Não foi possível enviar a justificativa.',
    );
  }

  /// Justificativas do próprio usuário, das mais recentes pras mais antigas.
  Future<List<Justificativa>> listarMinhas(String token) async {
    final corpo = await _api.get(
      '/api/ausencias',
      token: token,
      mensagemPadrao: 'Não foi possível carregar suas justificativas.',
    );
    return lerResposta(
      corpo,
      (json) => (json as List<dynamic>).map((e) => Justificativa.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
