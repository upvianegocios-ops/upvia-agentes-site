-- =============================================================================
-- UPVIA_CRM / UPVIA_INTERACOES — Funil de vendas e historico de contatos da UpVia
-- Projeto: clcyyogtvygpehgcmeyj.supabase.co
-- Aplicado em: 2026-06-10 (via execucao direta no banco)
-- =============================================================================

-- Funil de vendas: lead -> contato -> interessado -> proposta -> trial -> cliente -> perdido
CREATE TABLE IF NOT EXISTS upvia_crm (
  id SERIAL PRIMARY KEY,
  lead_id INTEGER REFERENCES upvia_prospeccao(id),
  telefone TEXT,
  nome TEXT,
  nicho TEXT,
  estagio TEXT DEFAULT 'lead',
  canal_captacao TEXT,
  instancia TEXT,
  ultima_interacao TIMESTAMP DEFAULT NOW(),
  data_entrada TIMESTAMP DEFAULT NOW(),
  observacoes TEXT,
  responsavel TEXT DEFAULT 'Bia', -- 'Bia' = automatico, 'Elisa' ou 'Jean' = assumiu manualmente
  humano_assumiu BOOLEAN DEFAULT false,
  humano_assumiu_em TIMESTAMP
);

-- Historico de interacoes por lead/cliente do funil upvia_crm
CREATE TABLE IF NOT EXISTS upvia_interacoes (
  id SERIAL PRIMARY KEY,
  crm_id INTEGER REFERENCES upvia_crm(id),
  telefone TEXT,
  tipo TEXT, -- 'mensagem_enviada', 'mensagem_recebida', 'reuniao_agendada', 'proposta_enviada'
  conteudo TEXT,
  canal TEXT DEFAULT 'whatsapp',
  data_interacao TIMESTAMP DEFAULT NOW(),
  instancia TEXT
);
