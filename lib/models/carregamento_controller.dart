import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

/// Estado de uma consulta simples à API (holerites, cadastro, mensagens ao
/// RH): os dados da última busca que deu certo e o erro da última que falhou.
///
/// Quem é dono do controller (o RootShell) decide quando buscar: na primeira
/// vez que a aba é aberta e, depois, de novo a cada vez que ela é aberta —
/// sem apagar o que já está na tela enquanto a busca nova não chega.
class CarregamentoController<T> extends ChangeNotifier {
  CarregamentoController(this._buscar);

  final Future<T> Function() _buscar;

  T? _dados;
  ApiException? _falha;
  bool _carregando = false;
  int _buscaAtual = 0;
  bool _descartado = false;

  /// Resultado da última busca que deu certo (null se nenhuma deu ainda).
  T? get dados => _dados;

  /// Erro da última busca, se ela falhou. Um 404 (conta sem cadastro de
  /// colaborador, por exemplo) apaga os [dados], porque eles não valem mais.
  ApiException? get falha => _falha;

  bool get carregando => _carregando;

  Future<void> recarregar() async {
    final busca = ++_buscaAtual;
    _carregando = true;
    _notificar();

    T? dados;
    ApiException? falha;
    try {
      dados = await _buscar();
    } on SessaoExpiradaException {
      // O ApiClient já está levando de volta pro login.
      if (busca == _buscaAtual) _carregando = false;
      return;
    } on ApiException catch (e) {
      falha = e;
    } catch (_) {
      falha = ApiException(mensagemErroInesperado);
    }

    // Uma busca mais nova já está a caminho: esta pode estar desatualizada.
    if (busca != _buscaAtual) return;
    if (falha == null) {
      _dados = dados;
    } else if (falha.statusCode == 404) {
      _dados = null;
    }
    _falha = falha;
    _carregando = false;
    _notificar();
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
