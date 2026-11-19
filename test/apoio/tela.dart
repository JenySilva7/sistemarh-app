import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_sistema_final/services/auth_service.dart';

/// Tela alta (900 x 2000) pros testes de widget, em vez dos 800 x 600
/// padrão, pra caber a tela inteira sem rolar. É larga porque a fonte dos
/// testes desenha cada letra como um quadrado, bem mais largo que a Inter.
void usarTelaDeCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Monta [tela] dentro de um MaterialApp + Scaffold, como as abas do app.
Widget comoAba(Widget tela) => MaterialApp(home: Scaffold(body: tela));

/// Sessão de um colaborador ligado a um cadastro, pros testes.
const sessaoDeTeste = Sessao(
  token: 'token-de-teste',
  id: 8,
  nome: 'Zezinho Da Lima',
  email: 'zedalima00@gmail.com',
  cargo: 'Analista de Sistemas',
  departamento: 'Tecnologia da Informação',
  saldoBancoHorasMinutos: 90,
  funcionarioId: 23,
);

/// Deixa o toast (que some sozinho depois de 4 s) terminar, pra não sobrar
/// timer pendente no fim do teste.
Future<void> esperarToastSumir(WidgetTester tester) async {
  // Primeiro a animação de entrada termina (só então o toast agenda a
  // saída), depois passam os 4 s e a animação de saída roda.
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}
