import 'package:flutter_test/flutter_test.dart';

import 'package:app_sistema_final/utils/formatters.dart';
import 'package:app_sistema_final/utils/horario_brasilia.dart';

void main() {
  group('lerInstanteApi', () {
    test('texto sem fuso é lido como UTC', () {
      final instante = lerInstanteApi('2026-11-13T15:50:51.568748');
      expect(instante, DateTime.utc(2026, 11, 13, 15, 50, 51, 568, 748));
      expect(paraBrasilia(instante).hour, 12);
    });

    test('respeita Z e offsets explícitos', () {
      expect(lerInstanteApi('2026-11-13T15:50:51Z'), DateTime.utc(2026, 11, 13, 15, 50, 51));
      expect(lerInstanteApi('2026-11-13T15:50:51+00:00'), DateTime.utc(2026, 11, 13, 15, 50, 51));
      expect(lerInstanteApi('2026-11-13T12:50:51-03:00'), DateTime.utc(2026, 11, 13, 15, 50, 51));
    });
  });

  group('lerDataApi', () {
    test('usa só o yyyy-MM-dd, sem mexer no fuso', () {
      expect(lerDataApi('2026-11-13T00:00:00'), DateTime(2026, 11, 13));
      expect(lerDataApi('2026-11-13T00:00:00Z'), DateTime(2026, 11, 13));
    });

    test('devolve null pra valores ausentes ou inválidos', () {
      expect(lerDataApi(null), isNull);
      expect(lerDataApi(''), isNull);
      expect(lerDataApi(42), isNull);
    });
  });

  test('formatarDataPorExtenso', () {
    expect(formatarDataPorExtenso(DateTime(2026, 11, 13)), 'Sexta-feira, 13 de novembro');
    expect(formatarDataPorExtenso(DateTime(2026, 3, 1)), 'Domingo, 1 de março');
  });

  test('formatarTempoDeCasa', () {
    final hoje = DateTime(2026, 11, 13);
    expect(formatarTempoDeCasa(DateTime(2020, 6, 1), hoje), '6 anos');
    expect(formatarTempoDeCasa(DateTime(2025, 11, 13), hoje), '1 ano');
    expect(formatarTempoDeCasa(DateTime(2025, 11, 14), hoje), '11 meses');
    expect(formatarTempoDeCasa(DateTime(2026, 3, 1), hoje), '8 meses');
    expect(formatarTempoDeCasa(DateTime(2026, 10, 13), hoje), '1 mês');
    expect(formatarTempoDeCasa(DateTime(2026, 10, 20), hoje), 'Menos de 1 mês');
  });
}
