-- Projeto: clcyyogtvygpehgcmeyj (VendedorIA / GAS)
-- Comando #promocao do dono: desconto pontual (dispara uma vez pra base)
-- ou programa de fidelidade recorrente (checado a cada confirmar_pedido).

CREATE TABLE IF NOT EXISTS promocoes_gas (
  id BIGSERIAL PRIMARY KEY,
  negocio_id INTEGER NOT NULL REFERENCES negocios_gas(id),
  tipo TEXT NOT NULL CHECK (tipo IN ('desconto_pontual', 'fidelidade')),
  descricao_original TEXT,
  texto_campanha TEXT,
  regra_fidelidade_pedidos INTEGER,
  regra_fidelidade_recompensa TEXT,
  status TEXT NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'confirmada', 'enviada', 'ativa', 'cancelada')),
  criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  executado_em TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_promocoes_gas_negocio_status
  ON promocoes_gas (negocio_id, status);
