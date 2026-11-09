import 'package:shared_preferences/shared_preferences.dart';

/// Guarda só o token de sessão no dispositivo, pra não precisar logar toda
/// vez que o app reabre. Os demais dados (nome, cargo, saldo etc.) são
/// sempre buscados de novo via `GET /api/auth/me` ao iniciar o app — assim
/// refletem qualquer mudança feita no servidor desde o último login, em vez
/// de confiar num retrato antigo guardado localmente.
class SessionStorage {
  static const _chaveToken = 'token_sessao';

  Future<void> salvarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveToken, token);
  }

  Future<String?> lerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveToken);
  }

  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveToken);
  }
}
