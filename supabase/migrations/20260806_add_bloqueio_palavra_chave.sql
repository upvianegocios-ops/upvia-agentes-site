-- Bloqueio automatico por palavra-chave (nome salvo + conteudo da mensagem)
-- pra contatos institucionais/profissionais (vara, tribunal, advogado
-- parceiro, perito, procurador, etc).
--
-- Contexto: tenant Ariane D'Avila Afonso mantinha uma lista manual em
-- contatos_bloqueados que precisava ser atualizada toda vez que um novo
-- contato profissional aparecia -- inviavel de manter. A IA estava
-- triando/atendendo gente que nao e cliente.
--
-- 2 colunas novas, ambas com default seguro (feature desligada por padrao):
--   bloqueio_por_palavra_chave  -- liga/desliga o recurso. Default FALSE,
--                                   TRUE so pra Ariane nesta primeira rodada.
--   palavras_chave_bloqueio     -- lista de termos separados por virgula,
--                                   checados (sem acento, case-insensitive,
--                                   por borda de palavra -- nao substring
--                                   cru) contra o pushName do contato E o
--                                   texto da mensagem recebida. Qualquer
--                                   match em qualquer uma das duas fontes
--                                   ativa humano_assumiu=true silenciosamente
--                                   (sem nenhuma mensagem automatica) e
--                                   dispara notificacao pro dono.
--
-- Risco conhecido, aceito pelo usuario: "dr."/"dra." continuam com alguma
-- chance de falso positivo (alguem usando a palavra informalmente sem ser
-- advogado, ou contato salvo como "Dr. Fulano" por vaidade sem ser
-- profissional de verdade) -- borda de palavra evita match dentro de outras
-- palavras (ex: "quadra"), mas nao resolve ambiguidade semantica. Ver
-- diagnostico completo na conversa do Claude Code de 2026-08-06.

ALTER TABLE public.clientes_sistema
  ADD COLUMN IF NOT EXISTS bloqueio_por_palavra_chave BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS palavras_chave_bloqueio TEXT;

UPDATE public.clientes_sistema
SET bloqueio_por_palavra_chave = true,
    palavras_chave_bloqueio = 'vara,tribunal,forum,comarca,procurador,procuradoria,advogado,advogada,dr.,dra.,oab,perito,pericia,cartorio,delegacia,ministerio publico,promotoria,juiz,juiza,oficial de justica'
WHERE instancia_whatsapp = 'ariane-d-avila-afonso-advocaci'
RETURNING id, nome_empresa, instancia_whatsapp, bloqueio_por_palavra_chave, palavras_chave_bloqueio;
