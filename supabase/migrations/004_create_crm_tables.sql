-- Migração 004: Criar tabelas de CRM
-- Data: 2026-05-29
-- Motivo: Sistema de CRM por plano (Light/Plus/Premium) implementado no AtendentIA

-- Tabela de ações do CRM (log de todas as mensagens enviadas)
CREATE TABLE IF NOT EXISTS public.crm_acoes (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id   TEXT NOT NULL,
  telefone_cliente TEXT NOT NULL,
  estagio_funil    TEXT,
  acao             TEXT NOT NULL,
  mensagem_enviada TEXT,
  respondeu        BOOLEAN DEFAULT false,
  data_acao        TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_crm_acoes_tenant_telefone
  ON public.crm_acoes(tenant_id, telefone_cliente);

CREATE INDEX IF NOT EXISTS idx_crm_acoes_data
  ON public.crm_acoes(data_acao DESC);

-- Tabela de funil de clientes (estágio de cada cliente por tenant)
CREATE TABLE IF NOT EXISTS public.crm_funil (
  id                       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id                TEXT NOT NULL,
  telefone_cliente         TEXT NOT NULL,
  nome_cliente             TEXT,
  estagio_atual            TEXT DEFAULT 'LEAD',
  estagio_anterior         TEXT,
  data_ultimo_agendamento  TIMESTAMP,
  total_agendamentos       INTEGER DEFAULT 0,
  valor_acumulado          DECIMAL(10,2) DEFAULT 0,
  updated_at               TIMESTAMP DEFAULT NOW(),
  UNIQUE(tenant_id, telefone_cliente)
);

-- Tabela de campanhas CRM (controle de disparos)
CREATE TABLE IF NOT EXISTS public.crm_campanhas (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id         TEXT NOT NULL,
  nome_campanha     TEXT NOT NULL,
  tipo              TEXT NOT NULL,       -- 'light_reativacao', 'plus_sequencia', 'premium_funil'
  total_enviados    INTEGER DEFAULT 0,
  total_responderam INTEGER DEFAULT 0,
  data_disparo      TIMESTAMP DEFAULT NOW()
);

-- Verificar estrutura criada
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('crm_acoes', 'crm_funil', 'crm_campanhas')
ORDER BY table_name, ordinal_position;
