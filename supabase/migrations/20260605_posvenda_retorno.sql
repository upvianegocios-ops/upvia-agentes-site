-- ============================================================
-- MIGRATION: Pós-venda e Retorno Automático
-- Data: 2026-06-05
-- Descrição: Adiciona campos necessários para os sub-fluxos
--            de pós-venda automático e agendamento de retorno.
-- ============================================================

-- ------------------------------------------------------------
-- 1. REGISTROS_AGENDA — campos de pós-venda e retorno
-- ------------------------------------------------------------

ALTER TABLE registros_agenda
  ADD COLUMN IF NOT EXISTS data_retorno_prevista   DATE,
  ADD COLUMN IF NOT EXISTS followup_enviado        BOOLEAN      DEFAULT false,
  ADD COLUMN IF NOT EXISTS followup_enviado_em     TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS followup_etapa          INTEGER      DEFAULT 0,
  ADD COLUMN IF NOT EXISTS posvenda_enviado        BOOLEAN      DEFAULT false,
  ADD COLUMN IF NOT EXISTS posvenda_enviado_em     TIMESTAMPTZ;

-- Índices para as queries de polling (performance)
CREATE INDEX IF NOT EXISTS idx_registros_agenda_posvenda
  ON registros_agenda (id_estabelecimento, status_evento, posvenda_enviado, data_fim)
  WHERE status_evento = 'concluido' AND posvenda_enviado = false;

CREATE INDEX IF NOT EXISTS idx_registros_agenda_retorno
  ON registros_agenda (id_estabelecimento, data_retorno_prevista, followup_enviado)
  WHERE data_retorno_prevista IS NOT NULL AND followup_enviado = false;

COMMENT ON COLUMN registros_agenda.data_retorno_prevista
  IS 'Data calculada automaticamente para lembrete de retorno. Calculada como data_fim + itens_servico.intervalo_retorno_dias';

COMMENT ON COLUMN registros_agenda.followup_enviado
  IS 'True quando a mensagem de lembrete de retorno foi enviada via WhatsApp';

COMMENT ON COLUMN registros_agenda.followup_enviado_em
  IS 'Timestamp do envio da mensagem de retorno';

COMMENT ON COLUMN registros_agenda.followup_etapa
  IS 'Etapa atual do followup (0=não iniciado, 1=retorno marcado, 2+=mensagem enviada)';

COMMENT ON COLUMN registros_agenda.posvenda_enviado
  IS 'True quando a mensagem de pós-venda (satisfação) foi enviada via WhatsApp';

COMMENT ON COLUMN registros_agenda.posvenda_enviado_em
  IS 'Timestamp do envio da mensagem de pós-venda';


-- ------------------------------------------------------------
-- 2. ITENS_SERVICO — campos de retorno automático por serviço
-- ------------------------------------------------------------

ALTER TABLE itens_servico
  ADD COLUMN IF NOT EXISTS intervalo_retorno_dias  INTEGER      DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS mensagem_retorno        TEXT         DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS ativo_followup          BOOLEAN      DEFAULT false;

COMMENT ON COLUMN itens_servico.intervalo_retorno_dias
  IS 'Quantidade de dias após o serviço para enviar lembrete de retorno. NULL = sem lembrete automático';

COMMENT ON COLUMN itens_servico.mensagem_retorno
  IS 'Mensagem personalizada de lembrete de retorno. Placeholders: {nome}, {servico}, {dias}. Ex: "Oi {nome}! Já faz {dias} dias desde seu {servico} 💅 Que tal renovar?"';

COMMENT ON COLUMN itens_servico.ativo_followup
  IS 'Se true, o sub-fluxo de retorno automático calcula e agenda data_retorno_prevista para este serviço';


-- ------------------------------------------------------------
-- 3. EXEMPLO DE CONFIGURAÇÃO (descomente para aplicar)
-- ------------------------------------------------------------

-- Exemplo: esmaltação em gel com retorno em 15 dias
-- UPDATE itens_servico
-- SET
--   intervalo_retorno_dias = 15,
--   mensagem_retorno = 'Oi {nome}! Já faz {dias} dias desde sua {servico} 💅 Que tal renovar? Posso verificar um horário disponível pra você essa semana!',
--   ativo_followup = true
-- WHERE nome ILIKE '%esmalt%'
--   AND id_estabelecimento = 'SEU_TENANT_ID_AQUI';

-- Exemplo: manicure com retorno em 21 dias
-- UPDATE itens_servico
-- SET
--   intervalo_retorno_dias = 21,
--   mensagem_retorno = 'Oi {nome}! Passando pra lembrar que já faz {dias} dias 🌸 Quer agendar sua {servico}? Tenho horários essa semana!',
--   ativo_followup = true
-- WHERE nome ILIKE '%manicure%'
--   AND id_estabelecimento = 'SEU_TENANT_ID_AQUI';


-- ------------------------------------------------------------
-- 4. MENSAGEM CUSTOMIZADA DE PÓS-VENDA (por tenant)
-- ------------------------------------------------------------
-- Para customizar a mensagem de pós-venda por tenant,
-- adicione uma linha em clientes_sistema.informacoes_extras:
--
--   mensagem_posvenda: Oi {nome}! Como foi o atendimento hoje? 😊
--
-- O fluxo busca esse padrão e substitui {nome} pelo primeiro nome
-- da cliente e {servico} pelo nome do serviço realizado.
--
-- Se não houver mensagem customizada, usa o template padrão:
-- "Oi {nome}! Tudo bem? Passando pra saber como foi o atendimento
--  hoje 😊 Ficou satisfeita com {servico}? Qualquer coisa estou por aqui!"


-- ------------------------------------------------------------
-- 5. VERIFICAÇÃO — rodar após aplicar a migration
-- ------------------------------------------------------------

-- Confirma que os campos foram criados em registros_agenda:
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'registros_agenda'
  AND column_name IN (
    'data_retorno_prevista',
    'followup_enviado',
    'followup_enviado_em',
    'followup_etapa',
    'posvenda_enviado',
    'posvenda_enviado_em'
  )
ORDER BY column_name;

-- Confirma que os campos foram criados em itens_servico:
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'itens_servico'
  AND column_name IN (
    'intervalo_retorno_dias',
    'mensagem_retorno',
    'ativo_followup'
  )
ORDER BY column_name;
