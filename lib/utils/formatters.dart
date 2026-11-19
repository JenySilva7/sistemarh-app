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

/// Mês de referência de um holerite: "2026-08" -> "Agosto 2026". Se vier
/// fora do formato AAAA-MM, devolve o texto como veio.
String formatarCompetencia(String competencia) {
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(competencia.trim());
  final mes = m == null ? 0 : int.parse(m[2]!);
  if (mes < 1 || mes > 12) return competencia;
  final nome = _meses[mes - 1];
  return '${nome[0].toUpperCase()}${nome.substring(1)} ${m![1]}';
}

/// Valor em reais no padrão brasileiro: 1234.5 -> "R$ 1.234,50".
String formatarMoeda(num valor) {
  final centavos = (valor * 100).round();
  final inteiro = (centavos.abs() ~/ 100).toString();
  final milhares = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) milhares.write('.');
    milhares.write(inteiro[i]);
  }
  final resto = (centavos.abs() % 100).toString().padLeft(2, '0');
  return '${centavos < 0 ? '-' : ''}R\$ $milhares,$resto';
}

/// CPF com máscara (000.000.000-00) quando tiver 11 dígitos; se não, como veio.
String formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf.trim();
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.${digitos.substring(6, 9)}-${digitos.substring(9)}';
}

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
