-- Projeto: clcyyogtvygpehgcmeyj (VendedorIA / GAS)
-- Estende a tabela dados_clientes_gas (ja existente, usada pelo workflow
-- "GAS - Atendente Cliente" para controlar a etapa da conversa) com campos
-- de CRM persistente, para permitir futuramente uma campanha de reativacao
-- (prospeccao ativa 30 dias apos a ultima compra).
--
-- Decisao: estender a tabela existente em vez de criar uma nova
-- "dados_clientes_gas" (colidiria com a que ja existe) ou uma tabela
-- paralela com outro nome (duplicaria a identidade do cliente, chaveada
-- por negocio_id + remote_jid, em duas tabelas diferentes).

ALTER TABLE dados_clientes_gas
  ADD COLUMN IF NOT EXISTS cliente_telefone TEXT,
  ADD COLUMN IF NOT EXISTS ultimo_endereco TEXT,
  ADD COLUMN IF NOT EXISTS ultimo_cep TEXT,
  ADD COLUMN IF NOT EXISTS data_ultima_compra TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS produtos_ja_comprados JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS total_pedidos INTEGER DEFAULT 0;
