# Instalação do Backup Diário na VPS (Hostinger)

## Pré-requisitos
- Acesso SSH à VPS
- Script `backup-diario.sh` enviado para a VPS

---

## Passo 1 — Enviar o script para a VPS

No seu computador local, execute:

```bash
scp vps/backup-diario.sh root@SEU_IP_VPS:/root/upvia-agentes/vps/backup-diario.sh
```

Ou copie o conteúdo do arquivo manualmente via SSH.

---

## Passo 2 — Dar permissão de execução

```bash
chmod +x /root/upvia-agentes/vps/backup-diario.sh
```

---

## Passo 3 — Testar o script manualmente

```bash
bash /root/upvia-agentes/vps/backup-diario.sh
```

Verifique se apareceu o arquivo em `/backup/`:

```bash
ls -lh /backup/
```

---

## Passo 4 — Configurar o cron job

```bash
crontab -e
```

Adicione esta linha ao final do arquivo:

```
0 3 * * * /root/upvia-agentes/vps/backup-diario.sh >> /var/log/upvia-backup.log 2>&1
```

Salve e saia (`Ctrl+X`, `Y`, `Enter` no nano).

---

## Passo 5 — Verificar se o cron foi salvo

```bash
crontab -l
```

Deve aparecer a linha que você adicionou.

---

## Verificando os logs do backup

```bash
# Ver log completo
cat /var/log/upvia-backup.log

# Ver apenas as últimas execuções
tail -50 /var/log/upvia-backup.log

# Acompanhar em tempo real (quando rodar manualmente)
bash /root/upvia-agentes/vps/backup-diario.sh
```

---

## Variáveis de ambiente (opcional)

Se os diretórios do N8N ou Evolution API estiverem em locais diferentes, exporte as variáveis antes ou edite o script:

```bash
export N8N_DATA_DIR=/caminho/para/.n8n
export EVO_DIR=/caminho/para/evolution-api
```

---

## Resumo do que o script faz

| Passo | O que faz |
|---|---|
| 1 | Copia dados do N8N (`~/.n8n`) |
| 2 | Copia configs da Evolution API (`.env`, `docker-compose.yml`, `.json`) |
| 3 | Copia configs da VPS (nginx, docker-compose, .env) |
| 4 | Compacta tudo em `/backup/upvia-YYYY-MM-DD.tar.gz` |
| 5 | Remove backups com mais de 7 dias |

**Horário:** Todo dia às **03:00** (horário da VPS)  
**Retenção:** Últimos **7 backups** (aproximadamente 1 semana)  
**Localização:** `/backup/upvia-YYYY-MM-DD.tar.gz`
