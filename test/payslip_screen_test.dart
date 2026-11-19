import 'package:flutter_test/flutter_test.dart';

import 'package:app_sistema_final/models/carregamento_controller.dart';
import 'package:app_sistema_final/screens/payslip_screen.dart';
import 'package:app_sistema_final/services/api_client.dart';
import 'package:app_sistema_final/services/holerite_service.dart';

import 'apoio/api_falsa.dart';
import 'apoio/tela.dart';

const _rota = '/api/me/holerites';

void main() {
  late ApiFalsa api;

  setUp(() {
    api = ApiFalsa();
    ApiClient.clientePadrao = api.cliente;
  });

  tearDown(() => ApiClient.clientePadrao = null);

  Future<void> abrir(WidgetTester tester) async {
    usarTelaDeCelular(tester);
    final holerites = CarregamentoController<List<Holerite>>(() => HoleriteService().listarMeus('t'));
    addTearDown(holerites.dispose);
    await tester.pumpWidget(comoAba(PayslipScreen(initials: 'ZL', holerites: holerites)));
    holerites.recarregar();
    await tester.pumpAndSettle();
  }

  testWidgets('sem holerite lançado mostra o estado vazio, sem valores inventados', (tester) async {
    api.responder('GET', _rota, []);
    await abrir(tester);

    expect(api.contar('GET', _rota), 1);
    expect(find.text('Nenhum holerite disponível'), findsOneWidget);
    expect(find.textContaining('R\$'), findsNothing);
    expect(find.text('JS'), findsNothing);
    expect(find.text('ZL'), findsOneWidget);
  });

  testWidgets('mostra os holerites da API, do mais recente pro mais antigo', (tester) async {
    api.responder('GET', _rota, [
      {
        'id': 2,
        'funcionarioId': 23,
        'competencia': '2026-10',
        'salario': 4321.5,
        'bonus': 100,
        'descontos': 654.25,
        'salarioLiquido': 3767.25,
        'dataPagamento': '2026-11-05T00:00:00',
      },
      {
        'id': 1,
        'funcionarioId': 23,
        'competencia': '2026-09',
        'salario': 4321.5,
        'bonus': 0,
        'descontos': 600,
        'salarioLiquido': 3721.5,
        'dataPagamento': null,
      },
    ]);
    await abrir(tester);

    // O líquido do último aparece no destaque e no card do mês.
    expect(find.text('R\$ 3.767,25'), findsNWidgets(2));
    expect(find.text('Outubro 2026'), findsNWidgets(2));
    expect(find.text('R\$ 4.421,50'), findsOneWidget);
    expect(find.text('R\$ 654,25'), findsOneWidget);
    expect(find.text('Inclui bônus de R\$ 100,00 · Pago em 05/11/2026'), findsOneWidget);
    expect(find.text('Setembro 2026'), findsOneWidget);
    expect(find.text('R\$ 3.721,50'), findsOneWidget);
    expect(find.text('R\$ 12.000,00'), findsNothing);
  });

  testWidgets('conta sem cadastro (404) mostra o aviso da API', (tester) async {
    api.responder('GET', _rota, {'mensagem': 'Sua conta não está ligada a um cadastro de colaborador.'}, status: 404);
    await abrir(tester);

    expect(find.text('Holerite indisponível'), findsOneWidget);
    expect(find.text('Sua conta não está ligada a um cadastro de colaborador.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
  });

  testWidgets('erro de conexão oferece tentar de novo', (tester) async {
    api.responder('GET', _rota, null, status: 502);
    await abrir(tester);

    expect(find.text('Não foi possível carregar'), findsOneWidget);
    api.responder('GET', _rota, []);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum holerite disponível'), findsOneWidget);
  });
}
