import { NextResponse, type NextRequest } from 'next/server';

// Resolve a organização (white-label, seção 13b) a partir do subdomínio da
// requisição e propaga via header para Server Components lerem o branding.
// Personalização é sempre configuração — nunca um deploy separado por cliente.

// TODO: confirmar o domínio definitivo do Ludilê (domínio próprio "ludile.com.br"
// ou subdomínio do UpVia "ludile.upviaagentes.com.br") e ajustar esta lista —
// ela define a partir de qual host o middleware passa a tratar o próximo nível
// como subdomínio de organização (white-label, seção 13b).
const ROOT_DOMAINS = ['ludile.com.br', 'ludile.upviaagentes.com.br', 'localhost:3000', 'localhost'];

function extractSubdomain(host: string): string | null {
  const hostname = host.split(':')[0] ?? host;
  for (const root of ROOT_DOMAINS.map((d) => d.split(':')[0] ?? d)) {
    if (hostname === root || hostname === `www.${root}`) return null;
    if (hostname.endsWith(`.${root}`)) {
      return hostname.replace(`.${root}`, '');
    }
  }
  return null;
}

export function middleware(request: NextRequest) {
  const host = request.headers.get('host') ?? '';
  const subdomain = extractSubdomain(host);

  const response = NextResponse.next();
  if (subdomain) {
    response.headers.set('x-ludile-org-subdomain', subdomain);
  }
  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
