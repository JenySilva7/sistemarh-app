import '../utils/horario_brasilia.dart';
import 'api_client.dart';

/// Cadastro de colaborador ligado à conta logada, como o RH preencheu no
/// painel (`GET /api/me/cadastro`). Só os campos que o app mostra.
class CadastroColaborador {
  final String nome;
  final String cpf;
  final String? email;
  final String? telefone;

  /// Datas de calendário (sem fuso).
  final DateTime? dataNascimento;
  final DateTime? dataAdmissao;
  final String cargo;
  final String departamento;
  final String? gerenteNome;
  final double salario;
  final double valeAlimentacao;

  const CadastroColaborador({
    required this.nome,
    required this.cpf,
    this.email,
    this.telefone,
    this.dataNascimento,
    this.dataAdmissao,
    this.cargo = '',
    this.departamento = '',
    this.gerenteNome,
    this.salario = 0,
    this.valeAlimentacao = 0,
  });

  factory CadastroColaborador.fromJson(Map<String, dynamic> json) {
    String? texto(String campo) {
      final valor = json[campo];
      return valor is String && valor.trim().isNotEmpty ? valor.trim() : null;
    }

    return CadastroColaborador(
      nome: texto('nome') ?? '',
      cpf: texto('cpf') ?? '',
      email: texto('email'),
      telefone: texto('telefone'),
      dataNascimento: lerDataApi(json['dataNascimento']),
      dataAdmissao: lerDataApi(json['dataAdmissao']),
      cargo: texto('cargoNome') ?? '',
      departamento: texto('departamentoNome') ?? '',
      gerenteNome: texto('gerenteNome'),
      salario: (json['salario'] as num?)?.toDouble() ?? 0,
      valeAlimentacao: (json['valeAlimentacao'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Fala com `GET /api/me/cadastro`. Erros chegam como [ApiException] (um
/// 404 quer dizer que a conta não está ligada a um cadastro de colaborador)
/// ou [SessaoExpiradaException].
class CadastroService {
  final ApiClient _api = ApiClient();

  Future<CadastroColaborador> obterMeu(String token) async {
    final corpo = await _api.get(
      '/api/me/cadastro',
      token: token,
      mensagemPadrao: 'Não foi possível carregar seus dados.',
    );
    return lerResposta(corpo, (json) => CadastroColaborador.fromJson(json as Map<String, dynamic>));
  }
}
