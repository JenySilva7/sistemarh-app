// Smoke test: garante que o app sobe sem lançar exceções e, sem sessão
// salva, abre na tela de login.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_sistema_final/main.dart';

void main() {
  testWidgets('App sobe e abre no login quando não há sessão salva', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SistemaRhApp());
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });
}
