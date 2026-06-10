-- =============================================================================
-- UPVIA_PROSPECCAO — Leads captados via Meta Ad Library (prospecção AtendentIA)
-- Projeto: clcyyogtvygpehgcmeyj.supabase.co
-- Aplicado em: 2026-06-10 (via execução direta no banco)
-- =============================================================================
CREATE TABLE IF NOT EXISTS upvia_prospeccao (
  id SERIAL PRIMARY KEY,
  page_name TEXT,
  page_id TEXT UNIQUE,
  nicho TEXT,
  telefone TEXT,
  texto_anuncio TEXT,
  status TEXT DEFAULT 'novo',
  data_captacao TIMESTAMP DEFAULT NOW(),
  data_abordagem TIMESTAMP,
  instancia TEXT,
  observacoes TEXT
);
