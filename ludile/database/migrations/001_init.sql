-- =====================================================================
-- Ludilê — Migration 001: schema inicial multi-tenant + RLS
-- Banco isolado do UpVia Agentes (nenhuma tabela/credencial compartilhada).
-- Compatível com Supabase (cloud ou self-hosted): usa auth.users e auth.uid().
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- 1. TENANTS (organizations) — seção 13 e 13b
-- ---------------------------------------------------------------------

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('familia', 'escola', 'clinica')),
  name text not null,
  -- white-label (13b)
  display_name text,
  logo_url text,
  primary_color text default '#6C4FE0',
  secondary_color text default '#FFC93C',
  subdomain text unique,
  plan_tier text not null default 'standard' check (plan_tier in ('standard', 'white_label')),
  enabled_features jsonb not null default '{}'::jsonb,
  enabled_phases jsonb not null default '[1]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.organizations is 'Tenant: família, escola ou clínica. Toda personalização white-label vive aqui, nunca em código.';

create table public.org_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('parent', 'teacher', 'therapist', 'org_admin', 'system_admin')),
  created_at timestamptz not null default now(),
  unique (organization_id, user_id, role)
);

create index idx_org_members_user on public.org_members(user_id);
create index idx_org_members_org on public.org_members(organization_id);

-- Perfil público espelhando auth.users (nome de exibição, sem duplicar credenciais)
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 2. FUNÇÕES DE APOIO A RLS
-- ---------------------------------------------------------------------

create or replace function public.is_org_member(org_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.org_members om
    where om.organization_id = org_id
      and om.user_id = auth.uid()
  );
$$;

create or replace function public.has_org_role(org_id uuid, roles text[])
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.org_members om
    where om.organization_id = org_id
      and om.user_id = auth.uid()
      and om.role = any(roles)
  );
$$;

create or replace function public.is_system_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.org_members om
    where om.user_id = auth.uid()
      and om.role = 'system_admin'
  );
$$;

-- ---------------------------------------------------------------------
-- 3. CATÁLOGO PEDAGÓGICO GLOBAL (não carrega organization_id — é conteúdo
--    compartilhado por todos os tenants, só a progressão da criança é isolada)
-- ---------------------------------------------------------------------

create table public.skills (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  category text not null,
  order_index int not null default 0
);

create table public.worlds (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  icon text,
  order_index int not null default 0,
  is_active boolean not null default true
);

create table public.missions (
  id uuid primary key default gen_random_uuid(),
  world_id uuid not null references public.worlds(id) on delete cascade,
  code text not null unique,
  name text not null,
  description text,
  order_index int not null default 0,
  unlock_requirement jsonb not null default '{}'::jsonb,
  is_active boolean not null default true
);

create index idx_missions_world on public.missions(world_id);

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.missions(id) on delete cascade,
  skill_id uuid references public.skills(id),
  activity_type text not null check (activity_type in (
    'caca_letra', 'memoria', 'qual_e_o_som', 'comeca_com',
    'monte_a_silaba', 'monte_a_palavra', 'qual_e_a_palavra', 'leia_e_escolha'
  )),
  difficulty smallint not null default 1 check (difficulty between 1 and 5),
  instruction text not null,
  audio_url text,
  question jsonb not null default '{}'::jsonb,
  options jsonb not null default '[]'::jsonb,
  correct_answer jsonb not null,
  hint text,
  reward jsonb not null default '{"xp": 10, "coins": 2}'::jsonb,
  order_index int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_activities_mission on public.activities(mission_id);
create index idx_activities_type on public.activities(activity_type);

create table public.rewards (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  type text not null check (type in ('avatar_item', 'scenario', 'cosmetic')),
  image_url text,
  unlock_criteria jsonb not null default '{}'::jsonb
);

create table public.badges (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  icon_url text,
  criteria jsonb not null default '{}'::jsonb
);

create table public.stories (
  id uuid primary key default gen_random_uuid(),
  world_id uuid references public.worlds(id),
  code text not null unique,
  title text not null,
  text_content text not null,
  audio_url text,
  order_index int not null default 0,
  is_active boolean not null default true
);

create table public.story_questions (
  id uuid primary key default gen_random_uuid(),
  story_id uuid not null references public.stories(id) on delete cascade,
  question text not null,
  options jsonb not null default '[]'::jsonb,
  correct_answer jsonb not null,
  order_index int not null default 0
);

create table public.audio_assets (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('letters', 'syllables', 'words', 'instructions', 'stories')),
  code text not null,
  storage_path text not null,
  language text not null default 'pt-BR',
  unique (category, code, language)
);

create table public.image_assets (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  code text not null,
  storage_path text not null,
  unique (category, code)
);

-- ---------------------------------------------------------------------
-- 4. CRIANÇAS E RESPONSÁVEIS (isolado por organization_id)
-- ---------------------------------------------------------------------

create table public.child_profiles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  nickname text not null,
  avatar_id text not null default 'default',
  birth_year int,
  accessibility_settings jsonb not null default '{
    "font": "default",
    "font_size": "medium",
    "sound_effects": true,
    "animation_speed": "normal",
    "focus_mode": false
  }'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_child_profiles_org on public.child_profiles(organization_id);

create table public.child_parent_relationships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  parent_user_id uuid not null references auth.users(id) on delete cascade,
  relationship text not null default 'responsavel',
  created_at timestamptz not null default now(),
  unique (child_id, parent_user_id)
);

create index idx_cpr_child on public.child_parent_relationships(child_id);
create index idx_cpr_parent on public.child_parent_relationships(parent_user_id);

-- PIN da área dos responsáveis (nunca reaproveitar a senha de login — seção 11)
create table public.guardian_pins (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  pin_hash text not null,
  updated_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

-- ---------------------------------------------------------------------
-- 5. PROGRESSO, TENTATIVAS, RECOMPENSAS DA CRIANÇA (isolado por organization_id)
-- ---------------------------------------------------------------------

create table public.game_progress (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  mission_id uuid not null references public.missions(id),
  status text not null default 'locked' check (status in ('locked', 'available', 'in_progress', 'completed')),
  stars_earned smallint not null default 0 check (stars_earned between 0 and 3),
  xp_earned int not null default 0,
  updated_at timestamptz not null default now(),
  unique (child_id, mission_id)
);

create index idx_game_progress_child on public.game_progress(child_id);
create index idx_game_progress_org on public.game_progress(organization_id);

create table public.attempts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  activity_id uuid not null references public.activities(id),
  is_correct boolean not null,
  hints_used smallint not null default 0,
  time_spent_ms int,
  attempt_number smallint not null default 1,
  difficulty_at_attempt smallint,
  created_at timestamptz not null default now()
);

create index idx_attempts_child on public.attempts(child_id);
create index idx_attempts_org on public.attempts(organization_id);
create index idx_attempts_activity on public.attempts(activity_id);

create table public.child_skill_progress (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  skill_id uuid not null references public.skills(id),
  mastery_level numeric(4,1) not null default 0 check (mastery_level between 0 and 100),
  updated_at timestamptz not null default now(),
  unique (child_id, skill_id)
);

create index idx_csp_child on public.child_skill_progress(child_id);

create table public.child_rewards (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  reward_id uuid not null references public.rewards(id),
  unlocked_at timestamptz not null default now(),
  unique (child_id, reward_id)
);

create table public.child_badges (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  badge_id uuid not null references public.badges(id),
  earned_at timestamptz not null default now(),
  unique (child_id, badge_id)
);

-- ---------------------------------------------------------------------
-- 6. CONFIGURAÇÃO E AUDITORIA
-- ---------------------------------------------------------------------

create table public.settings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  child_id uuid references public.child_profiles(id) on delete cascade,
  scope text not null check (scope in ('organization', 'child')),
  key text not null,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete set null,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index idx_audit_logs_org on public.audit_logs(organization_id);

-- ---------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY
-- ---------------------------------------------------------------------

alter table public.organizations enable row level security;
alter table public.org_members enable row level security;
alter table public.users enable row level security;
alter table public.child_profiles enable row level security;
alter table public.child_parent_relationships enable row level security;
alter table public.guardian_pins enable row level security;
alter table public.game_progress enable row level security;
alter table public.attempts enable row level security;
alter table public.child_skill_progress enable row level security;
alter table public.child_rewards enable row level security;
alter table public.child_badges enable row level security;
alter table public.settings enable row level security;
alter table public.audit_logs enable row level security;

-- catálogo global: leitura liberada a qualquer usuário autenticado, escrita só system_admin
alter table public.skills enable row level security;
alter table public.worlds enable row level security;
alter table public.missions enable row level security;
alter table public.activities enable row level security;
alter table public.rewards enable row level security;
alter table public.badges enable row level security;
alter table public.stories enable row level security;
alter table public.story_questions enable row level security;
alter table public.audio_assets enable row level security;
alter table public.image_assets enable row level security;

-- organizations: membro vê a própria org; system_admin vê todas
create policy org_select on public.organizations for select
  using (public.is_org_member(id) or public.is_system_admin());
create policy org_update on public.organizations for update
  using (public.has_org_role(id, array['org_admin']) or public.is_system_admin());
create policy org_insert_system_admin on public.organizations for insert
  with check (public.is_system_admin());

-- org_members: só membros da própria org enxergam a lista de membros
create policy org_members_select on public.org_members for select
  using (public.is_org_member(organization_id) or public.is_system_admin());
create policy org_members_write on public.org_members for all
  using (public.has_org_role(organization_id, array['org_admin']) or public.is_system_admin())
  with check (public.has_org_role(organization_id, array['org_admin']) or public.is_system_admin());

-- users: cada um vê/edita o próprio perfil
create policy users_self on public.users for select using (id = auth.uid());
create policy users_self_update on public.users for update using (id = auth.uid());
create policy users_self_insert on public.users for insert with check (id = auth.uid());

-- tabelas isoladas por organization_id: padrão idêntico em todas
do $$
declare
  t text;
  tenant_tables text[] := array[
    'child_profiles', 'child_parent_relationships', 'guardian_pins',
    'game_progress', 'attempts', 'child_skill_progress',
    'child_rewards', 'child_badges', 'settings', 'audit_logs'
  ];
begin
  foreach t in array tenant_tables loop
    execute format(
      'create policy %I_tenant_isolation on public.%I for all
         using (public.is_org_member(organization_id) or public.is_system_admin())
         with check (public.is_org_member(organization_id) or public.is_system_admin());',
      t, t
    );
  end loop;
end $$;

-- catálogo global: SELECT para qualquer autenticado, escrita só system_admin
do $$
declare
  t text;
  catalog_tables text[] := array[
    'skills', 'worlds', 'missions', 'activities', 'rewards',
    'badges', 'stories', 'story_questions', 'audio_assets', 'image_assets'
  ];
begin
  foreach t in array catalog_tables loop
    execute format(
      'create policy %I_read_all on public.%I for select using (auth.role() = ''authenticated'');',
      t, t
    );
    execute format(
      'create policy %I_write_admin on public.%I for insert with check (public.is_system_admin());',
      t, t
    );
    execute format(
      'create policy %I_update_admin on public.%I for update using (public.is_system_admin());',
      t, t
    );
    execute format(
      'create policy %I_delete_admin on public.%I for delete using (public.is_system_admin());',
      t, t
    );
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 8. CADASTRO DE FAMÍLIA (MVP) — organização padrão criada automaticamente
-- ---------------------------------------------------------------------

-- Autoatendimento só é permitido para organizações do tipo "familia":
-- escola/clínica são provisionadas por system_admin (onboarding comercial,
-- ver seção 13b). Função SECURITY DEFINER evita expor uma policy de INSERT
-- genérica em organizations que qualquer usuário autenticado pudesse abusar.
create or replace function public.create_family_organization(family_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_org_id uuid;
begin
  insert into public.organizations (type, name, plan_tier)
  values ('familia', family_name, 'standard')
  returning id into new_org_id;

  insert into public.org_members (organization_id, user_id, role)
  values (new_org_id, auth.uid(), 'parent');

  insert into public.users (id, display_name)
  values (auth.uid(), family_name)
  on conflict (id) do nothing;

  return new_org_id;
end;
$$;

grant execute on function public.create_family_organization(text) to authenticated;

comment on table public.child_profiles is
  'CRÍTICA: toda tabela relacionada à criança carrega organization_id. RLS filtra por organização, nunca só por user_id — necessário desde já para suportar escola/clínica na fase SaaS.';
