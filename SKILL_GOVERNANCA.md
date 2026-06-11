# 🔒 SKILL — Governança e Correção Segura UpVia

> **Versão:** V4 Enterprise
> Este arquivo define as regras absolutas de segurança, o protocolo obrigatório para qualquer alteração, e os comandos de correção.
> Complementa `CLAUDE.md` (contexto) e `SKILL_AUDITOR_N8N.md` (auditoria).

---

## ⚖️ Regra Absoluta — Sem Exceções

```
Nenhum workflow pode ser alterado sem:

  1. Backup exportado e confirmado
  2. Diagnóstico completo executado
  3. Aprovação explícita de Elisa

Nenhuma alteração pode ser revertida se não houver backup.
```

---

## 🔄 Módulo 1 — Fluxo Obrigatório de Governança

Qualquer pedido de alteração segue **exatamente** este pipeline:

```
ANALISAR
  ↓
Ler workflow completo
Mapear todos os nodes afetados
Identificar dependências
  ↓
DIAGNOSTICAR
  ↓
Classificar problemas (CRÍTICO/ALTO/MÉDIO/BAIXO)
Identificar causa raiz
Avaliar impacto da alteração
  ↓
REPORTAR
  ↓
Apresentar diagnóstico completo
Propor plano de correção com passos detalhados
Apresentar riscos e plano de rollback
  ↓
⏸ AGUARDAR APROVAÇÃO EXPLÍCITA
  ↓
[Elisa confirma: "pode executar" ou similar]
  ↓
EXECUTAR BACKUP
  ↓
Exportar workflow atual em JSON
Salvar em n8n-workflows/ com timestamp
  ↓
CORRIGIR
  ↓
Aplicar alteração conforme plano aprovado
Sem improviso — seguir plano exato
  ↓
VALIDAR
  ↓
Testar caminho afetado
Confirmar que outros caminhos não foram quebrados
  ↓
BACKUP PÓS-ALTERAÇÃO
  ↓
git add .
git commit -m "fix: [descrição da correção] — [nome-do-workflow]"
git push
```

> ⚠️ Pular qualquer etapa deste fluxo é proibido, mesmo que a alteração pareça trivial.

---

## 🛠️ Módulo 2 — Comandos de Correção Segura

### `/corrigir-workflow [nome] [descrição-do-problema]`

**Pré-requisitos obrigatórios antes de executar:**
- [ ] Auditoria já foi executada (`/auditar-workflow`)
- [ ] Diagnóstico completo disponível
- [ ] Aprovação de Elisa recebida
- [ ] Backup do estado atual exportado

**Regras invioláveis durante correção:**

| Regra | Descrição |
|---|---|
| ❌ Nunca alterar nomes de nodes | Quebra todas as referências ao node |
| ❌ Nunca alterar IDs de nodes | Quebra conexões internas do workflow |
| ❌ Nunca usar acentos em nomes novos | Causa erro `"Referenced node doesn't exist"` |
| ❌ Nunca remover conexões sem justificativa | Pode quebrar caminhos de execução |
| ❌ Nunca usar PUT/POST direto na API N8N | Esvazia o workflow inteiro |
| ✅ Sempre editar JSON localmente | Importar via "Import from File" no N8N |
| ✅ Sempre testar em dev antes de produção | Nunca aplicar direto em `studio_andrade` |
| ✅ Sempre verificar todas as referências | Ao renomear qualquer coisa |

---

### `/corrigir-cron [workflow] [problema]`
Correção de problemas de agendamento e timezone.

**Antes de corrigir:**
1. Executar `/auditar-cron` completo
2. Documentar timezone atual de servidor, container e workflow
3. Definir timezone correto alvo: `America/Sao_Paulo`

**Passos padrão para correção de timezone:**
```bash
# 1. Verificar timezone atual
timedatectl
docker exec n8n date

# 2. Corrigir timezone do servidor (se necessário)
timedatectl set-timezone America/Sao_Paulo

# 3. Corrigir timezone do container N8N (docker-compose.yml)
environment:
  - GENERIC_TIMEZONE=America/Sao_Paulo
  - TZ=America/Sao_Paulo

# 4. Reiniciar container
docker restart n8n

# 5. Verificar Schedule Trigger no workflow
# Ajustar horário se necessário após correção de timezone
```

---

### `/corrigir-followup [problema]`
Correção do sistema de follow-up.

**Verificações obrigatórias antes:**
- Confirmar que a correção não vai disparar mensagens para contatos errados
- Confirmar que não vai reenviar mensagens já enviadas
- Verificar filtro de `contatos_bloqueados`
- Verificar filtro de `tenant_id`

---

### `/corrigir-integracoes [servico] [problema]`
Correção de integrações (Evolution API, Supabase, Google Calendar, Google Drive).

**Regra especial para credenciais:**
- Nunca sobrescrever credenciais existentes sem backup
- Ao renovar OAuth2, testar em workflow de teste primeiro
- Documentar qual workflow usa qual credencial

---

## 📦 Módulo 3 — Protocolo de Backup

### Backup antes de qualquer alteração

```bash
# 1. Exportar workflow específico via N8N API
# Ler API key de: C:\Users\isaqu\OneDrive\Área de Trabalho\upvia-agentes\Key.n8n.txt

# PowerShell (Windows):
$apiKey = Get-Content "C:\Users\isaqu\OneDrive\Área de Trabalho\upvia-agentes\Key.n8n.txt"
$headers = @{ "X-N8N-API-KEY" = $apiKey }
$workflow = Invoke-RestMethod -Uri "https://n8n.upviaagentes.com/api/v1/workflows/[ID]" -Headers $headers
$workflow | ConvertTo-Json -Depth 100 | Out-File "n8n-workflows\[nome]-backup-$(Get-Date -Format 'yyyy-MM-dd-HHmm').json"

# 2. Git commit do backup
git add n8n-workflows/
git commit -m "backup: [nome-workflow] antes de [descrição-alteração]"
git push
```

### Backup diário automático
- **VPS:** `/root/backup-diario.sh` via cron às 03:00
- **GitHub Actions:** a cada 48 horas

### Verificar se backup está funcionando
```bash
# Verificar cron jobs ativos
crontab -l

# Verificar logs de backup
ls -la /backups/
cat /backups/$(date +%Y-%m-%d)/backup.log
```

---

## 🔁 Módulo 4 — Protocolo de Rollback

Se uma correção causar problema, executar imediatamente:

```
1. PARAR — não tentar corrigir o problema com mais alterações
2. IDENTIFICAR — qual backup está disponível
3. REPORTAR — avisar Elisa antes de restaurar
4. RESTAURAR — importar último JSON funcional via "Import from File"
5. VERIFICAR — confirmar que o workflow está funcionando
6. DOCUMENTAR — registrar o que aconteceu e por quê
```

### Importar backup no N8N (método seguro):
1. Acessar `https://n8n.upviaagentes.com`
2. Abrir workflow
3. Menu → Import from File
4. Selecionar JSON de backup
5. Salvar e ativar

> ⚠️ NUNCA usar PUT na API para restaurar — esvazia o workflow.

---

## 🏷️ Módulo 5 — Padrões de Nomenclatura

### Nodes N8N
```
✅ CORRETO:
- "Carregar Dados Negocio"
- "Filtro Extrair"
- "Verificar Bloqueio"
- "Enviar Mensagem"
- "Salvar Supabase"

❌ ERRADO:
- "Carregar Dados Negócio"   ← acento no "o"
- "Filtro + Extrair"         ← símbolo "+"
- "Verificação de Bloqueio"  ← acento
```

### Commits Git
```
feat: [nova funcionalidade] — [workflow ou arquivo]
fix: [problema corrigido] — [workflow ou arquivo]
backup: [nome-workflow] atualizado
backup: [nome-workflow] antes de [descrição]
hotfix: [problema crítico] — [workflow]
```

### Branches Git
- `main` — produção, sempre estável
- `dev` — desenvolvimento e testes
- Nunca commitar direto em `main` sem teste em `dev`

---

## 🧪 Módulo 6 — Validação Pós-Correção

Após qualquer correção, validar obrigatoriamente:

### Checklist mínimo
```
[ ] O caminho corrigido está funcionando
[ ] Os outros caminhos não foram quebrados
[ ] Mensagens estão sendo enviadas corretamente
[ ] Supabase está salvando dados corretamente
[ ] tenant_id ainda está sendo filtrado em todas as queries
[ ] Nenhum node está com erro em execução de teste
[ ] Logs do N8N sem erros críticos
```

### Checklist para workflow principal (`agente-atendente-multitenant`)
```
[ ] Novo cliente: fluxo completo funciona
[ ] Cliente recorrente: reconhecido corretamente
[ ] Agendamento: cria evento no Google Calendar
[ ] Cancelamento: remove evento corretamente
[ ] Remarcação: atualiza evento
[ ] Comandos do proprietário (#agendar, #relatorio, etc.)
[ ] Lock humano: ativa e expira após 2h
[ ] Follow-up: não dispara para bloqueados
[ ] Relatório 22h: cron no horário correto
[ ] CRM: funil atualizando estágios
[ ] Multitenant: studio_andrade isolado de outros tenants
```

---

## 📋 Módulo 7 — Registro de Alterações

Manter registro de todas as alterações em `CHANGELOG.md` (criar se não existir):

```markdown
## [data] — [nome do workflow]

**Problema:** [descrição]
**Causa raiz:** [análise]
**Correção aplicada:** [o que foi feito]
**Validado por:** Elisa
**Backup:** n8n-workflows/[nome]-backup-[data].json
**Commit:** [hash]
```

---

## 🚨 Situações de Emergência com Clientes Ativos

Se um cliente ativo (ex: `studio_andrade`) reportar problema:

```
PRIORIDADE 1 — Diagnosticar sem alterar nada
  ↓
Ver logs: docker logs n8n --tail 100
Ver execuções recentes no N8N
Identificar o erro exato
  ↓
PRIORIDADE 2 — Solução mínima e segura
  ↓
Aplicar apenas a correção necessária
Não aproveitar para fazer outras melhorias
  ↓
PRIORIDADE 3 — Confirmar funcionamento
  ↓
Testar exatamente o fluxo que estava falhando
Confirmar com Elisa que está OK
  ↓
PRIORIDADE 4 — Documentar
  ↓
Registrar no CHANGELOG.md
Fazer backup e git push
```

> ⚠️ Em emergência, velocidade importa — mas backup ANTES da correção é inegociável.

---

## 📌 Resumo Rápido — O que fazer e o que NUNCA fazer

### ✅ Sempre fazer
- Backup antes de qualquer alteração
- Auditoria antes de corrigir
- Testar em dev antes de produção
- Commit + push após cada alteração
- Verificar `tenant_id` em todas as queries
- Usar "Import from File" para atualizar workflows

### ❌ Nunca fazer
- Alterar nomes ou IDs de nodes
- Usar acentos em nomes novos de nodes
- PUT/POST direto na API N8N
- Deletar workflow sem JSON de backup
- Alterar credenciais OAuth2 sem teste
- Fazer múltiplas alterações de uma vez
- Alterar em produção direto sem validação
- Ignorar erro "Referenced node doesn't exist" sem investigar
