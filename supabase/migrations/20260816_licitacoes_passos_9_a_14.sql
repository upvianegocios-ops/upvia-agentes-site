-- Licitações IA — Passos 9 a 14 (export de dados, redator de contrato, monitor de
-- documentos de habilitação, monitor de homologação, alerta de prazo fatal, pontos de
-- atenção no resumo). Ver plano completo em C:\Users\isaqu\.claude\plans\soft-herding-feather.md

-- Correção transversal (pré-requisito Passos 9/12/14): usuario_id direto nas tabelas que hoje
-- só têm perfil_id/resumo_id nullable -- sem isso, resumos/propostas/fornecedores criados via
-- Orquestrador (sem perfil salvo) não têm como ser filtrados com segurança por usuário.
ALTER TABLE public.licitacoes_resumos
  ADD COLUMN IF NOT EXISTS usuario_id UUID REFERENCES public.licitacoes_usuarios(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS resultado TEXT NOT NULL DEFAULT 'pendente'
    CHECK (resultado IN ('pendente', 'vencida', 'perdida')),
  ADD COLUMN IF NOT EXISTS pontos_atencao TEXT;

ALTER TABLE public.licitacoes_propostas
  ADD COLUMN IF NOT EXISTS usuario_id UUID REFERENCES public.licitacoes_usuarios(id) ON DELETE CASCADE;

ALTER TABLE public.licitacoes_fornecedores_candidatos
  ADD COLUMN IF NOT EXISTS usuario_id UUID REFERENCES public.licitacoes_usuarios(id) ON DELETE CASCADE;

-- Passo 10: rascunho de minuta de contrato preenchida (nunca documento final assinável)
CREATE TABLE IF NOT EXISTS public.licitacoes_contratos (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  resumo_id         UUID        NOT NULL REFERENCES public.licitacoes_resumos(id) ON DELETE CASCADE,
  perfil_id         UUID        REFERENCES public.licitacoes_perfis_busca(id) ON DELETE CASCADE,
  usuario_id        UUID        REFERENCES public.licitacoes_usuarios(id) ON DELETE CASCADE,
  conteudo_contrato TEXT,
  status            TEXT        NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'revisado')),
  criado_em         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Passo 11: documentos de habilitação e validade, monitorados pelo cron diário
CREATE TABLE IF NOT EXISTS public.licitacoes_documentos_habilitacao (
  id             UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id     UUID        NOT NULL REFERENCES public.licitacoes_usuarios(id) ON DELETE CASCADE,
  tipo_documento TEXT        NOT NULL,
  data_validade  DATE        NOT NULL,
  atualizado_em  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (usuario_id, tipo_documento)
);

-- RLS (mesmo padrão já usado em todo o projeto: liga, sem policy de anon -- só N8N acessa)
ALTER TABLE public.licitacoes_contratos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licitacoes_documentos_habilitacao ENABLE ROW LEVEL SECURITY;
