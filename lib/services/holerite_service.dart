import '../utils/horario_brasilia.dart';
import 'api_client.dart';

/// Um holerite (folha de pagamento de um mês) do próprio colaborador, do
/// jeito que a API devolve.
class Holerite {
  final int id;

  /// Mês de referência no formato "AAAA-MM".
  final String competencia;
  final double salario;
  final double bonus;
  final double descontos;
  final double salarioLiquido;

  /// Data de calendário do pagamento — null se ainda não foi informada.
  final DateTime? dataPagamento;

  const Holerite({
    required this.id,
    required this.competencia,
    required this.salario,
    required this.bonus,
    required this.descontos,
    required this.salarioLiquido,
    this.dataPagamento,
  });

  /// Salário mais bônus, antes dos descontos.
  double get bruto => salario + bonus;

  factory Holerite.fromJson(Map<String, dynamic> json) {
    double valor(String campo) => (json[campo] as num?)?.toDouble() ?? 0;
    return Holerite(
      id: json['id'] as int,
      competencia: json['competencia'] as String? ?? '',
      salario: valor('salario'),
      bonus: valor('bonus'),
      descontos: valor('descontos'),
      salarioLiquido: valor('salarioLiquido'),
      dataPagamento: lerDataApi(json['dataPagamento']),
    );
  }
}

/// Fala com `GET /api/me/holerites`. Erros chegam como [ApiException] (um
/// 404 quer dizer que a conta não está ligada a um cadastro de colaborador)
/// ou [SessaoExpiradaException].
class HoleriteService {
  final ApiClient _api = ApiClient();

  /// Holerites do próprio colaborador, do mês mais recente pro mais antigo.
  Future<List<Holerite>> listarMeus(String token) async {
    final corpo = await _api.get(
      '/api/me/holerites',
      token: token,
      mensagemPadrao: 'Não foi possível carregar seus holerites.',
    );
    return lerResposta(
      corpo,
      (json) => (json as List<dynamic>).map((e) => Holerite.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
