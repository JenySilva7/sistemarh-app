/// Brasil não observa mais horário de verão desde 2019 — Brasília é sempre
/// UTC-3 —, então um offset fixo é suficiente aqui e garante que o relógio
/// do ponto nunca dependa do fuso horário (ou do relógio) configurado no
/// aparelho do colaborador.
const _offsetBrasilia = Duration(hours: -3);

/// Horário atual em Brasília, independente do fuso configurado no aparelho.
DateTime agoraBrasilia() => DateTime.now().toUtc().add(_offsetBrasilia);

/// Converte um instante (em qualquer fuso) para o horário de Brasília.
DateTime paraBrasilia(DateTime data) => data.toUtc().add(_offsetBrasilia);

final _designadorDeFuso = RegExp(r'([Zz]|[+-]\d{2}(:?\d{2})?)$');

/// Lê um instante devolvido pela API (ex.: `registradoEm`, `criadoEm`).
/// O backend grava tudo em UTC, mas algumas rotas mandam o texto sem o 'Z'
/// — e o `DateTime.parse` trataria isso como horário local do aparelho.
/// Por isso, sem designador de fuso, o texto é lido como UTC.
DateTime lerInstanteApi(String valor) {
  var texto = valor.trim();
  final inicioHora = texto.indexOf(RegExp('[Tt ]'));
  if (inicioHora < 0) {
    texto = '${texto}T00:00:00Z';
  } else if (!_designadorDeFuso.hasMatch(texto.substring(inicioHora + 1))) {
    texto = '${texto}Z';
  }
  return DateTime.parse(texto).toUtc();
}

/// Lê uma data "de calendário" da API (data da ausência, data de admissão),
/// que vem como "2026-11-13T00:00:00". Só o yyyy-MM-dd importa: converter
/// fuso aqui poderia jogar a data pro dia anterior. Null se vier vazia ou
/// num formato desconhecido.
DateTime? lerDataApi(Object? valor) {
  if (valor is! String) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(valor.trim());
  if (m == null) return null;
  return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}
