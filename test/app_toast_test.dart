import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_sistema_final/widgets/app_toast.dart';

import 'apoio/tela.dart';

void main() {
  testWidgets('toast sem ação não bloqueia o toque no que está embaixo dele', (tester) async {
    var toques = 0;
    late BuildContext contexto;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              contexto = context;
              // Botão no topo, onde o toast aparece.
              return Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: ElevatedButton(onPressed: () => toques++, child: const Text('Registrar saída')),
                ),
              );
            },
          ),
        ),
      ),
    );

    AppToast.show(contexto, title: 'Entrada registrada', description: 'Entrada registrada às 08:00');
    await tester.pumpAndSettle();
    expect(find.text('Entrada registrada'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.text('Registrar saída')));
    await tester.pump();
    expect(toques, 1);

    await esperarToastSumir(tester);
  });
}
