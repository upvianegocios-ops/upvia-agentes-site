-- Notificacao automatica de handoff pra atendimento humano (multi-tenant).
--
-- Contexto: hoje quando a IA passa o atendimento pro humano (cliente pediu,
-- trava automatica ativada, IA nao conseguiu resolver, ou -- no caso da
-- Ariane -- toda triagem concluida), o dono do numero nao recebe nenhum
-- alerta ativo, so descobre abrindo o WhatsApp manualmente.
--
-- 4 colunas novas, todas com defaults seguros (nao quebram tenant nenhum
-- que nao for explicitamente configurado):
--   notificar_atendimento_humano  -- liga/desliga as notificacoes padrao
--                                     (trava automatica + cliente pediu humano
--                                     + falha detectada). Default TRUE: so
--                                     melhora a experiencia, nao restringe nada.
--   notificar_toda_interacao      -- notifica em TODA resposta da IA, nao so
--                                     em handoff -- modelo "sempre revisao
--                                     humana antes de responder ao cliente".
--                                     Default FALSE, TRUE so pra Ariane (ela
--                                     nunca deixa a IA agendar sozinha, ver
--                                     REGRAS ABSOLUTAS -- AGENDAMENTO no
--                                     prompt dela).
--   palavras_urgencia             -- frases separadas por virgula, checadas
--                                     (case-insensitive, contains) na resposta
--                                     da IA. Se der match, notificacao IMEDIATA
--                                     com prefixo urgente, independente dos
--                                     outros 2 flags. Pra Ariane: a IA ja e
--                                     instruida (secao "CLASSIFICACAO DA
--                                     URGENCIA" do prompt dela) a responder
--                                     literalmente "situacao urgente" quando
--                                     classifica um caso como prioridade
--                                     maxima -- reaproveita essa confirmacao
--                                     em vez de tentar re-detectar prisao em
--                                     flagrante/mandado/etc diretamente (a IA
--                                     ja tem o contexto completo pra isso).
--   palavras_falha_atendimento    -- frases indicando que a IA nao conseguiu
--                                     resolver algo sozinha, checadas na
--                                     resposta dela. Default NULL (nenhuma
--                                     notificacao de falha ate o tenant
--                                     configurar suas proprias frases, ja que
--                                     depende de como cada IA formula isso).
--
-- Destino da notificacao: SEMPRE o proprio numero da instancia (self-message,
-- cs.telefone -- mesmo numero cadastrado na credencial da instancia). Sem
-- campo de numero alternativo, por decisao explicita -- simplifica e evita
-- inconsistencia entre tenants.
--
-- Ver diagnostico e desenho completo na conversa do Claude Code de 2026-08-06.

ALTER TABLE public.clientes_sistema
  ADD COLUMN IF NOT EXISTS notificar_atendimento_humano BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS notificar_toda_interacao BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS palavras_urgencia TEXT,
  ADD COLUMN IF NOT EXISTS palavras_falha_atendimento TEXT;

UPDATE public.clientes_sistema
SET notificar_toda_interacao = true,
    palavras_urgencia = 'situação urgente'
WHERE instancia_whatsapp = 'ariane-d-avila-afonso-advocaci'
RETURNING id, nome_empresa, instancia_whatsapp, notificar_atendimento_humano, notificar_toda_interacao, palavras_urgencia;
