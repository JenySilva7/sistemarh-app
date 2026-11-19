import 'formatters.dart';

// Regras de validação iguais às da API (README do backend, seções 5 e 8, e
// Common/Textos.cs e Common/Contato.cs), pra mostrar o erro antes de enviar.
// A API valida de novo de qualquer jeito; se as duas divergirem, a mensagem
// que ela devolver aparece na tela.

/// Regra de um campo de texto: nome na mensagem de erro, tamanho mínimo e
/// máximo (contados depois da limpeza) e se o campo é de texto longo (aceita
/// quebra de linha) ou aceita emoji.
class RegraTexto {
  /// Com artigo e maiúscula (ex.: "O assunto").
  final String rotulo;
  final int minimo;
  final int maximo;
  final String mensagemObrigatorio;
  final bool multiLinha;
  final bool permiteEmoji;

  const RegraTexto(
    this.rotulo,
    this.minimo,
    this.maximo,
    this.mensagemObrigatorio, {
    this.multiLinha = false,
    this.permiteEmoji = false,
  });

  /// Textos longos e o assunto da mensagem ao RH aceitam sequências de emoji
  /// — quem escreve pelo celular usa emoji.
  bool get aceitaEmoji => multiLinha || permiteEmoji;
}

const regraAssuntoMensagemRh = RegraTexto(
  'O assunto',
  3,
  100,
  'Informe o assunto da mensagem.',
  permiteEmoji: true,
);
const regraTextoMensagemRh = RegraTexto('A mensagem', 3, 2000, 'Escreva a mensagem.', multiLinha: true);
const regraDescricaoAusencia = RegraTexto(
  'A descrição',
  3,
  2000,
  'Descreva o motivo da ausência.',
  multiLinha: true,
);

/// A data da ausência vai de hoje − 365 até hoje + 365 dias.
const diasLimiteAusencia = 365;

const _quebra = 0x0A;
const _retorno = 0x0D;
const _zwj = 0x200D;
const _keycap = 0x20E3;
const _fimDasTags = 0xE007F;
const _bandeiraPreta = 0x1F3F4;
const _maximoDeZwjPorSequencia = 10;
const _maximoDeTagsPorBandeira = 8;

// ── Classificação dos caracteres (mesmas listas da API) ───────────────────

/// "Brancos" que não são de controle nem de formatação (Cc/Cf) mas também
/// não aparecem na tela — com eles dava pra ter um texto "em branco" que
/// passa no tamanho mínimo. Mesma lista da API (`Textos.EhInvisivelExtra`).
bool ehInvisivelExtra(int c) =>
    c == 0x034F || // combining grapheme joiner
    c == 0x115F || c == 0x1160 || // fillers do hangul (jamo)
    c == 0x3164 || c == 0xFFA0 || // hangul filler / halfwidth hangul filler
    c == 0x17B4 || c == 0x17B5 || // vogais invisíveis do khmer
    c == 0x2800 || // braille em branco
    (c >= 0x180B && c <= 0x180F) || // seletores de variação e separador do mongol
    (c >= 0xFE00 && c <= 0xFE0F) || // seletores de variação VS1–VS16
    (c >= 0xE0100 && c <= 0xE01EF); // seletores de variação VS17–VS256

/// Partes de uma sequência de emoji que não são um caractere por si:
/// seletores de texto/emoji (U+FE0E, U+FE0F), o ZWJ (U+200D), o keycap
/// (U+20E3), os tons de pele (U+1F3FB–U+1F3FF) e as tags das bandeiras
/// (U+E0020–U+E007F). Não contam pro tamanho mínimo nem como "caractere
/// visível" (`Textos.EhParteDeEmoji`).
bool ehParteDeEmoji(int c) =>
    c == 0xFE0E ||
    c == 0xFE0F ||
    c == _zwj ||
    c == _keycap ||
    _ehTomDePele(c) ||
    (c >= 0xE0020 && c <= _fimDasTags);

/// Base de emoji "desenhado": pode receber seletor, tom de pele e ser unida a
/// outra pelo ZWJ (`Textos.EhBaseDeEmoji`). Os tons de pele, apesar de
/// estarem na faixa, não são base.
bool ehBaseDeEmoji(int c) {
  if (_ehTomDePele(c)) return false;
  return (c >= 0x1F000 && c <= 0x1FAFF) ||
      (c >= 0x2600 && c <= 0x27BF) ||
      (c >= 0x2300 && c <= 0x23FF) ||
      (c >= 0x2B00 && c <= 0x2BFF) ||
      (c >= 0x2190 && c <= 0x21FF) ||
      (c >= 0x2900 && c <= 0x297F) ||
      c == 0x3030 || c == 0x303D || c == 0x3297 || c == 0x3299 ||
      c == 0x00A9 || c == 0x00AE || c == 0x203C || c == 0x2049 || c == 0x2122 || c == 0x2139 ||
      c == 0x24C2 || c == 0x25AA || c == 0x25AB || c == 0x25B6 || c == 0x25C0 ||
      (c >= 0x25FB && c <= 0x25FE);
}

/// Base de keycap (dígito, # ou *): aceita o seletor e o U+20E3, mas não tom
/// de pele nem ZWJ.
bool _ehBaseDeKeycap(int c) => (c >= 0x30 && c <= 0x39) || c == 0x23 || c == 0x2A;

bool _ehTomDePele(int c) => c >= 0x1F3FB && c <= 0x1F3FF;

bool _ehTag(int c) => c >= 0xE0020 && c <= 0xE007E;

/// Controle (Cc), formatação (Cf), separador de linha (Zl) e de parágrafo (Zp).
final _controleOuFormato = RegExp(r'[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]', unicode: true);

/// Code point sem caractere atribuído (Cn).
final _semCaractere = RegExp(r'\p{Cn}', unicode: true);

/// Espaços (Unicode Zs), inclusive o não separável.
final _espacosRepetidos = RegExp(r'\p{Zs}+', unicode: true);
final _espacosNasPontas = RegExp(r'^ +| +$');
final _quebrasDemais = RegExp(r'\n{3,}');

bool _ehSurrogateSolto(int c) => c >= 0xD800 && c <= 0xDFFF;

/// Não-caracteres do Unicode (U+FDD0–U+FDEF e todo U+xFFFE/U+xFFFF).
bool _ehNaoCaractere(int c) => (c >= 0xFDD0 && c <= 0xFDEF) || (c & 0xFFFE) == 0xFFFE;

/// A faixa dos emoji fica de fora da recusa de Cn: os emoji novos que os
/// celulares já mandam podem ainda não ter caractere nas tabelas da API.
bool _ehFaixaDeEmoji(int c) => c >= 0x1F000 && c <= 0x1FAFF;

/// Invisível ou de controle: Cc, Cf, Zl, Zp, surrogate solto, os "brancos" de
/// [ehInvisivelExtra], não-caracteres e code points sem caractere (Cn) fora da
/// faixa dos emoji (`Textos.EhInvisivelOuControle`).
bool _ehInvisivelOuControle(int c) {
  if (_ehSurrogateSolto(c) || ehInvisivelExtra(c) || _ehNaoCaractere(c)) return true;
  final caractere = String.fromCharCode(c);
  return _controleOuFormato.hasMatch(caractere) || (_semCaractere.hasMatch(caractere) && !_ehFaixaDeEmoji(c));
}

/// Propriedade Unicode White_Space (a mesma do `Rune.IsWhiteSpace` do .NET).
bool _ehBranco(int c) =>
    (c >= 0x09 && c <= 0x0D) ||
    c == 0x20 ||
    c == 0x85 ||
    c == 0xA0 ||
    c == 0x1680 ||
    (c >= 0x2000 && c <= 0x200A) ||
    c == 0x2028 ||
    c == 0x2029 ||
    c == 0x202F ||
    c == 0x205F ||
    c == 0x3000;

bool _ehVisivel(int c) => !_ehBranco(c) && !_ehInvisivelOuControle(c) && !ehParteDeEmoji(c);

// ── Sequências de emoji ───────────────────────────────────────────────────

enum _TipoBase { nenhuma, emoji, keycap }

/// Confere, caractere a caractere, se as partes de emoji de um texto formam
/// sequências de emoji de verdade (porte de `Textos.SequenciaDeEmoji`):
///  - seletor (U+FE0E/U+FE0F): só depois de uma base de emoji ou de keycap,
///    no máximo um por base;
///  - keycap (U+20E3): só depois de dígito, # ou * (com ou sem seletor);
///  - tom de pele: só depois de uma base de emoji, no máximo um por base;
///  - ZWJ: só ENTRE duas bases de emoji (antes dele pode vir o seletor ou o
///    tom da primeira), no máximo 10 por sequência;
///  - tags (U+E0020–U+E007E): só logo depois da bandeira U+1F3F4, no máximo
///    8, terminando em U+E007F.
/// Qualquer outro caractere segue a regra comum (invisível ou de controle é
/// recusado; a quebra de linha permitida passa).
class _SequenciaDeEmoji {
  _TipoBase _base = _TipoBase.nenhuma;
  bool _seletorUsado = false;
  bool _tomUsado = false;
  bool _depoisDoZwj = false;
  int _zwjsNaSequencia = 0;

  /// -1: fora de uma bandeira com tags.
  int _tags = -1;
  int _anterior = -1;

  /// Falso se o texto acabou no meio de uma bandeira com tags.
  bool get terminada => _tags < 0;

  bool aceitar(int c, {required bool quebraPermitida, required int? proximo}) {
    final aceito = _avaliar(c, quebraPermitida, proximo);
    _anterior = c;
    return aceito;
  }

  bool _avaliar(int c, bool quebraPermitida, int? proximo) {
    if (_tags >= 0) {
      if (_ehTag(c)) return ++_tags <= _maximoDeTagsPorBandeira;
      if (c == _fimDasTags) {
        // Bandeira fechada: nada mais se junta a ela.
        _tags = -1;
        _base = _TipoBase.nenhuma;
        return true;
      }
      return false;
    }

    if (_ehTag(c)) {
      if (_anterior != _bandeiraPreta) return false;
      _tags = 1;
      return true;
    }
    if (c == _fimDasTags) return false;
    if (c == 0xFE0E || c == 0xFE0F) {
      if (_base == _TipoBase.nenhuma || _seletorUsado) return false;
      _seletorUsado = true;
      return true;
    }
    if (c == _keycap) {
      if (_base != _TipoBase.keycap) return false;
      _base = _TipoBase.nenhuma;
      return true;
    }
    if (_ehTomDePele(c)) {
      if (_base != _TipoBase.emoji || _tomUsado) return false;
      _tomUsado = true;
      return true;
    }
    if (c == _zwj) {
      if (_base != _TipoBase.emoji ||
          proximo == null ||
          !ehBaseDeEmoji(proximo) ||
          ++_zwjsNaSequencia > _maximoDeZwjPorSequencia) {
        return false;
      }
      _base = _TipoBase.nenhuma;
      _depoisDoZwj = true;
      return true;
    }

    if (!quebraPermitida && _ehInvisivelOuControle(c)) return false;

    // Caractere comum: começa uma base nova (ou nenhuma).
    if (!_depoisDoZwj) _zwjsNaSequencia = 0;
    _depoisDoZwj = false;
    _seletorUsado = false;
    _tomUsado = false;
    _base = ehBaseDeEmoji(c)
        ? _TipoBase.emoji
        : _ehBaseDeKeycap(c)
        ? _TipoBase.keycap
        : _TipoBase.nenhuma;
    return true;
  }
}

// ── Textos ────────────────────────────────────────────────────────────────

String _mensagemMaximo(RegraTexto regra) => '${regra.rotulo} pode ter no máximo ${regra.maximo} caracteres.';

/// Confere caractere por caractere o texto como foi digitado (antes da
/// limpeza), como a API faz. Devolve a mensagem de erro, ou null.
///  - Campo de uma linha: qualquer controle ou invisível é recusado, inclusive
///    quebra de linha e tab.
///  - Texto longo: só a quebra de linha (\n ou \r) é aceita; tab continua
///    recusado.
///  - Com emoji ([RegraTexto.aceitaEmoji]): as partes de emoji só passam
///    dentro de uma sequência de verdade (ver [_SequenciaDeEmoji]).
String? _conferirCaracteres(String valor, RegraTexto regra) {
  final invisivel = '${regra.rotulo} contém caracteres invisíveis ou de controle, que não são permitidos.';
  final runas = valor.runes.toList();
  final emoji = _SequenciaDeEmoji();
  for (var i = 0; i < runas.length; i++) {
    final c = runas[i];
    final quebraPermitida = regra.multiLinha && (c == _quebra || c == _retorno);
    final aceito = regra.aceitaEmoji
        ? emoji.aceitar(c, quebraPermitida: quebraPermitida, proximo: i + 1 < runas.length ? runas[i + 1] : null)
        : quebraPermitida || !_ehInvisivelOuControle(c);
    if (!aceito) return invisivel;
  }
  // Bandeira com tags que não fecharam com U+E007F.
  if (regra.aceitaEmoji && !emoji.terminada) return invisivel;
  return null;
}

/// Limpa um texto que já passou na conferência de caracteres, como a API:
///  - espaços repetidos (inclusive NBSP e os outros Zs) viram um só e as
///    pontas são aparadas;
///  - no texto longo, antes disso \r\n e \r viram \n; depois, cada linha é
///    aparada (uma linha só de espaços fica vazia) e mais de 2 quebras
///    seguidas viram 2. Sem aparar as linhas antes, "\n \n \n" passaria como
///    3 quebras.
String limparTexto(String valor, RegraTexto regra) {
  var texto = valor;
  if (regra.multiLinha) texto = texto.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  texto = texto.replaceAll(_espacosRepetidos, ' ');
  if (regra.multiLinha) {
    texto = texto.split('\n').map((linha) => linha.replaceAll(_espacosNasPontas, '')).join('\n');
    texto = texto.replaceAll(_quebrasDemais, '\n\n');
  }
  return texto.trim();
}

/// Valida um texto livre com a [regra]. Devolve a mensagem de erro (a mesma
/// da API), ou null se estiver tudo certo.
///
/// Tamanho contado por caractere de verdade (code point), como a API: o
/// MÍNIMO não conta as partes de emoji ("a" + 2 seletores é 1 caractere na
/// tela); o MÁXIMO conta todos os code points, porque é o que ocupa a coluna
/// no banco.
String? validarTexto(String valor, RegraTexto regra) {
  if (valor.isEmpty) return regra.mensagemObrigatorio;
  // Um texto absurdamente maior que o permitido nem precisa ser percorrido.
  if (valor.length > regra.maximo * 4 + 1000) return _mensagemMaximo(regra);

  final erro = _conferirCaracteres(valor, regra);
  if (erro != null) return erro;

  final limpo = limparTexto(valor, regra);
  // Precisa de pelo menos um caractere visível de verdade (as partes de
  // emoji, sozinhas, não contam).
  if (limpo.isEmpty || !limpo.runes.any(_ehVisivel)) return regra.mensagemObrigatorio;

  var caracteres = 0;
  var partesDeEmoji = 0;
  for (final c in limpo.runes) {
    caracteres++;
    if (ehParteDeEmoji(c)) partesDeEmoji++;
  }
  if (caracteres - partesDeEmoji < regra.minimo) {
    return '${regra.rotulo} precisa ter pelo menos ${regra.minimo} caracteres.';
  }
  if (caracteres > regra.maximo) return _mensagemMaximo(regra);
  return null;
}

String? validarAssuntoMensagemRh(String assunto) => validarTexto(assunto, regraAssuntoMensagemRh);

String? validarTextoMensagemRh(String mensagem) => validarTexto(mensagem, regraTextoMensagemRh);

String? validarDescricaoAusencia(String descricao) => validarTexto(descricao, regraDescricaoAusencia);

// ── Senha ─────────────────────────────────────────────────────────────────

const senhaMinimo = 6;
const senhaMaximo = 64;
const mensagemSenhaComEmojiOuInvisivel = 'A senha não pode conter emoji nem caracteres invisíveis.';

/// Se a senha tem emoji (base desenhada ou parte de sequência). O mesmo
/// coração chega sem o seletor invisível de um teclado e com ele de outro, e
/// a pessoa não entraria mais pelo outro aparelho (`Textos.TemEmoji`).
bool _temEmoji(String texto) => texto.runes.any((c) => ehBaseDeEmoji(c) || ehParteDeEmoji(c));

bool _temInvisivelOuControle(String texto) => texto.runes.any(_ehInvisivelOuControle);

/// Valida uma senha como a API (`Senhas.Validar`): de 6 a 64 caracteres de
/// verdade (code points), não pode ser só espaços, nem começar ou terminar
/// com espaço, nem ter emoji ou caractere invisível. [rotulo] vem com artigo
/// e maiúscula (ex.: "A nova senha").
String? validarSenha(String senha, {String rotulo = 'A senha'}) {
  final curta = '$rotulo precisa ter pelo menos $senhaMinimo caracteres.';
  if (senha.isEmpty) return curta;
  if (senha.runes.every(_ehBranco)) return '$rotulo não pode ser formada só por espaços.';
  if (_temInvisivelOuControle(senha) || _temEmoji(senha)) return mensagemSenhaComEmojiOuInvisivel;
  if (_ehBranco(senha.runes.first) || _ehBranco(senha.runes.last)) {
    return '$rotulo não pode começar nem terminar com espaço.';
  }
  final caracteres = senha.runes.length;
  if (caracteres < senhaMinimo) return curta;
  if (caracteres > senhaMaximo) return '$rotulo pode ter no máximo $senhaMaximo caracteres.';
  return null;
}

/// Confere o formulário de troca de senha, na mesma ordem da API
/// (`PUT /api/auth/senha`): senha atual informada, nova senha válida e
/// diferente da atual. A confirmação é só do app.
String? validarTrocaDeSenha({required String senhaAtual, required String novaSenha, required String confirmacao}) {
  if (senhaAtual.isEmpty) return 'Informe a senha atual.';
  final erroNova = validarSenha(novaSenha, rotulo: 'A nova senha');
  if (erroNova != null) return erroNova;
  if (novaSenha == senhaAtual) return 'A nova senha precisa ser diferente da atual.';
  if (confirmacao != novaSenha) return 'A confirmação não é igual à nova senha.';
  return null;
}

// ── Datas ─────────────────────────────────────────────────────────────────

/// Primeiro dia aceito pra uma ausência, contado a partir de [hoje].
DateTime primeiraDataAusencia(DateTime hoje) => DateTime(hoje.year, hoje.month, hoje.day - diasLimiteAusencia);

/// Último dia aceito pra uma ausência, contado a partir de [hoje].
DateTime ultimaDataAusencia(DateTime hoje) => DateTime(hoje.year, hoje.month, hoje.day + diasLimiteAusencia);

/// Confere se a data da ausência foi escolhida e está dentro da faixa aceita
/// pela API. Só o dia importa (a hora de [data] e de [hoje] é ignorada).
String? validarDataAusencia(DateTime? data, DateTime hoje) {
  if (data == null) return 'Selecione a data da ausência.';
  final dia = DateTime(data.year, data.month, data.day);
  final primeira = primeiraDataAusencia(hoje);
  final ultima = ultimaDataAusencia(hoje);
  if (dia.isBefore(primeira) || dia.isAfter(ultima)) {
    return 'A data da ausência precisa estar entre ${formatarData(primeira)} e ${formatarData(ultima)}.';
  }
  return null;
}
