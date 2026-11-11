/// Brasil não observa mais horário de verão desde 2019 — Brasília é sempre
/// UTC-3 —, então um offset fixo é suficiente aqui e garante que o relógio
/// do ponto nunca dependa do fuso horário (ou do relógio) configurado no
/// aparelho do colaborador.
const _offsetBrasilia = Duration(hours: -3);

/// Horário atual em Brasília, independente do fuso configurado no aparelho.
DateTime agoraBrasilia() => DateTime.now().toUtc().add(_offsetBrasilia);

/// Converte um instante (em qualquer fuso) para o horário de Brasília.
DateTime paraBrasilia(DateTime data) => data.toUtc().add(_offsetBrasilia);
