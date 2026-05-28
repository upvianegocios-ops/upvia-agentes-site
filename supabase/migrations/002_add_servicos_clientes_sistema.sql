-- Migração: Adicionar coluna servicos em clientes_sistema
-- Data: 2026-05-28
-- Motivo: Bug fix — workflows usavam "tabela-serviços+tempo+preço" (nome inválido)
--         O nome correto/padrão da coluna é simplesmente "servicos".
--         Corrigido em: AtendentIA, VendedorIA, Cadastro Automático.

ALTER TABLE public.clientes_sistema
  ADD COLUMN IF NOT EXISTS servicos TEXT;

-- Verificar colunas relacionadas ao conteúdo do negócio
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'clientes_sistema'
  AND column_name IN ('servicos', 'profissionais', 'formas_pagamento', 'informacoes_extras')
ORDER BY column_name;
