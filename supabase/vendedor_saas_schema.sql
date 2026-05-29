-- =============================================================================
-- VendedorIA SaaS — Multi-Tenant — Schema Completo
-- Projeto: clcyyogtvygpehgcmeyj.supabase.co
-- Gerado em: 2026-05-29
-- Arquiteto: Claude Sonnet 4.6
--
-- Tabelas:
--   1. clientes_sistema     — tenants (negócios cadastrados)
--   2. dados_cliente        — clientes do tenant + estado de conversa
--   3. n8n_chat_histories   — memória de conversas (Langchain/n8n)
--   4. carrinho_abandonado  — follow-up de abandono de carrinho
--   5. followup_clientes    — follow-up geral de clientes
--   6. professionals        — profissionais por tenant
--   7. services             — catálogo de serviços por tenant
--   8. conversas            — cabeçalho de conversas WhatsApp
--   9. mensagens            — histórico de mensagens por conversa
--  10. prospectos           — base de prospecção (outbound)
--  11. upvia_log            — log de eventos do sistema
--  12. crm_funil            — estágio CRM por cliente por tenant
--  13. crm_acoes            — log de ações CRM
--  14. crm_campanhas        — campanhas disparadas
-- =============================================================================

-- Desabilitar RLS globalmente (conforme requisito)
-- (cada CREATE TABLE não terá ENABLE ROW LEVEL SECURITY)

-- =============================================================================
-- 1. CLIENTES_SISTEMA — Tenants (negócios/empresas clientes da plataforma)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.clientes_sistema (
  id                    UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id             TEXT        GENERATED ALWAYS AS (id::text) STORED,

  -- Identificação do negócio
  nome_empresa          TEXT        NOT NULL,
  nome_proprietario     TEXT,
  telefone              TEXT,
  endereco              TEXT,

  -- WhatsApp / Evolution API
  instancia_whatsapp    TEXT        NOT NULL UNIQUE,
  evo_api_url           TEXT        DEFAULT 'https://evo.upviaagentes.com',
  evo_api_key           TEXT,

  -- IA / Atendimento
  nome_atendente_ia     TEXT        DEFAULT 'Assistente',
  tom_voz               TEXT        DEFAULT 'Consultiva, calorosa e persuasiva',
  horario_funcionamento TEXT        DEFAULT 'Horário comercial',
  formas_pagamento      TEXT,
  informacoes_extras    TEXT,

  -- Catálogo (JSON ou Sheets)
  "tabela-serviços+tempo+preço" TEXT,          -- coluna legada (compatibilidade)
  servicos              TEXT,                  -- coluna nova (JSON array)
  profissionais         TEXT,                  -- JSON array de profissionais
  google_sheet_id       TEXT,                  -- ID do Google Sheet do catálogo
  catalogo_sheets_id    TEXT,                  -- alias legado

  -- Google Calendar
  default_calendar      TEXT,

  -- Vendas / Pagamentos
  link_vendas           TEXT,
  tipo_produto          TEXT        DEFAULT 'fisico',  -- 'fisico','servico','infoproduto','digital'
  chave_pix             TEXT,
  tipo_chave_pix        TEXT        DEFAULT 'cpf',
  nome_titular_pix      TEXT,
  banco_pix             TEXT,
  aceita_cartao         BOOLEAN     DEFAULT false,
  link_checkout         TEXT,
  msg_pos_venda         TEXT,

  -- Plano SaaS
  plano                 TEXT        DEFAULT 'light',   -- 'light','pro','premium'
  status                TEXT        DEFAULT 'ativo',   -- 'ativo','inativo','trial'
  data_criacao          TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_clientes_sistema_instancia
  ON public.clientes_sistema(instancia_whatsapp);

CREATE INDEX IF NOT EXISTS idx_clientes_sistema_status
  ON public.clientes_sistema(status);

CREATE INDEX IF NOT EXISTS idx_clientes_sistema_plano
  ON public.clientes_sistema(plano);

-- =============================================================================
-- 2. DADOS_CLIENTE — Estado de conversa e dados dos clientes do tenant
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.dados_cliente (
  id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  telefone            TEXT        NOT NULL UNIQUE,
  session_id          TEXT,
  instancia_whatsapp  TEXT,                             -- tenant identificador
  message             TEXT,                             -- última mensagem
  nome_cliente        TEXT,

  -- Controle de atendimento humano
  humano_assumiu      BOOLEAN     DEFAULT false,
  humano_assumiu_em   TIMESTAMP,
  ia_ativa            BOOLEAN     DEFAULT true,

  -- CRM básico
  recuperado          BOOLEAN     DEFAULT false,
  estagio_crm         TEXT        DEFAULT 'LEAD',

  -- Timestamps
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dados_cliente_instancia_updated
  ON public.dados_cliente(instancia_whatsapp, updated_at);

CREATE INDEX IF NOT EXISTS idx_dados_cliente_session
  ON public.dados_cliente(session_id);

-- =============================================================================
-- 3. N8N_CHAT_HISTORIES — Memória de conversas para Langchain (Postgres Memory)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.n8n_chat_histories (
  id          SERIAL      PRIMARY KEY,
  session_id  TEXT        NOT NULL,
  message     JSONB       NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_n8n_chat_session
  ON public.n8n_chat_histories(session_id);

CREATE INDEX IF NOT EXISTS idx_n8n_chat_created
  ON public.n8n_chat_histories(session_id, created_at DESC);

-- =============================================================================
-- 4. CARRINHO_ABANDONADO — Follow-up de clientes que não finalizaram compra
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.carrinho_abandonado (
  id            BIGSERIAL   PRIMARY KEY,
  telefone      TEXT        NOT NULL,
  session_id    TEXT,
  instancia     TEXT        NOT NULL,
  ultima_msg    TEXT,
  status        TEXT        DEFAULT 'ativo',   -- 'ativo','convertido','desistiu'
  followup_1h   BOOLEAN     DEFAULT false,
  followup_6h   BOOLEAN     DEFAULT false,
  followup_24h  BOOLEAN     DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(telefone, instancia)
);

CREATE INDEX IF NOT EXISTS idx_carrinho_status_updated
  ON public.carrinho_abandonado(status, updated_at);

CREATE INDEX IF NOT EXISTS idx_carrinho_instancia
  ON public.carrinho_abandonado(instancia);

-- =============================================================================
-- 5. FOLLOWUP_CLIENTES — Follow-up geral (AtendentIA Multi-Atendimento)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.followup_clientes (
  id              UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id       TEXT        NOT NULL,
  whatsapp        TEXT        NOT NULL,
  nome_cliente    TEXT,

  -- Controle de estado
  encerrado       BOOLEAN     DEFAULT false,
  enviou_ticket   BOOLEAN     DEFAULT false,
  bloqueado       BOOLEAN     DEFAULT false,

  -- Dados do follow-up
  ultima_msg      TEXT,
  estagio         TEXT        DEFAULT 'inicial',
  tentativas      INTEGER     DEFAULT 0,

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, whatsapp)
);

CREATE INDEX IF NOT EXISTS idx_followup_tenant_whatsapp
  ON public.followup_clientes(tenant_id, whatsapp);

CREATE INDEX IF NOT EXISTS idx_followup_encerrado
  ON public.followup_clientes(encerrado, updated_at);

-- =============================================================================
-- 6. PROFESSIONALS — Profissionais por tenant
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.professionals (
  id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id           TEXT        NOT NULL
                        REFERENCES public.clientes_sistema(id::text)
                        ON DELETE CASCADE
                        DEFERRABLE INITIALLY DEFERRED,
  nome                TEXT        NOT NULL,
  google_calendar_id  TEXT,
  especialidade       TEXT,
  telefone            TEXT,
  ativo               BOOLEAN     DEFAULT true,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_professionals_tenant
  ON public.professionals(tenant_id);

CREATE INDEX IF NOT EXISTS idx_professionals_ativo
  ON public.professionals(tenant_id, ativo);

-- =============================================================================
-- 7. SERVICES — Catálogo de serviços por tenant
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.services (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id        TEXT        NOT NULL,
  nome             TEXT        NOT NULL,
  descricao        TEXT,
  preco            NUMERIC(10,2),
  duracao_minutos  INTEGER,
  foto_url         TEXT,
  categoria        TEXT,
  ativo            BOOLEAN     DEFAULT true,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_services_tenant
  ON public.services(tenant_id);

CREATE INDEX IF NOT EXISTS idx_services_tenant_ativo
  ON public.services(tenant_id, ativo);

-- =============================================================================
-- 8. CONVERSAS — Cabeçalho de conversas WhatsApp por tenant
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.conversas (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id         TEXT        NOT NULL,
  whatsapp_cliente  TEXT        NOT NULL,
  nome_cliente      TEXT,
  instancia         TEXT,
  canal             TEXT        DEFAULT 'whatsapp',
  status            TEXT        DEFAULT 'aberta',  -- 'aberta','encerrada','aguardando_humano'
  ultima_mensagem   TEXT,
  updated_at        TIMESTAMPTZ DEFAULT NOW(),
  created_at        TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, whatsapp_cliente)
);

CREATE INDEX IF NOT EXISTS idx_conversas_tenant
  ON public.conversas(tenant_id);

CREATE INDEX IF NOT EXISTS idx_conversas_whatsapp
  ON public.conversas(tenant_id, whatsapp_cliente);

CREATE INDEX IF NOT EXISTS idx_conversas_updated
  ON public.conversas(updated_at DESC);

-- =============================================================================
-- 9. MENSAGENS — Histórico de mensagens por conversa
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.mensagens (
  id           UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  conversa_id  UUID        NOT NULL
                 REFERENCES public.conversas(id)
                 ON DELETE CASCADE,
  tenant_id    TEXT        NOT NULL,
  role         TEXT        NOT NULL CHECK (role IN ('user','assistant','system')),
  conteudo     TEXT        NOT NULL,
  media_url    TEXT,
  media_type   TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mensagens_conversa
  ON public.mensagens(conversa_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_mensagens_tenant
  ON public.mensagens(tenant_id);

-- =============================================================================
-- 10. PROSPECTOS — Base de prospecção outbound
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.prospectos (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  nome_empresa      TEXT,
  nicho             TEXT,
  whatsapp          TEXT,
  site              TEXT,
  cidade            TEXT,
  estado            TEXT,
  anuncio_ativo     BOOLEAN     DEFAULT false,
  mensagem_enviada  BOOLEAN     DEFAULT false,
  status            TEXT        DEFAULT 'novo',  -- 'novo','contatado','interesse','descartado','convertido'
  respondeu         BOOLEAN     DEFAULT false,
  observacoes       TEXT,
  fonte             TEXT,                         -- 'manual','scraping','ads'
  data_criacao      TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prospectos_status
  ON public.prospectos(status);

CREATE INDEX IF NOT EXISTS idx_prospectos_nicho
  ON public.prospectos(nicho, status);

CREATE INDEX IF NOT EXISTS idx_prospectos_whatsapp
  ON public.prospectos(whatsapp);

-- =============================================================================
-- 11. UPVIA_LOG — Log centralizado de eventos do sistema
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.upvia_log (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id   TEXT,
  evento      TEXT        NOT NULL,  -- 'mensagem_recebida','ia_respondeu','carrinho_salvo','followup_enviado'...
  detalhes    JSONB,
  nivel       TEXT        DEFAULT 'info',  -- 'info','warn','error'
  instancia   TEXT,
  telefone    TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_upvia_log_tenant
  ON public.upvia_log(tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_upvia_log_evento
  ON public.upvia_log(evento, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_upvia_log_nivel
  ON public.upvia_log(nivel) WHERE nivel IN ('warn','error');

-- =============================================================================
-- 12. CRM_FUNIL — Estágio do funil de vendas por cliente por tenant
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.crm_funil (
  id                        UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id                 TEXT        NOT NULL,
  telefone_cliente          TEXT        NOT NULL,
  nome_cliente              TEXT,
  estagio_atual             TEXT        DEFAULT 'LEAD',
    -- 'LEAD','INTERESSADO','AGENDOU','FREQUENTE','VIP'
  estagio_anterior          TEXT,
  data_ultimo_agendamento   TIMESTAMP,
  total_agendamentos        INTEGER     DEFAULT 0,
  valor_acumulado           NUMERIC(10,2) DEFAULT 0,
  score_vip                 INTEGER     DEFAULT 0,
  updated_at                TIMESTAMPTZ DEFAULT NOW(),
  created_at                TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, telefone_cliente)
);

CREATE INDEX IF NOT EXISTS idx_crm_funil_tenant
  ON public.crm_funil(tenant_id);

CREATE INDEX IF NOT EXISTS idx_crm_funil_estagio
  ON public.crm_funil(tenant_id, estagio_atual);

CREATE INDEX IF NOT EXISTS idx_crm_funil_updated
  ON public.crm_funil(updated_at DESC);

-- =============================================================================
-- 13. CRM_ACOES — Log de ações executadas pelo CRM
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.crm_acoes (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id         TEXT        NOT NULL,
  telefone_cliente  TEXT        NOT NULL,
  estagio_funil     TEXT,
  acao              TEXT        NOT NULL,
  mensagem_enviada  TEXT,
  respondeu         BOOLEAN     DEFAULT false,
  data_acao         TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_crm_acoes_tenant_telefone
  ON public.crm_acoes(tenant_id, telefone_cliente);

CREATE INDEX IF NOT EXISTS idx_crm_acoes_data
  ON public.crm_acoes(data_acao DESC);

-- =============================================================================
-- 14. CRM_CAMPANHAS — Campanhas segmentadas disparadas pelo CRM
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.crm_campanhas (
  id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id           TEXT        NOT NULL,
  nome_campanha       TEXT        NOT NULL,
  tipo                TEXT        NOT NULL,
    -- 'reativacao','sequencia_interesse','fidelidade','vip_exclusivo'
  estagio_alvo        TEXT,
  total_enviados      INTEGER     DEFAULT 0,
  total_responderam   INTEGER     DEFAULT 0,
  taxa_resposta       NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE WHEN total_enviados > 0
         THEN ROUND((total_responderam::numeric / total_enviados) * 100, 2)
         ELSE 0 END
  ) STORED,
  data_disparo        TIMESTAMPTZ DEFAULT NOW(),
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_crm_campanhas_tenant
  ON public.crm_campanhas(tenant_id, data_disparo DESC);

-- =============================================================================
-- TRIGGER: updated_at automático
-- =============================================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger nas tabelas com updated_at
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'clientes_sistema','dados_cliente','carrinho_abandonado',
    'followup_clientes','professionals','services',
    'conversas','prospectos','crm_funil'
  ] LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%I_updated_at ON public.%I;
       CREATE TRIGGER trg_%I_updated_at
         BEFORE UPDATE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();',
      t, t, t, t
    );
  END LOOP;
END;
$$;

-- =============================================================================
-- VERIFICAÇÃO FINAL
-- =============================================================================
SELECT
  t.table_name,
  COUNT(c.column_name) AS colunas,
  pg_size_pretty(pg_total_relation_size(('public.' || t.table_name)::regclass)) AS tamanho
FROM information_schema.tables t
JOIN information_schema.columns c
  ON c.table_name = t.table_name AND c.table_schema = 'public'
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
  AND t.table_name IN (
    'clientes_sistema','dados_cliente','n8n_chat_histories',
    'carrinho_abandonado','followup_clientes','professionals',
    'services','conversas','mensagens','prospectos',
    'upvia_log','crm_funil','crm_acoes','crm_campanhas'
  )
GROUP BY t.table_name
ORDER BY t.table_name;
