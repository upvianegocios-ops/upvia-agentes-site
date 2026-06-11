# 🔍 SKILL — Auditor N8N UpVia

> **Versão:** V4 Enterprise
> Este arquivo define os comandos, protocolos e saídas padrão para auditoria de todos os sistemas da UpVia Agentes.
> Complementa `CLAUDE.md` (contexto) e `SKILL_GOVERNANCA.md` (regras de alteração).

---

## 🎯 Papel deste Módulo

Ao receber qualquer pedido relacionado a N8N, Evolution API, Supabase, Google Calendar, Google Drive, CRM ou Follow-up:

```
NUNCA assumir que o fluxo está correto.

SEMPRE:
  1. Ler o workflow completo
  2. Mapear todas as dependências
  3. Identificar impacto da alteração
  4. Identificar riscos
  5. Criar plano de execução
  6. Reportar → Aguardar aprovação → Corrigir
```

---

## 📋 Módulo 1 — Comandos de Auditoria

### `/auditar-workflow [nome]`
Auditoria completa de um workflow específico.

**Protocolo:**
1. Ler o JSON completo do workflow
2. Mapear todos os nodes e suas conexões
3. Identificar fontes de dados de cada node (verificar se campos vêm do node correto)
4. Verificar acentos em nomes de nodes (causa erro `"Referenced node doesn't exist"`)
5. Verificar tratamento de erros em cada branch
6. Mapear todos os caminhos de execução possíveis
7. Identificar nodes sem saída de erro configurada
8. Verificar se `tenant_id` está presente e validado em todos os pontos de acesso a dados

**Saída obrigatória:**
```
## Auditoria: [nome-do-workflow]

### Mapa de Nodes
[lista todos os nodes com tipo e conexões]

### Fontes de Dados Validadas
[campo] → [node de origem] ✅/❌

### Caminhos de Execução
[diagrama textual de todos os caminhos]

### Problemas Encontrados
[classificados por severidade — ver Módulo 3]

### Score de Saúde
[ver Módulo 6]
```

---

### `/auditar-cron`
Auditoria de todos os Schedule Triggers e tarefas agendadas.

**O que verificar:**
- Schedule Trigger presente e ativo
- Timezone do workflow (configuração N8N)
- Timezone do servidor Docker
- Timezone do container N8N
- Horário configurado vs. horário real de execução
- Log da última execução
- Próxima execução prevista
- Dados disponíveis no momento da execução

**Atenção especial:** Relatório das 22h — verificar se os 3 timezones estão alinhados.

**Saída obrigatória:**
```
## Auditoria de Crons

| Workflow | Horário Config | Timezone Workflow | Timezone Servidor | Status | Última Execução | Próxima |
|---|---|---|---|---|---|---|

### Problemas de Timezone
[detalhar divergências]

### Diagnóstico
[OK / ATENÇÃO / CRÍTICO]
```

---

### `/auditar-followup`
Auditoria do sistema de follow-up automático.

**O que verificar:**
- Gatilho de ativação (trigger correto?)
- Filtros aplicados (cliente correto? tenant correto?)
- Conteúdo das mensagens (campos existem no Supabase?)
- Condição de disparo (não disparar para contatos bloqueados)
- Controle de reenvio (não enviar múltiplas vezes)
- Taxa de erro nos últimos 7 dias

**Saída obrigatória:**
```
## Auditoria Follow-up

Gatilho: [status]
Filtros: [status]
Mensagens: [status]

Quantidade prevista: [N]
Quantidade executada: [N]
Taxa de erro: [%]

Problemas: [lista]
```

---

### `/auditar-crm`
Auditoria do sistema CRM.

**O que verificar:**
- Cadastro de leads (está salvando corretamente?)
- Atualização de estágio no funil (Lead → Interessado → Agendou → Frequente → VIP)
- Critério VIP: 6+ agendamentos ou ticket alto
- Detecção de churn risk
- Segmentação funcionando
- Histórico de ações em `crm_acoes`
- Relatório CRM (`#relatorio-crm`) — geração e envio WhatsApp

**Saída obrigatória:**
```
## Auditoria CRM

Funil: [status de cada estágio]
Cadastro: [OK/ERRO]
Atualização: [OK/ERRO]
Segmentação: [OK/ERRO]
Histórico: [OK/ERRO]
Relatório: [OK/ERRO]

Processos incompletos identificados: [lista]
```

---

### `/auditar-whatsapp`
Auditoria da Evolution API e conexões WhatsApp.

**O que verificar por instância:**

| Item | Status |
|---|---|
| Instância conectada | ✅/❌ |
| Webhook ativo | ✅/❌ |
| Status de conexão | ONLINE/OFFLINE/QR_NEEDED |
| Filas pendentes | [N mensagens] |
| Erros de envio (últimas 24h) | [N] |
| Erros de recebimento (últimas 24h) | [N] |
| QR Code expirado | ✅/❌ |

**Classificação por instância:**
- `OK` — tudo funcionando
- `ATENÇÃO` — instável, monitorar
- `CRÍTICO` — offline ou sem webhook

---

### `/auditar-supabase`
Auditoria do banco de dados Supabase.

**O que verificar:**
- Tabelas utilizadas pelos workflows existem
- Consultas SQL válidas (sem campos inexistentes)
- Índices ausentes em campos de filtro frequente (`tenant_id`, `phone`, `jid`)
- Erros de relacionamento entre tabelas
- Filtros por `tenant_id` presentes em todas as queries (isolamento multitenant)
- Comparações de JID usando `REPLACE()` para remover `@s.whatsapp.net`
- Session Pooler configurado (obrigatório para IPv6)

**Saída obrigatória:**
```
## Auditoria Supabase

### Tabelas Verificadas
- clientes_sistema: [OK/ERRO]
- dados_cliente: [OK/ERRO]
- contatos_bloqueados: [OK/ERRO]
- regras_ia: [OK/ERRO]
- itens_servico: [OK/ERRO]

### Queries com Problemas
[lista com descrição do problema]

### Isolamento Multitenant
[todas as queries têm filtro tenant_id? OK/FALHA CRÍTICA]

### Índices Ausentes
[lista de campos sem índice que são filtrados frequentemente]
```

---

### `/auditar-google-calendar`
Auditoria das integrações com Google Calendar.

**O que verificar:**
- Credenciais OAuth2 válidas (não expiradas)
- Agendas conectadas por tenant
- Timezone configurado corretamente
- Eventos criados com sucesso (últimas 24h)
- Eventos atualizados/cancelados
- Erros de bloqueio de horários

**Simulações obrigatórias:**
1. Criar agendamento de teste
2. Remarcar agendamento de teste
3. Cancelar agendamento de teste

**Atenção especial:** Verificar se há bloqueios de datas/horários suspeitos (ex: bug junho 6–11).

---

### `/auditar-google-drive`
Auditoria da integração com Google Drive.

**O que verificar:**
- Credenciais OAuth2 válidas
- Acesso confirmado às pastas configuradas
- Documentos de `regras_ia` e `itens_servico` encontrados e sincronizados
- Permissões de leitura/escrita
- Documentos órfãos (referenciados no banco mas inexistentes no Drive)
- URLs de mídia acessíveis publicamente (para `sendMedia` na Evolution API)

---

### `/healthcheck-completo`
Executa todos os módulos de auditoria em sequência e gera relatório consolidado.

**Ordem de execução:**
1. `/auditar-whatsapp`
2. `/auditar-supabase`
3. `/auditar-google-calendar`
4. `/auditar-cron`
5. `/auditar-followup`
6. `/auditar-crm`
7. `/auditar-google-drive`
8. `/auditar-workflow agente-atendente-multitenant`

**Saída:** Score de Saúde Geral + lista priorizada de problemas + plano de ação.

---

## 🏢 Módulo 2 — Auditoria Multitenant

Em todo e qualquer workflow auditado, validar obrigatoriamente:

```
✅ tenant_id presente em todas as queries Supabase
✅ Isolamento: dados de um tenant NUNCA aparecem para outro
✅ Permissões: credenciais separadas por tenant quando necessário
✅ Filtros por tenant em: dados_cliente, regras_ia, itens_servico, CRM
```

> ⚠️ **Falha de isolamento multitenant é classificada como CRÍTICO.**
> Significa que cliente A poderia ver dados do cliente B — violação grave.

---

## 📊 Módulo 3 — Classificação de Problemas

Todo problema identificado deve ser classificado:

### 🔴 CRÍTICO
- Sistema parado ou inacessível
- Falha de isolamento multitenant
- Perda de dados confirmada ou possível
- WhatsApp desconectado em produção
- Credenciais expiradas em produção
- Backup não executando

### 🟠 ALTO
- Fluxo executando com erros intermitentes
- Node sem tratamento de erro em caminho principal
- Timezone errado no cron
- Campo sendo lido do node errado (fonte incorreta)
- Follow-up disparando para contatos errados

### 🟡 MÉDIO
- Performance degradada (queries lentas, sem índice)
- Tratamento de erro ausente em caminho secundário
- Documentação desatualizada no `CLAUDE.md`
- Script de backup desatualizado

### 🟢 BAIXO
- Melhorias de organização no workflow
- Nomes de nodes que poderiam ser mais descritivos
- Otimizações não urgentes

---

## 📈 Módulo 4 — Auditoria de Área do Proprietário

Validar e simular todos os comandos do proprietário:

| Comando | Função | Status |
|---|---|---|
| `#agendar` | Agendamento manual | [OK/ERRO] |
| `#cancelar` | Cancelamento manual | [OK/ERRO] |
| `#remarcar` | Remarcação manual | [OK/ERRO] |
| `#relatorio` | Relatório de atendimentos | [OK/ERRO] |
| `#agenda` | Consulta de agenda | [OK/ERRO] |
| `#ajuda` | Lista de comandos | [OK/ERRO] |
| `#balanco` | Balanço financeiro | [OK/ERRO] |
| `#crm` | Relatório CRM | [OK/ERRO] |

> Simular cada operação com dados de teste e verificar resposta.

---

## 🌙 Módulo 5 — Auditoria do Relatório das 22h

**Prioridade máxima** — relatório enviado ao proprietário toda noite.

**Checklist completo:**

```
[ ] Schedule Trigger configurado para 22:00
[ ] Timezone do Workflow = America/Sao_Paulo
[ ] Timezone do Servidor = America/Sao_Paulo
[ ] Timezone do Docker/Container = America/Sao_Paulo
[ ] Última execução ocorreu no horário correto
[ ] Próxima execução está agendada
[ ] Dados disponíveis no momento da execução
[ ] Geração do relatório sem erros
[ ] Envio WhatsApp confirmado
[ ] Logs sem erros críticos
```

**Diagnóstico de divergência de timezone:**
```bash
# Verificar timezone do servidor
timedatectl

# Verificar timezone do container N8N
docker exec n8n date

# Comparar com configuração do workflow N8N
```

---

## 📊 Módulo 6 — Score de Saúde

Após auditoria completa, gerar Score de 0 a 100 para cada dimensão:

```
## 📊 Score de Saúde — UpVia Agentes
Data: [data/hora]

| Dimensão | Score | Status |
|---|---|---|
| Saúde do Workflow Principal | [0-100] | [🔴/🟠/🟡/🟢] |
| Saúde das Integrações | [0-100] | [🔴/🟠/🟡/🟢] |
| Saúde do Banco (Supabase) | [0-100] | [🔴/🟠/🟡/🟢] |
| Saúde do WhatsApp | [0-100] | [🔴/🟠/🟡/🟢] |
| Saúde dos Agendamentos | [0-100] | [🔴/🟠/🟡/🟢] |
| Saúde dos Backups | [0-100] | [🔴/🟠/🟡/🟢] |

**Score Geral: [média ponderada]/100**

### Problemas Críticos 🔴
[lista]

### Problemas Altos 🟠
[lista]

### Problemas Médios 🟡
[lista]

### Funcionando Corretamente ✅
[lista]

### Plano de Ação Sugerido
[ordenado por impacto operacional]
```

**Critério de score por dimensão:**
- 90–100: Funcionando perfeitamente
- 70–89: Funcionando com alertas
- 50–69: Problemas que precisam de atenção
- 30–49: Problemas sérios afetando operação
- 0–29: Sistema comprometido

---

## 🔍 Módulo 7 — Diagnóstico Profundo

### `/diagnostico-completo`
Combina auditoria + análise de causa raiz + plano de correção detalhado.

### `/diagnostico-cron`
Foco em problemas de agendamento, timezone e execuções perdidas.

### `/diagnostico-whatsapp`
Foco em conectividade, webhooks e filas da Evolution API.

### `/diagnostico-agendamentos`
Foco no fluxo de agendamento Google Calendar: criação, remarcação, cancelamento, conflitos de horário.

**Formato de saída dos diagnósticos:**
```
## Diagnóstico: [escopo]

### Problema Identificado
[descrição clara]

### Causa Raiz
[análise técnica]

### Impacto
[o que está sendo afetado]

### Plano de Correção
Passo 1: [ação]
Passo 2: [ação]
...

### Riscos da Correção
[o que pode dar errado ao corrigir]

### Validação Pós-Correção
[como confirmar que foi resolvido]
```

---

## 🚨 Regra Especial — Workflow CRÍTICO

> O workflow `agente-atendente-multitenant.json` é **SISTEMA CRÍTICO** com clientes ativos em produção.

Antes de qualquer alteração neste workflow, obrigatoriamente:

1. Mapear **todos** os caminhos de execução:
   - Atendimento ao cliente (novo, recorrente)
   - Agendamento, cancelamento, remarcação
   - Área do proprietário (todos os comandos `#`)
   - CRM e funil de estágios
   - Follow-up automático
   - Atualização de documentos (`regras_ia`, `itens_servico`)
   - Relatório diário das 22h
   - Lock de atendimento humano (2h)

2. Identificar todos os nodes afetados pela alteração planejada

3. Criar plano de rollback antes de executar

4. Executar conforme protocolo em `SKILL_GOVERNANCA.md`
