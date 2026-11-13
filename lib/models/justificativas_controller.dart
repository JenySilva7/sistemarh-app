import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/ausencia_service.dart';

/// Estado da lista "Minhas justificativas" do Início, vinda de
/// `GET /api/ausencias` (só as do próprio usuário, mais recentes primeiro).
class JustificativasController extends ChangeNotifier {
  JustificativasController({required this.token, this.onSessaoExpirada}) {
    recarregar();
  }

  final String token;
  final AusenciaService _service = AusenciaService();

  /// Chamado quando o servidor recusa o token.
  final VoidCallback? onSessaoExpirada;

  List<Justificativa> _itens = const [];
  bool _carregando = true;
  String? _erro;
  int _buscaAtual = 0;
  bool _descartado = false;

  List<Justificativa> get itens => _itens;
  bool get carregando => _carregando;
  String? get erro => _erro;

  Future<void> recarregar() async {
    final busca = ++_buscaAtual;
    _carregando = true;
    _erro = null;
    _notificar();

    List<Justificativa>? lista;
    String? erro;
    try {
      lista = await _service.listarMinhas(token);
    } on SessaoExpiradaException {
      onSessaoExpirada?.call();
      return;
    } on ApiException catch (e) {
      erro = e.mensagem;
    } catch (_) {
      erro = mensagemErroInesperado;
    }

    // Uma busca mais nova (ex.: logo após enviar outra justificativa) já
    // está a caminho — essa resposta pode estar desatualizada.
    if (busca != _buscaAtual) return;
    if (lista != null) _itens = lista;
    _erro = erro;
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
