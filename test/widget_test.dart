// Smoke test: garante que o app sobe e mostra a tela de Início (Ponto)
// sem lançar exceções.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_sistema_final/main.dart';

void main() {
  testWidgets('App sobe e mostra o card do relógio na tela Início', (tester) async {
    await tester.pumpWidget(const SistemaRhApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bom dia, João'), findsOneWidget);
    expect(find.text('Registros de hoje'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
  });
}
