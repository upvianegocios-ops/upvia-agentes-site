-- Expansão do Licitações IA: agentes especializados (Resumidor de Edital, Redator de
-- Propostas, Buscador de Fornecedores) + Orquestrador Central via WhatsApp.
-- Ver plano completo em C:\Users\isaqu\.claude\plans\soft-herding-feather.md

-- Resumos estruturados de edital, gerados pelo Agente Resumidor
CREATE TABLE IF NOT EXISTS public.licitacoes_resumos (
  id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  perfil_id           UUID        REFERENCES public.licitacoes_perfis_busca(id) ON DELETE CASCADE,
  pncp_id             TEXT        NOT NULL,
  objeto_resumo       TEXT,
  tipo_disputa        TEXT        CHECK (tipo_disputa IN ('pregao_eletronico', 'dispensa')),
  valor_estimado      NUMERIC,
  prazo_proposta      TIMESTAMPTZ,
  prazo_entrega       TEXT,
  documentos_exigidos TEXT,
  tipo_software       TEXT,
  criado_em           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (perfil_id, pncp_id)
);
-- perfil_id fica NULLABLE: o Orquestrador Central permite resumir uma licitação avulsa,
-- digitada na conversa, sem estar ligada a nenhum perfil de busca salvo.

-- Dados da empresa (preenchimento manual depois — MEI do Jonas e MEI/CNPJ da UpVia)
CREATE TABLE IF NOT EXISTS public.licitacoes_dados_empresa (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id        UUID        NOT NULL REFERENCES public.licitacoes_usuarios(id) ON DELETE CASCADE,
  razao_social      TEXT,
  cnpj              TEXT,
  endereco          TEXT,
  responsavel_legal TEXT,
  criado_em         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (usuario_id)
);

-- Rascunhos de proposta, gerados pelo Agente Redator — nunca enviados/submetidos automaticamente
CREATE TABLE IF NOT EXISTS public.licitacoes_propostas (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  resumo_id         UUID        NOT NULL REFERENCES public.licitacoes_resumos(id) ON DELETE CASCADE,
  perfil_id         UUID        REFERENCES public.licitacoes_perfis_busca(id) ON DELETE CASCADE,
  conteudo_proposta TEXT,
  valor_ofertado    NUMERIC,
  status            TEXT        NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'revisada', 'enviada')),
  criado_em         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Candidatos a fornecedor, gerados pelo Agente Buscador de Fornecedores — só descoberta,
-- sem confirmar nada, contato/triangulação sempre manual
CREATE TABLE IF NOT EXISTS public.licitacoes_fornecedores_candidatos (
  id              UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  resumo_id       UUID        REFERENCES public.licitacoes_resumos(id) ON DELETE CASCADE,
  nome_fornecedor TEXT,
  site            TEXT,
  contato         TEXT,
  criado_em       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tipo de perfil: define quando preencher tipo_software (nos resumos) e quando disparar
-- o Agente Buscador de Fornecedores (só perfis de produto, nunca de serviço/software)
ALTER TABLE public.licitacoes_perfis_busca
  ADD COLUMN IF NOT EXISTS tipo_perfil TEXT NOT NULL DEFAULT 'produto'
    CHECK (tipo_perfil IN ('produto', 'servico_software'));

-- RLS (mesmo padrão das tabelas existentes: liga, sem policy de anon — só N8N acessa)
ALTER TABLE public.licitacoes_resumos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licitacoes_dados_empresa ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licitacoes_propostas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licitacoes_fornecedores_candidatos ENABLE ROW LEVEL SECURITY;
