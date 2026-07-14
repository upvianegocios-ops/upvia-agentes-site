-- Projeto: clcyyogtvygpehgcmeyj (VendedorIA / GAS)
-- Preferencia "pegajosa" de resposta em audio por conversa, no
-- GAS - Atendente Cliente. Reseta implicitamente quando a conversa e
-- tratada como nova (mesmo criterio ja usado para saudacao_necessaria:
-- >3h desde a ultima interacao), sem precisar de coluna de expiracao.

ALTER TABLE dados_clientes_gas
  ADD COLUMN IF NOT EXISTS prefere_audio BOOLEAN DEFAULT false;
