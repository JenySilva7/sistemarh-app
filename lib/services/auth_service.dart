import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

const String _baseUrl = apiBaseUrl;

/// Dados do usuário autenticado, exatamente como a API devolve.
class Sessao {
  final String token;
  final int id;
  final String nome;
  final String email;
  final String cargo;
  final String departamento;
  final int saldoBancoHorasMinutos;

  const Sessao({
    required this.token,
    required this.id,
    required this.nome,
    required this.email,
    required this.cargo,
    required this.departamento,
    required this.saldoBancoHorasMinutos,
  });

  factory Sessao.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>;
    return Sessao(
      token: json['token'] as String,
      id: usuario['id'] as int,
      nome: usuario['nome'] as String,
      email: usuario['email'] as String,
      cargo: usuario['cargo'] as String? ?? '',
      departamento: usuario['departamento'] as String? ?? '',
      saldoBancoHorasMinutos: usuario['saldoBancoHorasMinutos'] as int? ?? 0,
    );
  }

  /// Monta a sessão a partir da resposta de `GET /api/auth/me`, que devolve
  /// só os dados do usuário (sem token — por isso ele é passado à parte,
  /// vindo do token já salvo localmente).
  factory Sessao.fromUsuarioJson(String token, Map<String, dynamic> json) {
    return Sessao(
      token: token,
      id: json['id'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String,
      cargo: json['cargo'] as String? ?? '',
      departamento: json['departamento'] as String? ?? '',
      saldoBancoHorasMinutos: json['saldoBancoHorasMinutos'] as int? ?? 0,
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

/// Erro "esperado" de autenticação (credenciais inválidas, e-mail já
/// cadastrado, etc.) — a [mensagem] já vem pronta pra mostrar na tela.
class AuthException implements Exception {
  final String mensagem;
  AuthException(this.mensagem);
}

/// Fala com as rotas /api/auth do backend.
class AuthService {
  Future<Sessao> login({required String email, required String senha}) async {
    final resposta = await _post('/api/auth/login', {'email': email, 'senha': senha});
    return Sessao.fromJson(resposta);
  }

  Future<Sessao> registrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final resposta = await _post('/api/auth/register', {
      'nome': nome,
      'email': email,
      'senha': senha,
    });
    return Sessao.fromJson(resposta);
  }

  /// Rehidrata a sessão a partir de um token já salvo (ver [SessionStorage]),
  /// usado ao reabrir o app. Lança [AuthException] se o token não for mais
  /// válido (expirado, por exemplo) ou se não for possível falar com o servidor.
  Future<Sessao> me(String token) async {
    http.Response resposta;
    try {
      resposta = await http
          .get(
            Uri.parse('$_baseUrl/api/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw AuthException('Não foi possível conectar ao servidor. Verifique se o backend está rodando.');
    }

    final json = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return Sessao.fromUsuarioJson(token, json);
    }

    throw AuthException(json['mensagem'] as String? ?? 'Sessão expirada.');
  }

  Future<Map<String, dynamic>> _post(String caminho, Map<String, dynamic> corpo) async {
    http.Response resposta;
    try {
      resposta = await http
          .post(
            Uri.parse('$_baseUrl$caminho'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(corpo),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw AuthException('Não foi possível conectar ao servidor. Verifique se o backend está rodando.');
    }

    final json = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return json;
    }

    throw AuthException(json['mensagem'] as String? ?? 'Ocorreu um erro inesperado.');
  }
}
