import 'package:flutter_test/flutter_test.dart';

import 'package:app_sistema_final/models/carregamento_controller.dart';
import 'package:app_sistema_final/screens/my_data_screen.dart';
import 'package:app_sistema_final/services/api_client.dart';
import 'package:app_sistema_final/services/cadastro_service.dart';

import 'apoio/api_falsa.dart';
import 'apoio/tela.dart';

const _rota = '/api/me/cadastro';

void main() {
  late ApiFalsa api;
  late int saidas;
  late int trocasDeSenha;

  setUp(() {
    api = ApiFalsa();
    ApiClient.clientePadrao = api.cliente;
    saidas = 0;
    trocasDeSenha = 0;
  });

  tearDown(() => ApiClient.clientePadrao = null);

  Future<void> abrir(WidgetTester tester) async {
    usarTelaDeCelular(tester);
    final cadastro = CarregamentoController<CadastroColaborador>(() => CadastroService().obterMeu('t'));
    addTearDown(cadastro.dispose);
    await tester.pumpWidget(
      comoAba(
        MyDataScreen(
          sessao: sessaoDeTeste,
          cadastro: cadastro,
          onAlterarSenha: () => trocasDeSenha++,
          onSair: () => saidas++,
        ),
      ),
    );
    cadastro.recarregar();
    await tester.pumpAndSettle();
  }

  testWidgets('mostra CPF, telefone, nascimento, salário e VA do cadastro', (tester) async {
    api.responder('GET', _rota, {
      'id': 23,
      'nome': 'Zezinho Da Lima',
      'cpf': '12345678909',
      'email': 'zedalima00@gmail.com',
      'telefone': '(16) 99776-6554',
      'dataNascimento': '1990-05-10T00:00:00',
      'dataAdmissao': '2024-01-10T00:00:00',
      'status': 0,
      'departamentoNome': 'Tecnologia da Informação',
      'cargoNome': 'Analista de Sistemas',
      'salario': 7000.0,
      'valeAlimentacao': 600.0,
      'gerenteNome': 'Ana Silva',
      'versao': 3,
    });
    await abrir(tester);

    expect(find.text('123.456.789-09'), findsOneWidget);
    expect(find.text('(16) 99776-6554'), findsOneWidget);
    expect(find.text('10/05/1990'), findsOneWidget);
    expect(find.text('R\$ 7.000,00'), findsOneWidget);
    expect(find.text('R\$ 600,00'), findsOneWidget);
    // A sessão não trouxe admissão nem gestor: vêm do cadastro.
    expect(find.text('Na empresa desde 10/01/2024'), findsOneWidget);
    expect(find.text('Ana Silva'), findsOneWidget);
  });

  testWidgets('conta sem cadastro (404) não quebra: mostra o aviso e o que a sessão tem', (tester) async {
    api.responder('GET', _rota, {'mensagem': 'Sua conta não está ligada a um cadastro de colaborador.'}, status: 404);
    await abrir(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Sua conta não está ligada a um cadastro de colaborador.'), findsOneWidget);
    expect(find.text('zedalima00@gmail.com'), findsOneWidget);
    expect(find.text('CPF'), findsNothing);
    expect(find.text('Salário'), findsNothing);
    expect(find.text('Sair'), findsOneWidget);
  });

  testWidgets('o botão Sair chama o logout', (tester) async {
    api.responder('GET', _rota, null, status: 404);
    await abrir(tester);

    await tester.ensureVisible(find.text('Sair'));
    await tester.tap(find.text('Sair'));
    await tester.pump();

    expect(saidas, 1);
  });

  testWidgets('o botão Alterar senha abre a troca de senha', (tester) async {
    api.responder('GET', _rota, null, status: 404);
    await abrir(tester);

    await tester.ensureVisible(find.text('Alterar senha'));
    await tester.tap(find.text('Alterar senha'));
    await tester.pump();

    expect(trocasDeSenha, 1);
    expect(saidas, 0);
  });
}
