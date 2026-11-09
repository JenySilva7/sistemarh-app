import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ponto_service.dart';

/// As 4 marcações do dia (entrada, saída pro almoço, volta do almoço,
/// saída final). O rótulo exibido é sempre só "Entrada" ou "Saída" —
/// [TipoRegistroLabel.titulo] alterna entre os dois, sem nomear o almoço.
enum TipoRegistro { entrada, saidaAlmoco, voltaAlmoco, saida }

extension TipoRegistroLabel on TipoRegistro {
  bool get isEntrada => this == TipoRegistro.entrada || this == TipoRegistro.voltaAlmoco;

  String get titulo => isEntrada ? 'Entrada' : 'Saída';

  String get acaoBotao => isEntrada ? 'Registrar entrada' : 'Registrar saída';
}

/// Controla o estado do ponto do dia: horário de cada uma das 4 marcações
/// (entrada, saída/volta do almoço, saída final) e o status do expediente.
///
/// Os registros vêm de verdade do backend (`GET /api/ponto/hoje` ao criar o
/// controller, `POST /api/ponto` ao registrar) — não existe mais estado
/// "mockado" nem a possibilidade de desfazer um registro: uma vez batido o
/// ponto, o horário é definitivo (reflete como ponto eletrônico funciona na
/// vida real, e é assim que o backend trata isso também).
class PontoController extends ChangeNotifier {
  PontoController({required String token}) : _token = token {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    _carregarDeHoje();
  }

  static const escalaInicio = TimeOfDay(hour: 8, minute: 0);
  static const escalaFim = TimeOfDay(hour: 17, minute: 0);
  static const metaMinutos = 8 * 60;

  final String _token;
  final PontoService _service = PontoService();

  final Map<TipoRegistro, DateTime?> _registros = {
    TipoRegistro.entrada: null,
    TipoRegistro.saidaAlmoco: null,
    TipoRegistro.voltaAlmoco: null,
    TipoRegistro.saida: null,
  };

  Timer? _timer;
  bool _carregando = true;
  String? _erroCarregamento;

  /// true enquanto a busca inicial dos registros de hoje ainda não terminou.
  bool get carregando => _carregando;

  /// Mensagem de erro da busca inicial, se ela falhar (ex.: backend fora do
  /// ar) — o usuário ainda consegue tentar registrar, que vai falhar com o
  /// próprio erro de conexão nessa hora.
  String? get erroCarregamento => _erroCarregamento;

  DateTime? registroDe(TipoRegistro tipo) => _registros[tipo];

  /// Próximo registro pendente, ou null se a jornada já foi concluída.
  TipoRegistro? get proximo {
    for (final tipo in TipoRegistro.values) {
      if (_registros[tipo] == null) return tipo;
    }
    return null;
  }

  bool get jornadaConcluida => proximo == null;

  bool get emAlmoco =>
      _registros[TipoRegistro.saidaAlmoco] != null && _registros[TipoRegistro.voltaAlmoco] == null;

  String get statusLabel {
    if (jornadaConcluida) return 'Expediente encerrado';
    if (emAlmoco) return 'Em intervalo';
    if (_registros[TipoRegistro.entrada] == null) return 'Fora do expediente';
    return 'Em expediente';
  }

  TipoRegistro? get ultimoRegistrado {
    TipoRegistro? ultimo;
    for (final tipo in TipoRegistro.values) {
      if (_registros[tipo] != null) ultimo = tipo;
    }
    return ultimo;
  }

  /// Minutos trabalhados até agora (ou até a saída, se já registrada),
  /// descontando o intervalo de almoço.
  int get minutosTrabalhados {
    final entrada = _registros[TipoRegistro.entrada];
    if (entrada == null) return 0;
    final fim = _registros[TipoRegistro.saida] ?? DateTime.now();
    var total = fim.difference(entrada).inSeconds / 60.0;

    final saidaAlmoco = _registros[TipoRegistro.saidaAlmoco];
    final voltaAlmoco = _registros[TipoRegistro.voltaAlmoco];
    if (saidaAlmoco != null) {
      final fimAlmoco = voltaAlmoco ?? DateTime.now();
      if (fimAlmoco.isAfter(saidaAlmoco)) {
        total -= fimAlmoco.difference(saidaAlmoco).inSeconds / 60.0;
      }
    }
    return total.clamp(0, 24 * 60).round();
  }

  double get progresso => (minutosTrabalhados / metaMinutos).clamp(0.0, 1.0);

  String get trabalhadoHojeLabel => _formatHoras(minutosTrabalhados);

  String get metaLabel => _formatHoras(metaMinutos);

  static String _formatHoras(int minutos) {
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  Future<void> _carregarDeHoje() async {
    try {
      final registros = await _service.listarDeHoje(_token);
      for (final r in registros) {
        _registros[r.tipo] = r.registradoEm;
      }
      _erroCarregamento = null;
    } on PontoApiException catch (e) {
      _erroCarregamento = e.mensagem;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Registra o próximo ponto pendente contra a API e retorna uma mensagem
  /// de toast, ou null se a jornada já estava concluída. Lança
  /// [PontoApiException] em caso de erro — quem chama decide como mostrar.
  Future<String?> registrarProximo() async {
    if (proximo == null) return null;
    final registro = await _service.registrarProximo(_token);
    _registros[registro.tipo] = registro.registradoEm;
    final hora = TimeOfDay.fromDateTime(registro.registradoEm).format24();
    final dia = _diaSemanaCurto(registro.registradoEm.weekday);
    final msg = registro.tipo == TipoRegistro.saida
        ? 'Saída às $hora · $dia'
        : '${registro.tipo.titulo} registrada às $hora';
    notifyListeners();
    return msg;
  }

  String get ultimoRegistroLabel {
    final tipo = ultimoRegistrado;
    if (tipo == null) return 'Nenhum registro ainda hoje';
    final hora = TimeOfDay.fromDateTime(_registros[tipo]!).format24();
    return 'Último registro: ${tipo.titulo.toLowerCase()} às $hora';
  }

  static String _diaSemanaCurto(int weekday) {
    const dias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
    return dias[weekday - 1];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

extension on TimeOfDay {
  String format24() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
