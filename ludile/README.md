# Ludilê — a aventura da alfabetização

Aplicativo web/PWA de alfabetização infantil gamificada. MVP: **Mundo 1 — Vila das Letras** (seção 21 do prompt mestre).

Projeto totalmente isolado do UpVia Agentes (nenhum código, banco, credencial, container ou domínio compartilhado — ver [`docs/SECURITY.md`](docs/SECURITY.md)).

## Stack

- Next.js 14 (App Router) + TypeScript + Tailwind CSS
- Supabase self-hosted (Postgres + Auth + Storage + RLS), vendorizado em `docker/supabase/` a partir do repositório oficial `supabase/supabase`
- PWA (manifest + service worker) — instalável em celular/tablet, joga offline
- Vitest + Testing Library para testes unitários/componentes

## Rodando localmente

```bash
npm install
cp .env.example .env.local   # preencha com as chaves do Supabase (ver docs/DEPLOY.md)
npm run dev
```

Abra http://localhost:3000.

## Scripts

| Comando | O que faz |
|---|---|
| `npm run dev` | Servidor de desenvolvimento |
| `npm run build` | Build de produção |
| `npm run typecheck` | Checagem de tipos TypeScript |
| `npm run lint` | ESLint |
| `npm test` | Testes unitários (Vitest) |

## Documentação

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — decisões de arquitetura e como isso vira SaaS na fase 2
- [`docs/DATABASE.md`](docs/DATABASE.md) — schema, multi-tenancy e RLS
- [`docs/SECURITY.md`](docs/SECURITY.md) — segurança, privacidade infantil e isolamento do UpVia
- [`docs/DEPLOY.md`](docs/DEPLOY.md) — passo a passo de deploy na VPS
- [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) — sistema pedagógico e de jogo
- [`docs/PENDENCIAS.md`](docs/PENDENCIAS.md) — o que falta validar antes do piloto
