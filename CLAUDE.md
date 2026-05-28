# 🤖 UpVia Agentes — Projeto de Automação WhatsApp

## 👩‍💼 Contexto do Projeto
Agência de automação digital fundada por Elisa e Jean.
Produto principal: agentes de IA para WhatsApp com agendamento via Google Calendar.

**Missão do Claude Code aqui:**
- Gerenciar, debugar e evoluir os fluxos n8n
- Administrar e proteger a VPS
- Manter backups automáticos de tudo
- Garantir que o sistema NUNCA caia com clientes ativos

---

## 🌐 Infraestrutura

| Serviço | URL | Observação |
|---|---|---|
| n8n | https://n8n.upviaagentes.com | Gerenciador de fluxos |
| Evolution API | https://evo.upviaagentes.com | WhatsApp gateway |
| Supabase | (via dashboard) | Banco de dados principal |
| Site | https://upviaagentes.com.br | Netlify |

**Instância WhatsApp principal:** `agentematriz`
**API Key prefix:** `2B91C56C7911`

---

## 📁 Estrutura de Pastas

```
upvia-agentes/
│
├── n8n-workflows/
│   ├── agente-atendente-multitenant.json   ← PRINCIPAL
│   ├── agente-vendedor-atendente.json
│   ├── agente-food-atendente.json
│   ├── gerador-qrcode-agendamento.json
│   └── cadastro-automatico-site.json
│
├── supabase/
│   ├── schema.sql
│   ├── tabelas.md
│   └── migrations/
│
├── vps/
│   ├── backups/
│   ├── logs/
│   ├── seguranca/
│   │   ├── firewall-rules.sh
│   │   └── monitoramento.sh
│   └── scripts/
│       ├── backup-diario.sh
│       └── health-check.sh
│
└── CLAUDE.md  ← este arquivo
```

---

## 🔄 Fluxos n8n — Descrição

### 1. `agente-atendente-multitenant.json` ⭐ PRINCIPAL
- Agente de atendimento ao cliente via WhatsApp
- Arquitetura multitenant (vários clientes/empresas usando o mesmo agente)
- Integrado com Google Calendar para agendamentos
- Conectado ao Supabase (tabela `followup_clientes`)
- Campos importantes: `encerrado`, `enviou_ticket`, `bloqueado` (boolean, default false)

### 2. `agente-vendedor-atendente.json`
- Agente com perfil de vendedor
- Atendimento focado em conversão

### 3. `agente-food-atendente.json`
- Agente especializado para food service / restaurantes

### 4. `gerador-qrcode-agendamento.json`
- Fluxo pequeno auxiliar
- Gera QR Code para cadastro no agente de agendamento

### 5. `cadastro-automatico-site.json`
- Ativado pelo formulário do site (Netlify → n8n webhook)
- Cria cliente novo no Supabase automaticamente
- Provisiona instância na Evolution API
- Fluxo: Site → Webhook n8n → Supabase → Evolution API

---

## 🗄️ Supabase — Tabelas Principais

### `followup_clientes`
| Coluna | Tipo | Default |
|---|---|---|
| encerrado | boolean | false |
| enviou_ticket | boolean | false |
| bloqueado | boolean | false |

### Outras tabelas relevantes
- `professionals` — profissionais por tenant (campo: tenant_id)
- `services` — serviços por tenant (campo: tenant_id)
- Clientes cadastrados pelo site usam `tenant_id` como chave

---

## 🛡️ VPS — Regras e Segurança

### Tarefas prioritárias de segurança:
1. Configurar firewall (UFW) — liberar apenas portas necessárias
2. Fail2ban para bloquear tentativas de acesso suspeitas
3. Monitoramento de uso de CPU/memória/disco
4. Alertas automáticos quando algum serviço cair

### Portas que devem estar abertas:
- 80 e 443 (HTTP/HTTPS)
- 22 (SSH — restrito por IP se possível)
- Portas dos serviços: n8n, Evolution API

### Comando rápido para checar saúde dos serviços:
```bash
# Verificar status dos containers/serviços
docker ps -a
systemctl status nginx
```

---

## 💾 Sistema de Backup — PRIORIDADE MÁXIMA

> ⚠️ Histórico: o sistema caiu durante período de testes e tudo teve que ser refeito do zero. Isso NÃO pode acontecer com clientes ativos.

### O que deve ser salvo diariamente:
1. **Fluxos n8n** — exportar todos os workflows em JSON
2. **Banco Supabase** — dump completo das tabelas
3. **Configurações Evolution API** — instâncias e configs
4. **Arquivos de configuração da VPS** — nginx, docker-compose, .env

### Script de backup diário (a implementar):
```bash
#!/bin/bash
# backup-diario.sh
# Executar via cron todo dia às 03:00

DATA=$(date +%Y-%m-%d)
PASTA_BACKUP="/backups/$DATA"

mkdir -p $PASTA_BACKUP

# 1. Backup n8n workflows
# 2. Backup Supabase
# 3. Compactar e enviar para armazenamento seguro
# 4. Manter últimos 30 dias de backup
```

### Frequência de backup com clientes ativos:
- **Fluxos n8n:** a cada 6 horas
- **Dados novos de clientes:** a cada hora
- **Configurações gerais:** 1x por dia (03:00)

---

## 🚨 Procedimentos de Emergência

### Se o n8n travar / fluxo parar de funcionar:
1. Verificar logs: `docker logs n8n --tail 100`
2. Reiniciar serviço: `docker restart n8n`
3. Checar se webhook está ativo na instância `agentematriz`
4. Verificar conexão Evolution API ↔ n8n

### Se a Evolution API parar:
1. Acessar https://evo.upviaagentes.com/manager
2. Verificar instância `agentematriz`
3. Reconectar QR Code se necessário

### Lição aprendida — NUNCA:
- Fazer import de fluxo sem exportar backup antes
- Deletar workflow sem ter JSON salvo
- Atualizar dependências em produção sem teste antes

---

## 📋 Tarefas Recorrentes (peça para o Claude Code fazer)

```
"Exporta todos os workflows do n8n e salva na pasta n8n-workflows/"
"Verifica o status de todos os serviços da VPS"
"Faz um health check do sistema completo"
"Cria backup de hoje de tudo"
"Debugar o fluxo [nome] — está dando erro no node [nome]"
"Adiciona tratamento de erro no fluxo [nome]"
"Verifica se há tentativas de acesso suspeitas na VPS"
"Mostra os logs de erro do n8n das últimas 24h"
```

---

## 🔧 Comandos Úteis

```bash
# Ver logs do n8n
docker logs n8n -f

# Ver todos containers rodando
docker ps

# Reiniciar serviço específico
docker restart n8n
docker restart evolution-api

# Verificar uso de disco
df -h

# Verificar uso de memória
free -h

# Verificar conexões ativas
netstat -tulpn
```

---

## 🔒 REGRA DE BACKUP

> **OBRIGATÓRIO:** A cada modificação em workflows N8N, configurações do site ou arquivos críticos, fazer commit e push automático para o GitHub como backup.

### Regra geral:
- Qualquer alteração em `n8n-workflows/` → commit + push imediato
- Qualquer alteração em `supabase/` → commit + push imediato
- Qualquer alteração em arquivos de configuração da VPS → commit + push imediato
- O GitHub Actions roda a cada 48h como backup automático adicional
- A VPS roda backup local diário às 03:00 via cron

### Fluxo de trabalho obrigatório ao editar workflows:
1. Exportar o workflow do n8n em JSON
2. Salvar em `n8n-workflows/`
3. `git add . && git commit -m "backup: [nome-do-workflow] atualizado" && git push`

---

## 📌 Notas Importantes

- Todos os fluxos são em **português brasileiro**
- Arquitetura é **multitenant** — um agente serve vários clientes
- O agente de agendamento é o produto principal já vendável
- Novos agentes (vendedor, food) estão em desenvolvimento
- Sempre testar em ambiente de dev antes de subir para produção
- Manter este CLAUDE.md atualizado a cada mudança importante
