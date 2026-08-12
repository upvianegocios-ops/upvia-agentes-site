-- Corrige spam de notificacao de handoff (feature de 06/08): "toda_interacao"
-- disparava a cada resposta da IA durante a triagem (varias por conversa), nao
-- so quando a triagem de fato termina. Sem nenhuma trava contra repeticao.
--
-- 2 colunas novas, ambas com defaults seguros (NULL = comportamento antigo
-- pros tenants que nao usam essas features):
--
--   clientes_sistema.palavras_conclusao_triagem
--     Mesmo padrao de palavras_urgencia: frases separadas por virgula,
--     checadas (case-insensitive, contains) na resposta da IA. So passa a
--     valer junto com notificar_toda_interacao = true (ver Avaliar
--     Notificacao Pos Resposta no workflow). Varias variacoes em vez de uma
--     frase exata porque a IA parafraseia -- qualquer uma delas basta.
--
--   trava_atendimento_humano.notificacao_handoff_enviada_em
--     Timestamp da ultima notificacao de handoff enviada pra esse contato.
--     Reaproveita a mesma janela de 2h ja usada por humano_assumiu_em como
--     "sessao" -- dentro da janela, nao notifica de novo (nem toda_interacao
--     nem pediu_humano); passada a janela, considera nova sessao. urgente
--     continua sempre disparando (nao respeita essa trava -- emergencia real
--     merece alerta mesmo que ja tenha notificado 10 min atras).
--
-- Ver diagnostico e desenho completo na conversa do Claude Code de 2026-08-11.

ALTER TABLE public.clientes_sistema
  ADD COLUMN IF NOT EXISTS palavras_conclusao_triagem TEXT;

ALTER TABLE public.trava_atendimento_humano
  ADD COLUMN IF NOT EXISTS notificacao_handoff_enviada_em TIMESTAMPTZ;

UPDATE public.clientes_sistema
SET palavras_conclusao_triagem = 'vou encaminhar,passarei essas informações,dra. ariane vai analisar,dra. ariane vai retornar,entrará em contato'
WHERE instancia_whatsapp = 'ariane-d-avila-afonso-advocaci'
RETURNING id, nome_empresa, instancia_whatsapp, palavras_conclusao_triagem;
