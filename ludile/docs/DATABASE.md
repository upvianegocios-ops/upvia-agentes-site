# Banco de Dados — Ludilê

Postgres self-hosted (Supabase stack), schema em
`database/migrations/001_init.sql`, seed do Mundo 1 em
`database/seed/001_vila_das_letras.sql`.

## Modelo de dados

### Tenants (multi-tenant desde a v1 — seções 13 e 13b)

| Tabela | Papel |
|---|---|
| `organizations` | Família, escola ou clínica. Também guarda o branding white-label (`display_name`, `logo_url`, `primary_color`, `secondary_color`, `subdomain`, `plan_tier`, `enabled_features`, `enabled_phases`). |
| `org_members` | Vínculo usuário ↔ organização ↔ papel (`parent`, `teacher`, `therapist`, `org_admin`, `system_admin`). |
| `users` | Perfil público espelhando `auth.users` (nome de exibição). |

### Catálogo pedagógico (global — compartilhado por todos os tenants)

`skills`, `worlds`, `missions`, `activities`, `rewards`, `badges`,
`stories`, `story_questions`, `audio_assets`, `image_assets`. Nenhuma
dessas tabelas carrega `organization_id`: é conteúdo, não dado de tenant.

### Criança e progresso (isolado por `organization_id` — regra crítica)

`child_profiles`, `child_parent_relationships`, `guardian_pins`,
`game_progress`, `attempts`, `child_skill_progress`, `child_rewards`,
`child_badges`, `settings`, `audit_logs`.

> Toda tabela desta lista tem `organization_id` e uma RLS policy idêntica
> (`is_org_member(organization_id) OR is_system_admin()`), gerada via o
> bloco `DO $$ ... FOREACH ... $$` no fim da migration — evita esquecer a
> policy em uma tabela nova.

## RLS — como funciona

Duas funções `SECURITY DEFINER`:

```sql
is_org_member(org_id uuid) -> boolean   -- o usuário logado pertence à org?
has_org_role(org_id uuid, roles text[]) -> boolean -- e tem um desses papéis?
is_system_admin() -> boolean
```

Catálogo global: `SELECT` liberado para qualquer usuário autenticado,
`INSERT/UPDATE/DELETE` só para `system_admin`.

## Cadastro de família (MVP)

`create_family_organization(family_name text)` — função `SECURITY DEFINER`
chamada pelo app no cadastro (`app/(auth)/cadastro/page.tsx`). Cria a
organização tipo `familia`, o vínculo `org_members` com papel `parent`, e o
perfil em `users`. Evita expor uma policy de `INSERT` genérica em
`organizations` que qualquer usuário pudesse abusar para criar orgs
arbitrárias.

## Aplicando as migrations

- **Self-hosted (produção/VPS):** já é aplicado automaticamente na primeira
  subida do container `ludile-db` — ver os mounts `999-ludile-init.sql` e
  `9999-ludile-seed.sql` em `docker/supabase/docker-compose.yml`.
- **Contra um Postgres já rodando** (ex: ambiente de teste): rode os dois
  arquivos SQL em ordem com `psql` ou com o SQL Editor do Studio.

## Extensão futura (fase SaaS)

Adicionar tabelas novas de tenant deve sempre seguir o padrão: coluna
`organization_id not null references organizations(id)`, e adicionar o
nome da tabela ao array `tenant_tables` no bloco de RLS da migration
seguinte — nunca criar a tabela sem RLS "para adicionar depois".
