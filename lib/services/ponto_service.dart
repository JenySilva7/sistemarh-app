import '../models/ponto_controller.dart';
import '../utils/horario_brasilia.dart';
import 'api_client.dart';

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
      registradoEm: paraBrasilia(lerInstanteApi(json['registradoEm'] as String)),
    );
  }
}

/// Fala com as rotas /api/ponto do backend. Erros chegam como [ApiException]
/// ou [SessaoExpiradaException].
class PontoService {
  final ApiClient _api = ApiClient();

  Future<List<RegistroPontoApi>> listarDeHoje(String token) async {
    final corpo = await _api.get(
      '/api/ponto/hoje',
      token: token,
      mensagemPadrao: 'Não foi possível carregar os registros de hoje.',
    );
    return lerResposta(
      corpo,
      (json) => (json as List<dynamic>).map((e) => RegistroPontoApi.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<RegistroPontoApi> registrarProximo(String token) async {
    final corpo = await _api.post(
      '/api/ponto',
      token: token,
      mensagemPadrao: 'Não foi possível registrar o ponto.',
    );
    return lerResposta(
      corpo,
      (json) => RegistroPontoApi.fromJson((json as Map<String, dynamic>)['registro'] as Map<String, dynamic>),
    );
  }
}
