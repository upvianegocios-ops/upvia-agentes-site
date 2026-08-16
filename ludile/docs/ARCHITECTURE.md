# Arquitetura — Ludilê

## Visão geral

```
[Criança/Tablet] ──HTTPS──> [Nginx/Traefik] ──> [Next.js app (container ludile-app)]
                                                        │
                                                        ▼ (rede interna Docker, nunca pública)
                                          [Envoy gateway (ludile-envoy:8000)]
                                                        │
                                    ┌───────────────────┼────────────────────┐
                                    ▼                    ▼                    ▼
                              [GoTrue Auth]        [PostgREST]          [Storage API]
                                    │                    │                    │
                                    └────────────────────┴────────────────────┘
                                                        ▼
                                          [Postgres self-hosted (ludile-db)]
```

Todo o stack de banco/auth/storage roda em `docker/supabase/` (vendorizado do
repositório oficial `supabase/supabase`, ver seção "Por que vendorizar"
abaixo). O app Next.js é o **único** ponto exposto publicamente — o gateway
Supabase fica só em `127.0.0.1`, alcançável apenas pelo app e por quem tiver
acesso SSH à VPS.

## Decisões e por quê

### 1. Next.js App Router + Server Actions
Evita expor uma API REST própria separada: leitura via Server Components
(RSC), escrita via Server Actions (`'use server'`), ambos rodando no
servidor com a chave anônima do Supabase — RLS é quem garante o isolamento
por `organization_id`, nunca a lógica do app sozinha.

### 2. Multi-tenant desde o dia 1 (seção 13/13b)
Toda tabela ligada a criança/progresso carrega `organization_id`. No MVP
existe só o tipo `familia` (criado automaticamente no cadastro via a função
`create_family_organization`, ver `database/migrations/001_init.sql`).
Escola/clínica (`org_admin`, `teacher`, `therapist`) já têm role e RLS
prontos — só falta a tela de onboarding institucional na fase SaaS, não o
schema.

### 3. White-label como configuração (seção 13b)
`organizations.display_name/logo_url/primary_color/secondary_color/subdomain`
é lido em runtime pelo `middleware.ts` (resolve subdomínio → header
`x-ludile-org-subdomain`) e pelos componentes via CSS custom properties
(`--ludile-primary`, `--ludile-secondary` em `tailwind.config.ts`). Nunca há
build ou deploy separado por cliente.

**Pendente para produção multi-domínio real (documentado, não bloqueia o
MVP familiar):** certificado wildcard ou emissão automática por subdomínio
novo — hoje a VPS usa EasyPanel/Traefik, que já suporta isso via labels
dinâmicas; a automação (criar o registro DNS + o serviço no EasyPanel a
cada nova escola/clínica) fica para a fase SaaS.

### 4. Por que vendorizar o self-hosted do Supabase em vez de escrever do zero
O stack completo (Postgres com extensões próprias, GoTrue, PostgREST,
Realtime, Storage, Envoy/Kong, Supavisor) tem dezenas de variáveis de
ambiente interdependentes (JWT_SECRET, ANON_KEY, SERVICE_ROLE_KEY, chaves de
criptografia). Reescrever isso à mão arrisca um deploy quebrado — o que este
projeto proíbe explicitamente (seção 1: "o app deve ser instalado de forma
isolada e não pode quebrar"). Por isso `docker/supabase/` é uma cópia do
`docker/` oficial do repositório `supabase/supabase`, com o mínimo de
customização necessária para isolamento (ver `docker/supabase/docker-compose.yml`,
comentário no topo do arquivo).

### 5. Motor de dificuldade adaptativo é determinístico, não IA (seção 9/24)
`lib/game-engine/difficulty.ts` é uma função pura, testável, sem chamada a
nenhum modelo. Ajusta dificuldade, sinaliza "mostrar explicação visual" e
"sugerir pausa" — nunca rotula ou diagnostica a criança.

### 6. Áudio: SpeechSynthesis sempre, TTS externo nunca bloqueia
`lib/audio/speech.ts` usa a Web SpeechSynthesis API do navegador como
caminho principal. Um áudio pré-gravado (`audio_url` na atividade) é
preferido quando existe; se falhar ao carregar, cai automaticamente para o
SpeechSynthesis — nunca fica mudo.

### 7. Offline (PWA)
`public/sw.js` faz cache do app shell. `lib/offline/queue.ts` guarda
tentativas de atividade em `localStorage` quando a gravação falha (sem
rede) e sincroniza no evento `online`. Ver limitação documentada em
`docs/PENDENCIAS.md` (localStorage vs. IndexedDB, conclusão de missão ainda
exige rede no MVP).

## Estrutura de pastas

```
ludile/
  app/                    Next.js App Router (rotas por grupo: (auth), (child), (parent), (admin))
  components/ui/          Design system (GameButton, MapNode, RewardModal, ...)
  components/games/       Os 3 mini-jogos do MVP + ActivityRenderer (motor genérico)
  lib/game-engine/        Dificuldade adaptativa, recompensas, tipos — puro, testável
  lib/data/                Consultas Supabase (Server Components)
  lib/supabase/            Clientes browser/server (@supabase/ssr)
  lib/audio/                SpeechSynthesis
  lib/offline/              Fila de sincronização offline
  database/migrations/     Schema SQL (organizations, RLS, etc.)
  database/seed/            Conteúdo do Mundo 1 (10 letras, 20 atividades)
  docker/supabase/          Stack Supabase self-hosted (vendorizado)
  docker/app/                Dockerfile do Next.js
  nginx/                      Config do subdomínio isolado
  docs/                        Esta documentação
```
