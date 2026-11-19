/// Endereço do backend .NET (SistemaRH.Backend), compartilhado por todos os
/// serviços HTTP do app.
///
/// Por padrão aponta pro backend publicado na Railway (endereço fixo), então o
/// APK funciona em qualquer celular. Pra falar com outro servidor não precisa
/// mexer no código: basta passar `--dart-define=API_BASE_URL=...` no
/// `flutter run`, `flutter test` ou `flutter build`. Ex.: backend rodando no
/// computador, visto de dentro do emulador Android:
/// `--dart-define=API_BASE_URL=http://10.0.2.2:5080`.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://backend-production-b0a758c2.up.railway.app',
);
