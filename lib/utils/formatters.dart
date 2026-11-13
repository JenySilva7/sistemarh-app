/// Formata uma data como dd/mm/aaaa.
String formatarData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Formata uma hora como HH:mm.
String formatarHora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

const _diasDaSemana = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// Formata uma data por extenso, ex.: "Sexta-feira, 13 de novembro".
String formatarDataPorExtenso(DateTime d) => '${_diasDaSemana[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]}';

/// Tempo de casa entre a admissão e [hoje] (ambas datas de calendário):
/// "6 anos", "1 ano", "8 meses", "1 mês" ou "Menos de 1 mês".
String formatarTempoDeCasa(DateTime admissao, DateTime hoje) {
  var meses = (hoje.year - admissao.year) * 12 + hoje.month - admissao.month;
  if (hoje.day < admissao.day) meses--;
  if (meses < 1) return 'Menos de 1 mês';
  if (meses < 12) return meses == 1 ? '1 mês' : '$meses meses';
  final anos = meses ~/ 12;
  return anos == 1 ? '1 ano' : '$anos anos';
}
