-- Migração 003: Adicionar colunas de suporte ao CRM em dados_cliente
-- Data: 2026-05-29
-- Motivo: CRM precisa de instancia_whatsapp para multi-tenancy correto
--         e updated_at para detectar inatividade por data

ALTER TABLE public.dados_cliente
  ADD COLUMN IF NOT EXISTS instancia_whatsapp TEXT;

ALTER TABLE public.dados_cliente
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Índice para queries de inatividade por instância
CREATE INDEX IF NOT EXISTS idx_dados_cliente_instancia_updated
  ON public.dados_cliente(instancia_whatsapp, updated_at);

-- Atualizar registros existentes (se instancia puder ser inferida da sessão)
-- ATENÇÃO: Execute manualmente se quiser migrar dados históricos
-- UPDATE public.dados_cliente SET updated_at = NOW() WHERE updated_at IS NULL;
