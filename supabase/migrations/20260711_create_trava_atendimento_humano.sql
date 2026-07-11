-- Dedicated table for the human-handoff lock (humano_assumiu), decoupled from dados_cliente.
--
-- Root cause: dados_cliente gets a new row per chat session (session_id per row, by
-- original design), so it was never a safe source of truth for a lock that must be
-- unique per contact (telefone + instancia_whatsapp). Combined with a bug in the
-- "Buscar Contatos" n8n node (querying the wrong table, causing a brand new session
-- row to be created on every single client message), this produced dozens of
-- duplicate rows per contact -- some locked, some not -- and the trava-check node
-- ("Supabase - Buscar Sessao", limit 1, no ORDER BY) could non-deterministically
-- read either one, silently bypassing an active human takeover.
--
-- Applied in production on 2026-07-11 via mcp__supabase__apply_migration (this file
-- documents that change for the repo history / rollback reference).

create table if not exists public.dados_cliente_backup_20260711 as
select * from public.dados_cliente;

create table if not exists public.trava_atendimento_humano (
  id bigserial primary key,
  telefone text not null,
  instancia_whatsapp text not null,
  humano_assumiu boolean not null default false,
  humano_assumiu_em timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (telefone, instancia_whatsapp)
);

-- Migrate current lock state from dados_cliente: for each contact, the most
-- recent humano_assumiu_em across all their rows is the last real lock activation.
insert into public.trava_atendimento_humano (telefone, instancia_whatsapp, humano_assumiu, humano_assumiu_em)
select telefone, instancia_whatsapp,
       (max(humano_assumiu_em) is not null) as humano_assumiu,
       max(humano_assumiu_em) as humano_assumiu_em
from public.dados_cliente
where telefone is not null and instancia_whatsapp is not null
group by telefone, instancia_whatsapp
on conflict (telefone, instancia_whatsapp) do nothing;

-- Cleanup: dados_cliente had 889 orphaned duplicate rows across 180 contacts
-- (rows with telefone/instancia_whatsapp set), created by the "Buscar Contatos"
-- bug above. Keep only the most recent row per contact; rows without
-- telefone/instancia_whatsapp (857 of them, unrelated to this feature) are untouched.
-- Full pre-cleanup snapshot preserved in dados_cliente_backup_20260711 above.
with manter as (
  select distinct on (telefone, instancia_whatsapp) id
  from public.dados_cliente
  where telefone is not null and instancia_whatsapp is not null
  order by telefone, instancia_whatsapp, created_at desc
)
delete from public.dados_cliente
where telefone is not null and instancia_whatsapp is not null
  and id not in (select id from manter);
