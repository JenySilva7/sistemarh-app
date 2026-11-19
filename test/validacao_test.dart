import 'package:flutter_test/flutter_test.dart';

import 'package:app_sistema_final/utils/validacao.dart';

// Os casos de emoji, de code point sem caractere e de senha são os mesmos dos
// testes da API (SistemaRH.Api.Tests: EmojiTests.cs e TerceiraRodadaTests.cs),
// pra o app e a API concordarem. Caracteres invisíveis e emoji são montados
// pelo code point, pra não ficarem escondidos dentro dos textos do teste.
String _u(List<int> codePoints) => String.fromCharCodes(codePoints);

const _fe0f = 0xFE0F;
const _zwj = 0x200D;
const _keycap = 0x20E3;
const _bandeira = 0x1F3F4;
const _fimTags = 0xE007F;

const _regrasComEmoji = [regraTextoMensagemRh, regraDescricaoAusencia, regraAssuntoMensagemRh];

String _invisivel(RegraTexto regra) => '${regra.rotulo} contém caracteres invisíveis ou de controle, que não são permitidos.';

final _nbsp = _u([0x00A0]);

/// Sequências de emoji de verdade (TerceiraRodadaTests.EmojiValidos e
/// EmojiTests), com o nome de cada uma pra mensagem de falha.
final _emojiValidos = <String, String>{
  'coração': _u([0x2764, _fe0f]),
  'joinha com tom de pele': _u([0x1F44D, 0x1F3FD]),
  'família com ZWJ': _u([0x1F468, _zwj, 0x1F469, _zwj, 0x1F467]),
  'bandeira arco-íris': _u([0x1F3F3, _fe0f, _zwj, 0x1F308]),
  'bandeira pirata': _u([_bandeira, _zwj, 0x2620, _fe0f]),
  'bandeira da Inglaterra (tags)': _u([_bandeira, 0xE0067, 0xE0062, 0xE0065, 0xE006E, 0xE0067, _fimTags]),
  'bandeira da Escócia (tags)': _u([_bandeira, 0xE0067, 0xE0062, 0xE0073, 0xE0063, 0xE0074, _fimTags]),
  'tecla 1': _u([0x31, _fe0f, _keycap]),
  'tecla #': _u([0x23, _fe0f, _keycap]),
  'tecla * sem seletor': _u([0x2A, _keycap]),
  'copyright': _u([0x00A9, _fe0f]),
  'trade mark': _u([0x2122, _fe0f]),
  'seta de voltar': _u([0x21A9, _fe0f]),
  'seta para cima e à direita': _u([0x2934, _fe0f]),
  'seta para cima': _u([0x2B06, _fe0f]),
  'play': _u([0x25B6, _fe0f]),
  'linha ondulada': _u([0x3030, _fe0f]),
  'seta dupla em forma de texto': _u([0x2194, 0xFE0E]),
  'pessoa no computador com tom': _u([0x1F469, 0x1F3FD, _zwj, 0x1F4BB]),
  'pessoas de mãos dadas com tons': _u([0x1F9D1, 0x1F3FB, _zwj, 0x1F91D, _zwj, 0x1F9D1, 0x1F3FF]),
  'rosto soltando o ar': _u([0x1F62E, _zwj, 0x1F4A8]),
  'emoji do Unicode 16': _u([0x1FAE9]),
  'M em círculo': _u([0x24C2, _fe0f]),
  'quadrado pequeno': _u([0x25AA, _fe0f]),
  'quadrado médio': _u([0x25FB, _fe0f]),
};

/// Partes de emoji fora de uma sequência (TerceiraRodadaTests.PartesForaDeLugar).
final _partesForaDeLugar = <String, String>{
  'seletor depois de letra': _u([0x61, _fe0f]),
  '1 letra + 2 seletores': _u([0x61, _fe0f, _fe0f]),
  'dois seletores na mesma base': _u([0x2764, _fe0f, _fe0f]),
  'seletor de texto + de emoji': _u([0x4F, 0x69, 0x2764, 0xFE0E, _fe0f]),
  'ZWJ entre letras': 'Apro${_u([_zwj])}vado',
  'ZWJ antes de letra': _u([0x1F600, _zwj, 0x61]),
  'ZWJ depois de letra': _u([0x61, _zwj, 0x1F600]),
  'ZWJ antes de tom de pele': _u([0x1F44D, _zwj, 0x1F3FD]),
  'ZWJ seguido de ZWJ': _u([0x1F600, _zwj, _zwj, 0x1F600]),
  'tom depois de letra': _u([0x61, 0x1F3FD]),
  'dois tons': _u([0x1F44D, 0x1F3FD, 0x1F3FD]),
  'tom no keycap': _u([0x31, 0x1F3FD]),
  'keycap depois de letra': _u([0x61, _keycap]),
  'seletor depois do keycap': _u([0x31, _keycap, _fe0f]),
  'texto escondido em tags': 'Oi${_u([0xE0049, 0xE0047, 0xE004E, 0xE004F, 0xE0052, 0xE0045])} tudo bem',
  'tags depois de outra bandeira': _u([0x1F3F3, 0xE0067, 0xE0062, _fimTags]),
  'tags depois do seletor': _u([_bandeira, _fe0f, 0xE0067, 0xE0062, _fimTags]),
  'fim das tags sem tag': _u([_bandeira, _fimTags]),
  '9 tags': _u([_bandeira, 0xE0067, 0xE0062, 0xE0073, 0xE0063, 0xE0074, 0xE0067, 0xE0062, 0xE0073, 0xE0063, _fimTags]),
  'tags que não fecham': '${_u([_bandeira, 0xE0067, 0xE0062])} oi',
  'tags no fim do texto, sem fechar': _u([_bandeira, 0xE0067, 0xE0062]),
};

/// Partes de emoji isoladas ou no começo (EmojiTests.ParteDeEmojiIsoladaOuNoComeco_EhRecusada).
final _partesIsoladas = <String, String>{
  'seletor sozinho': _u([_fe0f]),
  'seletor depois de espaço': 'Oi ${_u([_fe0f])}',
  'seletor depois de quebra de linha': 'Oi\n${_u([_fe0f])} tudo',
  'ZWJ no fim': 'a${_u([_zwj])}',
  'texto só de ZWJ': _u([_zwj, _zwj, _zwj]),
  'ZWJ no começo': '${_u([_zwj])}abc',
  'ZWJ entre espaços': 'Oi ${_u([_zwj])} tudo',
  'ZWJ seguido de ZWJ': 'a${_u([_zwj, _zwj])}b',
  'tom de pele no começo': '${_u([0x1F3FD])} oi',
  'tag de bandeira solta': 'oi ${_u([0xE0067])}',
  'zero-width space': 'oi${_u([0x200B])}',
};

/// Code points sem caractere (Cn) e não-caracteres (TerceiraRodadaTests).
const _semCaractere = [
  0x2065, 0xFFF0, 0xFFF8, 0xE0080, 0xE00FF, 0xE01F0, 0xE0FFF, //
  0xFDD0, 0xFFFE, 0xFFFF, 0x1FFFF, 0x10FFFF,
];

void main() {
  group('emoji nos textos longos e no assunto', () {
    test('sequências de verdade são aceitas', () {
      for (final MapEntry(key: nome, value: emoji) in _emojiValidos.entries) {
        for (final regra in _regrasComEmoji) {
          expect(validarTexto('Oi $emoji', regra), isNull, reason: '$nome em ${regra.rotulo}');
          expect(validarTexto('Ok$emoji$emoji', regra), isNull, reason: '$nome repetido em ${regra.rotulo}');
        }
        expect(
          limparTexto('Linha 1 $emoji\r\nLinha 2', regraTextoMensagemRh),
          'Linha 1 $emoji\nLinha 2',
          reason: nome,
        );
      }
    });

    test('partes fora de uma sequência são recusadas', () {
      for (final MapEntry(key: nome, value: texto) in _partesForaDeLugar.entries) {
        for (final regra in _regrasComEmoji) {
          expect(validarTexto('Mensagem $texto', regra), _invisivel(regra), reason: '$nome em ${regra.rotulo}');
        }
      }
    });

    test('partes isoladas, no começo, depois de espaço ou de quebra são recusadas', () {
      for (final MapEntry(key: nome, value: texto) in _partesIsoladas.entries) {
        for (final regra in _regrasComEmoji) {
          expect(validarTexto(texto, regra), _invisivel(regra), reason: '$nome em ${regra.rotulo}');
        }
      }
    });

    test('mil e tantos seletores depois de "Oi" são recusados', () {
      final texto = 'Oi${_u([_fe0f]) * 1998}';
      expect(validarTextoMensagemRh(texto), _invisivel(regraTextoMensagemRh));
    });

    test('no máximo 10 ZWJ por sequência e 8 tags por bandeira', () {
      final rosto = _u([0x1F600]);
      final dezZwj = List.filled(11, rosto).join(_u([_zwj]));
      final onzeZwj = List.filled(12, rosto).join(_u([_zwj]));
      final oitoTags = _u([_bandeira, 0xE0061, 0xE0062, 0xE0063, 0xE0064, 0xE0065, 0xE0066, 0xE0067, 0xE0068, _fimTags]);

      expect(validarTextoMensagemRh(dezZwj), isNull);
      expect(validarTextoMensagemRh('Oi $oitoTags'), isNull);
      expect(validarTextoMensagemRh(onzeZwj), _invisivel(regraTextoMensagemRh));
      // Duas sequências de 10 separadas por espaço: cada uma tem a sua conta.
      expect(validarTextoMensagemRh('$dezZwj $dezZwj'), isNull);
    });

    test('campo de uma linha: quebra de linha e tab são recusados, não trocados por espaço', () {
      expect(validarAssuntoMensagemRh('Férias\nde julho'), _invisivel(regraAssuntoMensagemRh));
      expect(validarAssuntoMensagemRh('Férias\tde julho'), _invisivel(regraAssuntoMensagemRh));
    });

    test('texto longo: tab continua recusado', () {
      expect(validarTextoMensagemRh('Bom dia,\tRH'), _invisivel(regraTextoMensagemRh));
    });
  });

  group('tamanho por code point: o mínimo não conta partes de emoji, o máximo conta tudo', () {
    final joinha = _u([0x1F44D]);
    final coracao = _u([0x2764, _fe0f]);

    test('emoji fora do BMP conta como 1 caractere', () {
      // 99 letras + joinha = 100 caracteres (101 unidades UTF-16): cabe no assunto.
      expect(validarAssuntoMensagemRh('${'a' * 99}$joinha'), isNull);
      expect(validarAssuntoMensagemRh('${'a' * 100}$joinha'), 'O assunto pode ter no máximo 100 caracteres.');
    });

    test('dois emoji não atingem o mínimo de 3; três atingem', () {
      expect(validarAssuntoMensagemRh(joinha * 2), 'O assunto precisa ter pelo menos 3 caracteres.');
      expect(validarAssuntoMensagemRh(joinha * 3), isNull);
    });

    test('o mínimo não conta tom de pele nem seletor', () {
      // 4 code points, 2 caracteres na tela.
      expect(
        validarAssuntoMensagemRh(_u([0x1F44D, 0x1F3FD, 0x1F44D, 0x1F3FD])),
        'O assunto precisa ter pelo menos 3 caracteres.',
      );
      expect(validarAssuntoMensagemRh(coracao * 3), isNull);
      expect(validarAssuntoMensagemRh(coracao * 2), 'O assunto precisa ter pelo menos 3 caracteres.');
    });

    test('o máximo conta todos os code points', () {
      // 50 corações = 100 code points: cabe; com mais uma letra, não.
      expect(validarAssuntoMensagemRh(coracao * 50), isNull);
      expect(validarAssuntoMensagemRh('${coracao * 50}a'), 'O assunto pode ter no máximo 100 caracteres.');
    });
  });

  group('code points sem caractere (Cn) e não-caracteres', () {
    test('são recusados em todos os textos e na senha', () {
      for (final codigo in _semCaractere) {
        final invisivel = _u([codigo]);
        final rotulo = codigo.toRadixString(16);
        for (final regra in _regrasComEmoji) {
          expect(validarTexto('Mensagem$invisivel', regra), _invisivel(regra), reason: '$rotulo em ${regra.rotulo}');
        }
        expect(validarSenha('senha${invisivel}123'), mensagemSenhaComEmojiOuInvisivel, reason: rotulo);
      }
    });
  });

  group('brancos invisíveis que não são Cc/Cf', () {
    test('são recusados nos textos longos e no assunto', () {
      const brancos = [
        0x3164, 0xFFA0, 0x115F, 0x1160, 0x2800, 0x034F, 0x17B4, 0x17B5, //
        0xFE00, 0xFE0D, 0xE0100, 0xE01EF, 0x180B, 0x180E, 0x180F, 0x2028, 0x2029,
      ];
      for (final codigo in brancos) {
        final branco = _u([codigo]);
        final rotulo = codigo.toRadixString(16);
        expect(validarTextoMensagemRh('Bom${branco}dia'), _invisivel(regraTextoMensagemRh), reason: rotulo);
        expect(validarAssuntoMensagemRh('Fé${branco}rias'), _invisivel(regraAssuntoMensagemRh), reason: rotulo);
        expect(validarDescricaoAusencia(branco * 5), _invisivel(regraDescricaoAusencia), reason: rotulo);
      }
    });
  });

  group('limpeza', () {
    test('campo de uma linha: junta espaços (inclusive NBSP) e apara as pontas', () {
      expect(limparTexto('  Férias   de julho ', regraAssuntoMensagemRh), 'Férias de julho');
      expect(limparTexto('a$_nbsp${_nbsp}b', regraAssuntoMensagemRh), 'a b');
      expect(limparTexto('   ', regraAssuntoMensagemRh), '');
    });

    test('texto longo: mantém as quebras e normaliza \\r\\n e \\r pra \\n', () {
      expect(limparTexto('linha 1\nlinha 2', regraTextoMensagemRh), 'linha 1\nlinha 2');
      expect(limparTexto('linha 1\r\nlinha 2\rlinha 3', regraTextoMensagemRh), 'linha 1\nlinha 2\nlinha 3');
    });

    test('texto longo: apara cada linha e reduz as quebras seguidas a no máximo 2', () {
      expect(limparTexto('a\n\n\n\n\nb', regraTextoMensagemRh), 'a\n\nb');
      expect(limparTexto('a\r\n\r\n\r\nb', regraTextoMensagemRh), 'a\n\nb');
      expect(limparTexto('a\n \n \n \nb', regraTextoMensagemRh), 'a\n\nb');
      expect(limparTexto('  \n Bom   dia,  RH \n  boa  tarde\n\n  ', regraTextoMensagemRh), 'Bom dia, RH\nboa tarde');
    });
  });

  group('assunto, mensagem e descrição', () {
    test('limites de tamanho', () {
      expect(validarAssuntoMensagemRh('abc'), isNull);
      expect(validarAssuntoMensagemRh('a' * 100), isNull);
      expect(validarAssuntoMensagemRh('a' * 101), 'O assunto pode ter no máximo 100 caracteres.');
      expect(validarAssuntoMensagemRh('  a  '), 'O assunto precisa ter pelo menos 3 caracteres.');
      expect(validarTextoMensagemRh('a' * 2000), isNull);
      expect(validarTextoMensagemRh('a' * 2001), 'A mensagem pode ter no máximo 2000 caracteres.');
      expect(validarDescricaoAusencia('a' * 2001), 'A descrição pode ter no máximo 2000 caracteres.');
      // As quebras que ficam contam no máximo: 1999 letras + 1 quebra = 2000.
      expect(validarTextoMensagemRh('${'a' * 1000}\n${'a' * 999}'), isNull);
      expect(validarTextoMensagemRh('${'a' * 1000}\n\n\n${'a' * 999}'), 'A mensagem pode ter no máximo 2000 caracteres.');
    });

    test('vazio ou sem caractere visível', () {
      expect(validarAssuntoMensagemRh(''), 'Informe o assunto da mensagem.');
      expect(validarAssuntoMensagemRh('   '), 'Informe o assunto da mensagem.');
      expect(validarTextoMensagemRh(' \n\n  \n'), 'Escreva a mensagem.');
      expect(validarDescricaoAusencia(''), 'Descreva o motivo da ausência.');
    });

    test('quebra de linha é aceita nos textos longos', () {
      expect(validarTextoMensagemRh('Bom dia,\n\nquero tirar férias.'), isNull);
      expect(validarDescricaoAusencia('Consulta médica.\r\nAtestado entregue ao RH.'), isNull);
    });
  });

  group('senha (Senhas.Validar)', () {
    test('emoji ou invisível tem mensagem própria', () {
      final casos = [
        'Abc${_u([0x2764, _fe0f])}123', // coração com o seletor que o teclado põe
        'Abc${_u([0x2764])}123', // coração sem seletor
        'senha${_u([0x1F600])}1',
        'abc${_u([0x200B])}def',
        'abc${_u([_zwj])}def',
        'senha${_u([0x00A9])}12', // copyright também é base de emoji
      ];
      for (final senha in casos) {
        expect(validarSenha(senha, rotulo: 'A senha provisória'), mensagemSenhaComEmojiOuInvisivel, reason: senha.runes.toString());
      }
    });

    test('tamanho de 6 a 64 caracteres de verdade', () {
      expect(validarSenha('', rotulo: 'A nova senha'), 'A nova senha precisa ter pelo menos 6 caracteres.');
      expect(validarSenha('12345', rotulo: 'A nova senha'), 'A nova senha precisa ter pelo menos 6 caracteres.');
      expect(validarSenha('123456', rotulo: 'A nova senha'), isNull);
      expect(validarSenha('a' * 64, rotulo: 'A nova senha'), isNull);
      expect(validarSenha('a' * 65, rotulo: 'A nova senha'), 'A nova senha pode ter no máximo 64 caracteres.');
      // Acento e letra fora do BMP contam 1 cada.
      expect(validarSenha('Pão123'), isNull);
    });

    test('espaços: nunca só espaços, nunca nas pontas', () {
      expect(validarSenha('      ', rotulo: 'A nova senha'), 'A nova senha não pode ser formada só por espaços.');
      expect(validarSenha(' senha1', rotulo: 'A nova senha'), 'A nova senha não pode começar nem terminar com espaço.');
      expect(validarSenha('senha1 ', rotulo: 'A nova senha'), 'A nova senha não pode começar nem terminar com espaço.');
      expect(validarSenha('minha senha', rotulo: 'A nova senha'), isNull);
    });

    test('troca de senha: mesma ordem e mensagens da API', () {
      String? trocar(String atual, String nova, [String? confirmacao]) =>
          validarTrocaDeSenha(senhaAtual: atual, novaSenha: nova, confirmacao: confirmacao ?? nova);

      expect(trocar('', 'outra123'), 'Informe a senha atual.');
      expect(trocar('senha123', '123'), 'A nova senha precisa ter pelo menos 6 caracteres.');
      expect(trocar('senha123', 'senha123'), 'A nova senha precisa ser diferente da atual.');
      expect(trocar('senha123', 'Abc${_u([0x2764, _fe0f])}123'), mensagemSenhaComEmojiOuInvisivel);
      expect(trocar('senha123', 'outra123', 'outra124'), 'A confirmação não é igual à nova senha.');
      expect(trocar('senha123', 'outra123'), isNull);
    });
  });

  group('data da ausência (hoje − 365 a hoje + 365)', () {
    final hoje = DateTime(2026, 11, 18);

    test('aceita os limites e hoje', () {
      expect(validarDataAusencia(hoje, hoje), isNull);
      expect(validarDataAusencia(DateTime(2025, 11, 18), hoje), isNull);
      expect(validarDataAusencia(DateTime(2027, 11, 18), hoje), isNull);
      expect(primeiraDataAusencia(hoje), DateTime(2025, 11, 18));
      expect(ultimaDataAusencia(hoje), DateTime(2027, 11, 18));
    });

    test('recusa fora da faixa e sem data', () {
      final esperado = 'A data da ausência precisa estar entre 18/11/2025 e 18/11/2027.';
      expect(validarDataAusencia(DateTime(2025, 11, 17), hoje), esperado);
      expect(validarDataAusencia(DateTime(2027, 11, 19), hoje), esperado);
      expect(validarDataAusencia(null, hoje), 'Selecione a data da ausência.');
    });

    test('ignora a hora', () {
      expect(validarDataAusencia(DateTime(2027, 11, 18, 23, 59), DateTime(2026, 11, 18, 0, 1)), isNull);
    });
  });
}
