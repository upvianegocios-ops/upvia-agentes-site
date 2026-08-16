-- Passo 20: coluna de favorito por licitacao -- usada pra filtro "Favoritas" no
-- Escritorio de Licitacao IA (site) e pela tool_favoritar do Orquestrador (WhatsApp).
ALTER TABLE public.licitacoes_resumos
  ADD COLUMN IF NOT EXISTS favorito BOOLEAN NOT NULL DEFAULT false;
