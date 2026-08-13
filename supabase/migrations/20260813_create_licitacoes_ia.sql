-- Migração: Licitações IA — schema inicial
-- Data: 2026-08-13
-- Projeto Supabase: qzgokcxvyasftuqgqonn (mesmo do AtendentIA)
-- Referência de arquitetura: upvia-agentes/licitacoes-ia-arquitetura.md.md
--
-- Auth simples por código WhatsApp (sem Supabase Auth): o mini app nunca fala
-- direto com o Supabase, só com webhooks N8N (que usam a service_role key e por
-- isso ignoram RLS). RLS fica ativado em todas as tabelas mas sem nenhuma policy
-- permissiva -- isso bloqueia qualquer acesso direto via anon/authenticated key,
-- caso ela vaze ou seja usada por engano no front.

CREATE TABLE IF NOT EXISTS public.licitacoes_usuarios (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  nome              TEXT,
  whatsapp_numero   TEXT        NOT NULL UNIQUE,  -- E.164
  instancia_whatsapp TEXT,
  plano             TEXT        NOT NULL DEFAULT 'trial' CHECK (plano IN ('beta', 'trial', 'mensal')),
  ativo             BOOLEAN     NOT NULL DEFAULT true,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.licitacoes_perfis_busca (
  id                      UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id              UUID        NOT NULL REFERENCES public.licitacoes_usuarios(id) ON DELETE CASCADE,
  nome_perfil             TEXT        NOT NULL,
  objeto_palavras_chave   TEXT[]      NOT NULL DEFAULT '{}',
  modalidades             TEXT[]      NOT NULL DEFAULT '{}' CHECK (modalidades <@ ARRAY['pregao_eletronico', 'dispensa']),
  valor_min               NUMERIC,
  valor_max               NUMERIC,
  uf                      TEXT[],
  municipio               TEXT[],
  ativo                   BOOLEAN     NOT NULL DEFAULT true,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_licitacoes_perfis_busca_usuario
  ON public.licitacoes_perfis_busca(usuario_id);

CREATE INDEX IF NOT EXISTS idx_licitacoes_perfis_busca_ativo
  ON public.licitacoes_perfis_busca(ativo) WHERE ativo;

CREATE TABLE IF NOT EXISTS public.licitacoes_resultados_enviados (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  perfil_id   UUID        NOT NULL REFERENCES public.licitacoes_perfis_busca(id) ON DELETE CASCADE,
  pncp_id     TEXT        NOT NULL,  -- numeroControlePNCP
  enviado_em  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (perfil_id, pncp_id)
);

CREATE INDEX IF NOT EXISTS idx_licitacoes_resultados_enviados_perfil
  ON public.licitacoes_resultados_enviados(perfil_id);

-- Login por código WhatsApp ------------------------------------------------

-- Código OTP de 6 dígitos, curta duração, gerado pelo webhook "licitacoes-login-solicitar"
CREATE TABLE IF NOT EXISTS public.licitacoes_codigos_login (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  whatsapp_numero   TEXT        NOT NULL,
  codigo            TEXT        NOT NULL,
  expira_em         TIMESTAMPTZ NOT NULL,
  usado             BOOLEAN     NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_licitacoes_codigos_login_whatsapp
  ON public.licitacoes_codigos_login(whatsapp_numero, usado);

-- Token de sessão, gerado pelo webhook "licitacoes-login-confirmar" após validar o código.
-- Mini app manda esse token em toda chamada seguinte; N8N valida antes de ler/escrever.
CREATE TABLE IF NOT EXISTS public.licitacoes_sessoes (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id  UUID        NOT NULL REFERENCES public.licitacoes_usuarios(id) ON DELETE CASCADE,
  token       TEXT        NOT NULL UNIQUE,
  expira_em   TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_licitacoes_sessoes_token
  ON public.licitacoes_sessoes(token);

-- Row Level Security ---------------------------------------------------------
-- RLS ligado em tudo, sem policies: só a service_role key (usada pelo N8N) passa.

ALTER TABLE public.licitacoes_usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licitacoes_perfis_busca ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licitacoes_resultados_enviados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licitacoes_codigos_login ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licitacoes_sessoes ENABLE ROW LEVEL SECURITY;
