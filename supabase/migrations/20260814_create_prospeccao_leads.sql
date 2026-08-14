-- Prospecção Leads (Meta Ad Library) — schema inicial
-- Projeto Supabase: qzgokcxvyasftuqgqonn (mesmo do Jonas/Licitacoes IA) — reaproveitado,
-- prefixo prospeccao_ pra isolar visualmente das tabelas licitacoes_*.
-- (mudanca de projeto pedida explicitamente -- especificacao original dizia clcyyogtvygpehgcmeyj)
--
-- Só entram no funil anúncios de clique-pra-WhatsApp (CTWA) -- é assim que dá pra
-- extrair o telefone de forma confiável. telefone_origem = 'manual' é o caminho de
-- excecao (quando a extracao automatica falhar num anuncio CTWA), nao a regra.

CREATE TABLE IF NOT EXISTS public.prospeccao_nichos (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  nome              TEXT        NOT NULL,
  palavras_chave    TEXT[]      NOT NULL DEFAULT '{}',  -- termos de busca na Ad Library (pode ter varios por nicho)
  ativo             BOOLEAN     NOT NULL DEFAULT true,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.prospeccao_leads (
  id                        UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  nicho_id                  UUID        NOT NULL REFERENCES public.prospeccao_nichos(id) ON DELETE CASCADE,
  ad_archive_id             TEXT        NOT NULL UNIQUE,  -- dedup nativo (ON CONFLICT DO NOTHING)
  page_id                   TEXT,
  page_name                 TEXT,
  ad_creative_body          TEXT,
  ad_snapshot_url           TEXT,
  ad_delivery_start_time    TIMESTAMPTZ,
  telefone                  TEXT,        -- extraido do anuncio CTWA, ou preenchido manual como excecao
  telefone_origem           TEXT         CHECK (telefone_origem IN ('automatico', 'manual')),
  mensagem_personalizada    TEXT,
  status                    TEXT         NOT NULL DEFAULT 'novo'
                               CHECK (status IN ('novo', 'pronto_para_contato', 'contatado')),
  data_contatado            TIMESTAMPTZ,
  contatado_por             TEXT         CHECK (contatado_por IN ('elisa', 'jean')),
  created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prospeccao_leads_status ON public.prospeccao_leads(status);
CREATE INDEX IF NOT EXISTS idx_prospeccao_leads_nicho ON public.prospeccao_leads(nicho_id);

CREATE TABLE IF NOT EXISTS public.prospeccao_config (
  id                     INT  PRIMARY KEY DEFAULT 1,
  limite_diario_contato  INT  NOT NULL DEFAULT 20,  -- alerta visual no CRM, nao trava tecnica
  leads_por_rodada       INT  NOT NULL DEFAULT 25,  -- teto de leads novos inseridos por execucao do cron
  CONSTRAINT singleton CHECK (id = 1)
);
INSERT INTO public.prospeccao_config (id, limite_diario_contato, leads_por_rodada)
VALUES (1, 20, 25) ON CONFLICT (id) DO NOTHING;

-- Nichos iniciais ------------------------------------------------------------
-- "Advogado" usa 3 termos especificos (trabalhista/familia/previdenciario) em vez de
-- um generico "advogado", pra nao trazer ruido de advocacia corporativa/empresarial.

INSERT INTO public.prospeccao_nichos (nome, palavras_chave) VALUES
  ('Estética', ARRAY['clínica de estética', 'estética facial', 'estética corporal']),
  ('Salão de beleza', ARRAY['salão de beleza']),
  ('Barbearia', ARRAY['barbearia']),
  ('Clínica odontológica', ARRAY['clínica odontológica', 'consultório dentista']),
  ('Clínicas em geral', ARRAY['clínica médica']),
  ('Advogado', ARRAY['advogado trabalhista', 'advogado de família', 'advogado previdenciário']),
  ('Fisioterapia', ARRAY['clínica de fisioterapia', 'fisioterapeuta']),
  ('Estética capilar/tricologia', ARRAY['tricologia', 'estética capilar']),
  ('Psicólogo/psicoterapeuta', ARRAY['psicólogo', 'psicoterapeuta']),
  ('Personal trainer', ARRAY['personal trainer']),
  ('Estúdio de pilates/yoga', ARRAY['estúdio de pilates', 'estúdio de yoga']),
  ('Veterinária/pet shop', ARRAY['clínica veterinária', 'pet shop banho e tosa']),
  ('Nutricionista', ARRAY['nutricionista']),
  ('Estética automotiva', ARRAY['estética automotiva']),
  ('Dedetização', ARRAY['dedetização']),
  ('Limpeza pós-obra', ARRAY['limpeza pós-obra']),
  ('Manutenção de ar-condicionado', ARRAY['manutenção de ar condicionado', 'instalação de ar condicionado']),
  ('Fotógrafo de eventos', ARRAY['fotógrafo de eventos'])
ON CONFLICT DO NOTHING;

-- Row Level Security ---------------------------------------------------------
-- Pagina CRM e sem login -- a anon key precisa ler tudo e atualizar status/telefone/
-- contatado direto. Sem INSERT/DELETE via anon (isso e so o N8N com service_role).

ALTER TABLE public.prospeccao_nichos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prospeccao_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prospeccao_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY prospeccao_nichos_select_anon ON public.prospeccao_nichos
  FOR SELECT TO anon USING (true);

CREATE POLICY prospeccao_leads_select_anon ON public.prospeccao_leads
  FOR SELECT TO anon USING (true);

CREATE POLICY prospeccao_leads_update_anon ON public.prospeccao_leads
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY prospeccao_config_select_anon ON public.prospeccao_config
  FOR SELECT TO anon USING (true);
