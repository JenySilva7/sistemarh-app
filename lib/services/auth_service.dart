import '../utils/horario_brasilia.dart';
import 'api_client.dart';

/// Dados do usuário autenticado, exatamente como a API devolve.
class Sessao {
  final String token;
  final int id;
  final String nome;
  final String email;
  final String cargo;
  final String departamento;
  final int saldoBancoHorasMinutos;
  final int? funcionarioId;

  /// Data de calendário (sem fuso) — null se o RH ainda não informou.
  final DateTime? dataAdmissao;
  final String? gerenteNome;
  final int totalSolicitacoesAusencia;

  const Sessao({
    required this.token,
    required this.id,
    required this.nome,
    required this.email,
    required this.cargo,
    required this.departamento,
    required this.saldoBancoHorasMinutos,
    this.funcionarioId,
    this.dataAdmissao,
    this.gerenteNome,
    this.totalSolicitacoesAusencia = 0,
  });

  /// Monta a sessão a partir da resposta do login (`{ token, usuario }`).
  factory Sessao.fromJson(Map<String, dynamic> json) {
    return Sessao.fromUsuarioJson(json['token'] as String, json['usuario'] as Map<String, dynamic>);
  }

  /// Monta a sessão a partir da resposta de `GET /api/auth/me`, que devolve
  /// só os dados do usuário (sem token — por isso ele é passado à parte,
  /// vindo do token já salvo localmente).
  ///
  /// Os campos mais novos (funcionário, admissão, gerente) são lidos de forma
  /// tolerante: um servidor desatualizado pode simplesmente não mandá-los.
  factory Sessao.fromUsuarioJson(String token, Map<String, dynamic> json) {
    final funcionarioId = json['funcionarioId'];
    final gerenteNome = json['gerenteNome'];
    final totalAusencias = json['totalSolicitacoesAusencia'];
    return Sessao(
      token: token,
      id: json['id'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String,
      cargo: json['cargo'] as String? ?? '',
      departamento: json['departamento'] as String? ?? '',
      saldoBancoHorasMinutos: json['saldoBancoHorasMinutos'] as int? ?? 0,
      funcionarioId: funcionarioId is int ? funcionarioId : null,
      dataAdmissao: lerDataApi(json['dataAdmissao']),
      gerenteNome: gerenteNome is String && gerenteNome.trim().isNotEmpty ? gerenteNome.trim() : null,
      totalSolicitacoesAusencia: totalAusencias is int ? totalAusencias : 0,
    );
  }

  /// Iniciais pro avatar circular (ex.: "Ana Pereira" -> "AP").
  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }

  /// Formata o saldo em minutos como "+6h30" / "-12h15".
  String get bancoDeHorasFormatado {
    final sinal = saldoBancoHorasMinutos < 0 ? '-' : '+';
    final totalMinutos = saldoBancoHorasMinutos.abs();
    final horas = totalMinutos ~/ 60;
    final minutos = totalMinutos % 60;
    return '$sinal${horas}h${minutos.toString().padLeft(2, '0')}';
  }
}

/// Fala com as rotas /api/auth do backend. Erros chegam como [ApiException]
/// (ou [SessaoExpiradaException], no caso de [me] com token recusado).
class AuthService {
  final ApiClient _api = ApiClient();

  Future<Sessao> login({required String email, required String senha}) async {
    final corpo = await _api.post(
      '/api/auth/login',
      corpo: {'email': email, 'senha': senha},
      mensagemPadrao: 'Não foi possível entrar. Confira seus dados e tente novamente.',
    );
    return lerResposta(corpo, (json) => Sessao.fromJson(json as Map<String, dynamic>));
  }

  Future<Sessao> registrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final corpo = await _api.post(
      '/api/auth/register',
      corpo: {'nome': nome, 'email': email, 'senha': senha},
      mensagemPadrao: 'Não foi possível concluir o cadastro.',
    );
    return lerResposta(corpo, (json) => Sessao.fromJson(json as Map<String, dynamic>));
  }

  /// Rehidrata a sessão a partir de um token já salvo (ver [SessionStorage]),
  /// usado ao reabrir o app. Lança [SessaoExpiradaException] se o token não
  /// valer mais e [ApiException] (com o [ApiException.statusCode]) nos demais
  /// casos — quem chama decide se isso deve ou não apagar o token.
  Future<Sessao> me(String token) async {
    final corpo = await _api.get(
      '/api/auth/me',
      token: token,
      mensagemPadrao: 'Não foi possível validar sua sessão.',
    );
    return lerResposta(corpo, (json) => Sessao.fromUsuarioJson(token, json as Map<String, dynamic>));
  }
}
