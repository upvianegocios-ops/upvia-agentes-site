-- Migração: Adicionar colunas de controle de atendimento humano
-- Tabela: dados_cliente
-- Data: 2026-05-28
-- Motivo: Bug fix — workflow AtendentIA usava humano_assumiu, humano_assumiu_em
--         e ia_ativa mas essas colunas nunca foram criadas na tabela.

-- Adicionar coluna que indica se humano assumiu o atendimento
ALTER TABLE public.dados_cliente
  ADD COLUMN IF NOT EXISTS humano_assumiu BOOLEAN DEFAULT false;

-- Adicionar coluna com timestamp de quando o humano assumiu
ALTER TABLE public.dados_cliente
  ADD COLUMN IF NOT EXISTS humano_assumiu_em TIMESTAMP;

-- Adicionar coluna que indica se a IA está ativa para este contato
-- true = IA responde normalmente | false = IA pausada (humano assumiu)
ALTER TABLE public.dados_cliente
  ADD COLUMN IF NOT EXISTS ia_ativa BOOLEAN DEFAULT true;

-- Verificar estrutura final
SELECT
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'dados_cliente'
ORDER BY ordinal_position;
