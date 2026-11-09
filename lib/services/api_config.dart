/// Endereço do backend .NET (SistemaRH.Backend), compartilhado por todos os
/// serviços HTTP do app.
///
/// Hoje aponta pro túnel público (Cloudflare) que expõe o backend rodando
/// localmente — assim o app funciona em qualquer celular, não só no
/// emulador. Como é um túnel "quick" (gratuito, sem conta), a URL muda toda
/// vez que o túnel é reiniciado; se parar de funcionar, é só pedir uma nova
/// URL e atualizar essa constante.
const String apiBaseUrl = 'https://helen-met-talk-points.trycloudflare.com';
