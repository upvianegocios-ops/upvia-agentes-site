-- INCIDENTE: Agente Redator de Contrato disparou pra uma licitacao (Processo
-- Administrativo 152/2026, Santa Barbara do Sul/RS, prazo_proposta 2026-08-24)
-- SEM nenhuma vitoria real confirmada -- prazo ainda no futuro, nenhuma disputa
-- aconteceu. Nao houve dado fabricado (valores continuaram como placeholder),
-- mas a ferramenta rodou fora de ordem porque nada no sistema impedia isso.
--
-- Corrige na raiz: maquina de estados explicita. Nenhuma ferramenta pode avancar
-- fase sozinha -- toda transicao critica exige confirmacao explicita do usuario
-- via WhatsApp, ou (pra vencida/perdida) confirmacao real do PNCP via Monitor de
-- Homologacao. tool_redigir_contrato so roda com fase_atual = 'vencida'.

ALTER TABLE public.licitacoes_resumos
  ADD COLUMN IF NOT EXISTS fase_atual TEXT NOT NULL DEFAULT 'identificada'
    CHECK (fase_atual IN (
      'identificada',        -- resumo criado, ainda nao processado
      'analisada',           -- Resumidor extraiu os dados do edital
      'proposta_enviada',    -- rascunho de proposta gerado a pedido do usuario
      'aguardando_resultado',-- proposta (rascunho) entregue, esperando prazo/resultado
      'vencida',             -- confirmado (PNCP real ou usuario) que o usuario venceu
      'perdida',             -- confirmado que o usuario nao venceu
      'proposta_readequada', -- reservado p/ feature futura de readequacao de proposta
      'contrato_gerado'      -- rascunho de contrato ja gerado (so possivel a partir de "vencida")
    ));

-- backfill dos resumos que ja existem, refletindo o estado real ja observavel
-- (nenhum esta "vencida"/"perdida" de verdade, confirmado no diagnostico do incidente):
UPDATE public.licitacoes_resumos r SET fase_atual = 'aguardando_resultado'
  WHERE resultado = 'pendente'
    AND EXISTS (SELECT 1 FROM public.licitacoes_propostas p WHERE p.resumo_id = r.id);
UPDATE public.licitacoes_resumos SET fase_atual = 'analisada'
  WHERE resultado = 'pendente' AND fase_atual = 'identificada' AND objeto_resumo IS NOT NULL;
