# 🤖 UpVia Agentes — Contexto do Projeto para Claude Code

> **Versão:** V4 Enterprise | **Atualizado:** Junho 2025
> Este arquivo é o contexto principal. Para auditoria, ver `SKILL_AUDITOR_N8N.md`. Para governança e segurança, ver `SKILL_GOVERNANCA.md`.

---

## 👩‍💼 Sobre a UpVia

Agência de automação digital fundada por **Elisa e Jean**, com sede em **Pelotas/RS, Brasil**.

**Produtos principais:**
1. **AtendentIA** — Agente de atendimento WhatsApp com agendamento via Google Calendar (produto principal, já vendável)
2. **VendedorIA** — Agente de vendas com SPIN Selling e funil de conversão
3. **Websites e Apps** sob demanda

**Demo case ao vivo:** Unhabella (negócio de películas de unhas da Elisa) — `elisaunhabella12@gmail.com`

**Missão do Claude Code aqui:**
- Gerenciar, debugar e evoluir os fluxos N8N
- Administrar e proteger a VPS
- Manter backups automáticos de tudo
- Garantir que o sistema NUNCA caia com clientes ativos

---

## 🌐 Infraestrutura

| Serviço | URL / Referência | Observação |
|---|---|---|
| N8N | `https://n8n.upviaagentes.com` | Gerenciador de fluxos — **não usar PUT/POST direto na API sem backup** |
| Evolution API | `https://evo.upviaagentes.com` | WhatsApp gateway |
| Evolution API Key (global) | `3gl0eq56t0ahsh3m5lx7ruv8i764qcvd` | Usar no header `apikey` |
| Supabase (AtendentIA) | Projeto `qzgokcxvyasftuqgqonn` | Banco principal |
| Supabase (VendedorIA) | Projeto `clcyyogtvygpehgcmeyj` | Pooler: `aws-0-us-west-2.pooler.supabase.com` |
| Site | `https://upviaagentes.com.br` | Deploy via Vercel + GitHub (`upvianegocios-ops/upvia-agentes-site`, branch `main`) |
| VPS | IP `187.127.29.198` | Ubuntu 24.04, Easypanel/Docker/Traefik, Hostinger |
| Cloudflare | DNS proxy ativo | Para subdomínios `*.upviaagentes.com` |

**Instância WhatsApp principal:** `agentematriz`

---

## 📁 Estrutura de Pastas

```
upvia-agentes/
│
├── n8n-workflows/
│   ├── agente-atendente-multitenant.json   ← SISTEMA CRÍTICO
│   ├── agente-vendedor-multitenant.json
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
│       ├── backup-diario.sh     ← cron às 03:00
│       └── health-check.sh
│
├── CLAUDE.md              ← contexto do projeto (este arquivo)
├── SKILL_AUDITOR_N8N.md   ← comandos de auditoria
└── SKILL_GOVERNANCA.md    ← regras de segurança e alterações
```

---

## 🗄️ Supabase — Tabelas Reais

### Projeto AtendentIA (`qzgokcxvyasftuqgqonn`)

| Tabela | Uso |
|---|---|
| `clientes_sistema` | Tenants/empresas cadastradas na plataforma |
| `dados_cliente` | Contatos ativos, com campos `humano_assumiu`, `humano_assumiu_em` |
| `contatos_bloqueados` | Contatos que não devem receber atendimento automático |
| `regras_ia` | Regras de comportamento do agente por tenant — reduz alucinações |
| `itens_servico` | Catálogo de serviços por tenant — reduz alucinações |

> ⚠️ **Atenção:** O campo `bloqueado` vem de `contatos_bloqueados`. Usar `REPLACE()` ao comparar JID para remover sufixo `@s.whatsapp.net`.

### Colunas críticas em `dados_cliente`

| Coluna | Tipo | Observação |
|---|---|---|
| `humano_assumiu` | boolean | Ativa lock de atendimento humano |
| `humano_assumiu_em` | timestamp | Controla expiração de 2 horas do lock |
| `tenant_id` | text | **Chave de isolamento multitenant — CRÍTICA** |

### Projeto VendedorIA (`clcyyogtvygpehgcmeyj`)

- Host pooler: `aws-0-us-west-2.pooler.supabase.com`
- User format: `postgres.[project-ref]`
- Tenants ativos: **Unhabella** (agente "Bela", PIX CNPJ `24786973000166`) e **UpvIA Comercial** (instância `upvia-comercial`, agente "Bia")

---

## 🔄 Fluxos N8N — Descrição

### 1. `agente-atendente-multitenant.json` ⭐ SISTEMA CRÍTICO

Agente de atendimento ao cliente via WhatsApp. Arquitetura multitenant — um fluxo atende vários clientes/empresas.

**Nodes-chave e suas fontes de dados:**

| Campo | Fonte correta |
|---|---|
| `messageId` | Node **"Filtro + Extrair"** |
| `instancia_whatsapp` | Node **"Carregar Dados Negocio"** |
| `evo_api_key` | Node **"Carregar Dados Negocio"** |
| `evo_api_url` | Node **"Carregar Dados Negocio"** |
| `default_calendar` | Node **"Carregar Dados Negocio"** |
| `modelo_ia` | Node **"Carregar Dados Negocio"** |

**Camadas do fluxo:**
- Atendimento ao cliente (novo cliente, recorrente, agendamento, cancelamento, remarcação)
- Área do proprietário (comandos `#agendar`, `#cancelar`, `#remarcar`, `#relatorio`, `#agenda`, `#ajuda`, `#balanco`, `#crm`)
- CRM com funil de 5 estágios: Lead → Interessado → Agendou → Frequente → VIP
- Follow-up automático
- Relatório diário das 22h
- Lock de atendimento humano (2 horas, controlado por `humano_assumiu_em`)

**Modelos de IA por plano:**
- Essencial / Pro: `gpt-4.1-mini`
- Premium: `gpt-4.1`

**Tenant ativo em produção:** `studio_andrade` — agente "Nic" (Andressa)

### 2. `agente-vendedor-multitenant.json`
Agente com perfil de vendedor. SPIN Selling, Challenger Sale, gatilhos de escassez.
Planos AtendentIA: Essencial R$297/mo | Pro R$497/mo | Premium R$897/mo | Trial 7 dias.
Fechamento: `https://www.upviaagentes.com.br/conectar-whatsapp.html`

### 3. `agente-food-atendente.json`
Agente especializado para food service / restaurantes. Em desenvolvimento.

### 4. `gerador-qrcode-agendamento.json`
Fluxo auxiliar. Gera QR Code para cadastro no agente de agendamento.

### 5. `cadastro-automatico-site.json`
Ativado pelo formulário `conectar-whatsapp.html`.
Fluxo: Site → Webhook N8N → Supabase → Evolution API
Provisiona instância automaticamente. Integrado ao Asaas para cobrança recorrente.

---

## ⚠️ Armadilhas Conhecidas — LER ANTES DE EDITAR

### N8N
- **Acentos em nomes de nodes** causam erro `"Referenced node doesn't exist"` — NUNCA usar acentos
- **PUT/POST direto na API N8N esvazia workflows** — sempre editar JSON localmente e importar via "Import from File"
- **MCP N8N server conflita com chamadas REST diretas** — desabilitar antes de usar Invoke-RestMethod
- **Split in Batches:** output `0` = Loop Branch | output `1` = Done Branch (não inverter)
- **Nó `Sem Erros?` IF:** usar `notEquals`, não `isEmpty` (null ≠ "" com validação estrita)
- **`fromMe` detection:** simplificar para boolean `true` com "Convert types where required"

### Evolution API
- `sendMedia` exige URL publicamente acessível
- Google Drive: usar formato `https://drive.google.com/uc?export=download&id=FILE_ID` (arquivo deve ser "Qualquer pessoa com link")
- Retorno de contatos usa formato `@lid` — usar campo `remoteJidAlt`

### Supabase
- IPv6 requer Session Pooler obrigatório
- Comparação de JID: usar `REPLACE(jid, '@s.whatsapp.net', '')`
- "Continue on Fail" + "Always Output Data" nos nós Postgres para evitar quebra de fluxo

---

## 🛡️ VPS — Segurança

**Portas abertas:** 80, 443, 22 (restrito por IP quando possível)

```bash
# Checar saúde dos serviços
docker ps -a
systemctl status nginx

# Ver logs do N8N
docker logs n8n --tail 100

# Reiniciar serviços
docker restart n8n
docker restart evolution-api

# Uso de recursos
df -h && free -h

# Conexões ativas
netstat -tulpn
```

---

## 💾 Sistema de Backup

> ⚠️ **Histórico:** Container restart já apagou todos os workflows — tudo teve que ser refeito do zero. Isso NÃO pode acontecer com clientes ativos.

### Frequência
| Item | Frequência |
|---|---|
| Fluxos N8N | A cada 6 horas |
| Dados novos de clientes | A cada hora |
| Configurações gerais VPS | Diário às 03:00 |
| GitHub Actions | A cada 48 horas |

### O que deve ser salvo
1. Fluxos N8N (exportar todos em JSON)
2. Dump Supabase (tabelas completas)
3. Configurações Evolution API (instâncias e configs)
4. Arquivos VPS: nginx, docker-compose, `.env`

### Script base (`/root/backup-diario.sh`)
```bash
#!/bin/bash
DATA=$(date +%Y-%m-%d)
PASTA_BACKUP="/backups/$DATA"
mkdir -p $PASTA_BACKUP
# 1. Backup N8N workflows via API
# 2. Backup Supabase
# 3. Compactar e enviar para armazenamento seguro
# 4. Manter últimos 30 dias
```

---

## 🚨 Procedimentos de Emergência

### N8N travado / fluxo parou
1. `docker logs n8n --tail 100`
2. `docker restart n8n`
3. Checar webhook ativo na instância `agentematriz`
4. Verificar conexão Evolution API ↔ N8N

### Evolution API parou
1. Acessar `https://evo.upviaagentes.com/manager`
2. Verificar instância `agentematriz`
3. Reconectar via QR Code se necessário

### Regras absolutas — NUNCA fazer:
- Importar fluxo sem exportar backup antes
- Deletar workflow sem JSON salvo localmente
- Atualizar dependências em produção sem teste
- Alterar nomes de nodes sem verificar todas as referências

---

## 📋 Tarefas Recorrentes

```
"Exporta todos os workflows do N8N e salva na pasta n8n-workflows/"
"Verifica o status de todos os serviços da VPS"
"Faz um health check completo do sistema"
"Cria backup de hoje de tudo"
"Debugar o fluxo [nome] — erro no node [nome]"
"Adiciona tratamento de erro no fluxo [nome]"
"Verifica tentativas de acesso suspeitas na VPS"
"Mostra logs de erro do N8N das últimas 24h"
```

---

## 📌 Notas Gerais

- Todos os fluxos são em **português brasileiro**
- Arquitetura é **multitenant** — um agente serve vários clientes isolados por `tenant_id`
- Sempre testar em ambiente de dev antes de subir para produção
- Manter este `CLAUDE.md` atualizado a cada mudança importante
- Para auditoria: usar comandos em `SKILL_AUDITOR_N8N.md`
- Para alterações seguras: seguir protocolo em `SKILL_GOVERNANCA.md`
