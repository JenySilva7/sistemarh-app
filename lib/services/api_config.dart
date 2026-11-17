/// Endereço do backend .NET (SistemaRH.Backend), compartilhado por todos os
/// serviços HTTP do app.
///
/// Aponta pro backend publicado na Railway (endereço fixo), então o app
/// funciona em qualquer celular. Pra testar com o backend rodando localmente
/// no emulador Android, troque por http://10.0.2.2:5080.
const String apiBaseUrl = 'https://backend-production-b0a758c2.up.railway.app';
