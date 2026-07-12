-- Projeto: clcyyogtvygpehgcmeyj (VendedorIA / GAS)
-- Trava de atendimento humano para o workflow "GAS - Atendente Cliente".
-- Chave negocio_id + remote_jid (mesmo padrao ja usado em dados_clientes_gas
-- e na session key do Postgres Chat Memory), diferente do AtendentIA que usa
-- telefone + instancia_whatsapp -- GAS ja usa negocio_id como chave de tenant
-- em todo o schema, entao seguimos a convencao existente.

CREATE TABLE IF NOT EXISTS trava_atendimento_humano_gas (
  id BIGSERIAL PRIMARY KEY,
  negocio_id INTEGER NOT NULL REFERENCES negocios_gas(id),
  remote_jid TEXT NOT NULL,
  humano_assumiu BOOLEAN NOT NULL DEFAULT false,
  humano_assumiu_em TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (negocio_id, remote_jid)
);

CREATE INDEX IF NOT EXISTS idx_trava_atendimento_humano_gas_lookup
  ON trava_atendimento_humano_gas (negocio_id, remote_jid);
