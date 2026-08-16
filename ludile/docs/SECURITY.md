# Segurança e Privacidade — Ludilê

## Isolamento do UpVia Agentes (seções 1 e 2)

- Banco de dados próprio (self-hosted, `docker/supabase/`), nenhuma tabela,
  schema, credencial ou projeto Supabase compartilhado com `memoria-upvia`
  ou `vendedor ia saas`.
- Containers, rede Docker (`ludile_default`) e volumes próprios — não
  reaproveita nada do N8N ou da Evolution API.
- Subdomínio isolado, deploy separado, sem alterar Nginx/Traefik/N8N
  existentes (a config em `nginx/ludile.conf` é só para o novo subdomínio).
- Nenhuma credencial do UpVia (Evolution API key, Supabase do AtendentIA
  etc.) é usada ou referenciada em nenhum arquivo deste projeto.

## Autenticação e autorização

- Supabase Auth (GoTrue) para responsáveis/profissionais — e-mail + senha.
- Row Level Security em **todas** as tabelas que carregam dado de tenant ou
  criança (`database/migrations/001_init.sql`, seção 7). Duas funções
  `SECURITY DEFINER` (`is_org_member`, `has_org_role`, `is_system_admin`)
  concentram a lógica de autorização — nenhuma policy confia em dado vindo
  do cliente.
- Criação de organização "família" via função `create_family_organization`
  (RPC), não via INSERT direto — evita que um usuário autenticado crie
  organizações arbitrárias ou do tipo escola/clínica (essas são
  provisionadas por `system_admin`, seção 13b).
- Área dos responsáveis protegida por **PIN separado da senha de login**
  (`lib/pin.ts`, scrypt + salt aleatório, nunca texto puro), seção 11.
- Painel administrativo (`/admin`) exige role `system_admin`
  (`lib/data/admin-queries.ts#isCurrentUserSystemAdmin`).

## Privacidade infantil (seção 14)

- Minimização de dados: perfil da criança tem só apelido, avatar e ano de
  nascimento (opcional) — sem nome completo, sem foto, sem localização.
- Nenhuma publicidade, nenhuma venda de dado, nenhum uso de dado infantil
  para treinar modelo.
- Relatórios para responsáveis usam linguagem pedagógica ("apresentou maior
  dificuldade nesta habilidade"), nunca linguagem médica/diagnóstica — ver
  aviso explícito na tela `/area-responsaveis`.
- Quando a organização for escola/clínica (fase SaaS), a base legal passa a
  ser o contrato institucional, não só o consentimento do responsável — a
  instituição atua como controladora/operadora dos dados da criança nesse
  contexto (nota da seção 14, a implementar na fase SaaS).

## Cabeçalhos e transporte

- `next.config.js` define `X-Frame-Options`, `X-Content-Type-Options`,
  `Referrer-Policy` e `X-Robots-Tag: noindex, nofollow` em toda rota.
- HTTPS obrigatório em produção (Let's Encrypt via Nginx/Traefik — ver
  `docs/DEPLOY.md`); cookies de sessão (`ludile_child_id`,
  `ludile_guardian_verified`) são `httpOnly` e `secure` em produção.

## O que nunca fazer aqui (seção 25 aplicada ao código)

- Nunca logar senha, PIN, JWT_SECRET, ANON_KEY, SERVICE_ROLE_KEY ou
  qualquer variável de `docker/supabase/.env`.
- Nunca commitar `.env`/`.env.local` (ver `.gitignore`).
- Nunca usar `output: true`/PUT direto para "corrigir rápido" um dado de
  produção sem passar pela migration versionada em `database/migrations/`.

## Nota contratual (white-label, seção 13b)

Quando licenciado para escola/clínica: a propriedade do produto é da
UpVia/Ludilê — a instituição licencia o uso com marca própria, não adquire
o software. Isso deve constar no contrato comercial (fora do escopo deste
repositório).
