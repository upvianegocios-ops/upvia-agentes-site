-- Projeto: clcyyogtvygpehgcmeyj (VendedorIA / GAS)
-- Adiciona estimativa de tempo de entrega (ETA) calculada por Haversine,
-- sem depender de API paga (Distance Matrix/Directions).

ALTER TABLE pedidos_gas
  ADD COLUMN IF NOT EXISTS eta_estimado_min INTEGER,
  ADD COLUMN IF NOT EXISTS eta_estimado_texto TEXT;
