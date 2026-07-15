-- Trava configuravel por tenant: quando o proprio dono do numero inicia/fala
-- manualmente numa conversa, trava a IA automaticamente pra aquele contato
-- (reaproveita trava_atendimento_humano, ja usado pelo comando #pausar).
--
-- Contexto: o workflow "AtendentIA Multi-Atendimento SaaS" ja ativa essa trava
-- globalmente pra qualquer tenant desde a atualizacao de 2026-07-11 (node
-- "Decisor Central" classifica qualquer mensagem fromMe sem "#" como
-- humano_falou). Essa coluna torna esse comportamento opt-in por tenant:
-- default FALSE mantem o comportamento visto antes de 11/07 (IA responde
-- normalmente mesmo em conversas iniciadas pelo dono). So a Ariane usa TRUE
-- nesta primeira rodada.
--
-- Ver diagnostico completo na conversa do Claude Code de 2026-07-14.

ALTER TABLE public.clientes_sistema
  ADD COLUMN IF NOT EXISTS trava_conversas_iniciadas_pelo_owner BOOLEAN NOT NULL DEFAULT false;

UPDATE public.clientes_sistema
SET trava_conversas_iniciadas_pelo_owner = true
WHERE instancia_whatsapp = 'ariane-d-avila-afonso-advocaci'
RETURNING id, nome_empresa, instancia_whatsapp, trava_conversas_iniciadas_pelo_owner;
