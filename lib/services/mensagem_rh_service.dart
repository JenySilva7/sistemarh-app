import '../utils/horario_brasilia.dart';
import 'api_client.dart';

/// Mesma ordem do enum de status da mensagem no backend (0..1).
enum StatusMensagemRh {
  aberta('Aguardando resposta'),
  respondida('Respondida');

  const StatusMensagemRh(this.rotulo);
  final String rotulo;
}

/// Uma mensagem que o colaborador mandou pro RH pelo "Falar com RH", com a
/// resposta, quando houver. A resposta só aparece aqui no app — não vai por
/// e-mail.
class MensagemRh {
  final int id;
  final String assunto;
  final String mensagem;

  /// Null se o servidor mandar um status que o app ainda não conhece.
  final StatusMensagemRh? status;
  final String? resposta;
  final String? responsavelNome;

  /// Instantes já convertidos pro horário de Brasília.
  final DateTime? criadoEm;
  final DateTime? respondidaEm;

  const MensagemRh({
    required this.id,
    required this.assunto,
    required this.mensagem,
    required this.status,
    this.resposta,
    this.responsavelNome,
    this.criadoEm,
    this.respondidaEm,
  });

  bool get respondida => status == StatusMensagemRh.respondida;

  factory MensagemRh.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final resposta = json['resposta'];
    final responsavel = json['responsavelNome'];
    final criadoEm = json['criadoEm'];
    final respondidaEm = json['respondidaEm'];
    return MensagemRh(
      id: json['id'] as int,
      assunto: json['assunto'] as String? ?? '',
      mensagem: json['mensagem'] as String? ?? '',
      status: status is int && status >= 0 && status < StatusMensagemRh.values.length
          ? StatusMensagemRh.values[status]
          : null,
      resposta: resposta is String && resposta.trim().isNotEmpty ? resposta : null,
      responsavelNome: responsavel is String && responsavel.trim().isNotEmpty ? responsavel.trim() : null,
      criadoEm: criadoEm is String ? paraBrasilia(lerInstanteApi(criadoEm)) : null,
      respondidaEm: respondidaEm is String ? paraBrasilia(lerInstanteApi(respondidaEm)) : null,
    );
  }
}

/// Fala com as rotas /api/mensagens-rh do backend. Erros chegam como
/// [ApiException] (inclusive as validações que a API devolve com 400) ou
/// [SessaoExpiradaException].
class MensagemRhService {
  final ApiClient _api = ApiClient();

  /// [assunto] e [mensagem] já devem vir limpos (`limparTexto`, que na
  /// mensagem mantém as quebras de linha) e validados
  /// (`validarAssuntoMensagemRh` e `validarTextoMensagemRh`).
  Future<MensagemRh> enviar({required String token, required String assunto, required String mensagem}) async {
    final corpo = await _api.post(
      '/api/mensagens-rh',
      token: token,
      corpo: {'assunto': assunto, 'mensagem': mensagem},
      mensagemPadrao: 'Não foi possível enviar sua mensagem ao RH.',
    );
    return lerResposta(corpo, (json) => MensagemRh.fromJson(json as Map<String, dynamic>));
  }

  /// Mensagens do próprio usuário, das mais novas pras mais antigas.
  Future<List<MensagemRh>> listarMinhas(String token) async {
    final corpo = await _api.get(
      '/api/mensagens-rh/minhas',
      token: token,
      mensagemPadrao: 'Não foi possível carregar suas mensagens.',
    );
    return lerResposta(
      corpo,
      (json) => (json as List<dynamic>).map((e) => MensagemRh.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
