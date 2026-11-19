import 'package:flutter_test/flutter_test.dart';

import 'package:app_sistema_final/utils/formatters.dart';

void main() {
  test('formatarMoeda usa o padrão brasileiro', () {
    expect(formatarMoeda(0), 'R\$ 0,00');
    expect(formatarMoeda(5), 'R\$ 5,00');
    expect(formatarMoeda(1234.5), 'R\$ 1.234,50');
    expect(formatarMoeda(7000), 'R\$ 7.000,00');
    expect(formatarMoeda(1000000), 'R\$ 1.000.000,00');
    expect(formatarMoeda(999.999), 'R\$ 1.000,00');
    expect(formatarMoeda(-49000), '-R\$ 49.000,00');
  });

  test('formatarCompetencia', () {
    expect(formatarCompetencia('2026-08'), 'Agosto 2026');
    expect(formatarCompetencia('2025-12'), 'Dezembro 2025');
    expect(formatarCompetencia('2026-03'), 'Março 2026');
    expect(formatarCompetencia('2026-13'), '2026-13');
    expect(formatarCompetencia('banana'), 'banana');
  });

  test('formatarCpf', () {
    expect(formatarCpf('12345678909'), '123.456.789-09');
    expect(formatarCpf('123.456.789-09'), '123.456.789-09');
    expect(formatarCpf('123'), '123');
  });
}
