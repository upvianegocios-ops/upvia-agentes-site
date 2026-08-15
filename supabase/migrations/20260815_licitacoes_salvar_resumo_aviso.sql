-- Feature: salvar licitação recebida, gerar resumo de documentação/proposta via IA,
-- e avisar quando a sessão de disputa do Pregão Eletrônico estiver prestes a começar.
--
-- licitacoes_resultados_enviados ate agora so guardava perfil_id+pncp_id (so pra
-- deduplicar envios). Estende com o snapshot completo do edital (pra mostrar no
-- mini app sem precisar buscar de novo no PNCP) + os campos de "salvar"/resumo/aviso.

ALTER TABLE public.licitacoes_resultados_enviados
  ADD COLUMN IF NOT EXISTS objeto TEXT,
  ADD COLUMN IF NOT EXISTS orgao TEXT,
  ADD COLUMN IF NOT EXISTS valor NUMERIC,
  ADD COLUMN IF NOT EXISTS uf TEXT,
  ADD COLUMN IF NOT EXISTS municipio TEXT,
  ADD COLUMN IF NOT EXISTS modalidade_nome TEXT,
  ADD COLUMN IF NOT EXISTS link TEXT,
  ADD COLUMN IF NOT EXISTS data_abertura_proposta TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS data_encerramento_proposta TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS salvo BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS resumo_documentacao TEXT,
  ADD COLUMN IF NOT EXISTS resumo_gerado_em TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS aviso_pregao_enviado BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_licitacoes_resultados_enviados_perfil_salvo
  ON public.licitacoes_resultados_enviados(perfil_id) WHERE salvo;

CREATE INDEX IF NOT EXISTS idx_licitacoes_resultados_enviados_aviso_pregao
  ON public.licitacoes_resultados_enviados(data_abertura_proposta)
  WHERE salvo AND NOT aviso_pregao_enviado AND modalidade_nome ILIKE 'Preg%';
