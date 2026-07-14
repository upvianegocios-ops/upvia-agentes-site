-- Projeto: clcyyogtvygpehgcmeyj (VendedorIA / GAS)
-- Campanha de reativacao automatica: intervalo configuravel por loja e
-- controle de envio unico por periodo de inatividade (so reenvia depois
-- que o cliente comprar de novo e ficar inativo outra vez).

ALTER TABLE negocios_gas
  ADD COLUMN IF NOT EXISTS intervalo_reativacao_dias INTEGER DEFAULT 30;

ALTER TABLE dados_clientes_gas
  ADD COLUMN IF NOT EXISTS ultima_reativacao_enviada TIMESTAMPTZ;
