#!/bin/bash
# backup-diario.sh — UpVia Agentes
# Rodar via cron todo dia às 03:00
# crontab: 0 3 * * * /root/upvia-agentes/vps/backup-diario.sh >> /var/log/upvia-backup.log 2>&1

set -e

DATA=$(date +%Y-%m-%d)
HORA=$(date +%H-%M)
NOME_ARQUIVO="upvia-${DATA}.tar.gz"
PASTA_BACKUP="/backup"
ARQUIVO_BACKUP="${PASTA_BACKUP}/${NOME_ARQUIVO}"
MAX_BACKUPS=7

echo "=============================="
echo "BACKUP UPVIA — $DATA $HORA"
echo "=============================="

mkdir -p "$PASTA_BACKUP"
TEMP_DIR=$(mktemp -d)

echo "[1/4] Backup dos workflows do N8N..."
N8N_DATA_DIR="${N8N_DATA_DIR:-/root/.n8n}"
if [ -d "$N8N_DATA_DIR" ]; then
  mkdir -p "$TEMP_DIR/n8n"
  cp -r "$N8N_DATA_DIR" "$TEMP_DIR/n8n/" 2>/dev/null || true
  echo "  OK — N8N data copiado de $N8N_DATA_DIR"
else
  echo "  AVISO — Diretório N8N não encontrado em $N8N_DATA_DIR"
fi

echo "[2/4] Backup das configurações da Evolution API..."
EVO_DIR="${EVO_DIR:-/root/evolution-api}"
if [ -d "$EVO_DIR" ]; then
  mkdir -p "$TEMP_DIR/evolution-api"
  find "$EVO_DIR" \( -name "*.env" -o -name "docker-compose*.yml" -o -name "*.json" \) \
    -not -path "*/node_modules/*" \
    -exec cp --parents {} "$TEMP_DIR/evolution-api/" \; 2>/dev/null || true
  echo "  OK — Evolution API configs copiadas"
else
  echo "  AVISO — Diretório Evolution API não encontrado em $EVO_DIR"
fi

echo "[3/4] Backup das configurações gerais da VPS..."
mkdir -p "$TEMP_DIR/vps-configs"
[ -f /etc/nginx/nginx.conf ] && cp /etc/nginx/nginx.conf "$TEMP_DIR/vps-configs/" 2>/dev/null || true
[ -d /etc/nginx/sites-enabled ] && cp -r /etc/nginx/sites-enabled "$TEMP_DIR/vps-configs/nginx-sites" 2>/dev/null || true
find /root -maxdepth 2 -name "docker-compose*.yml" -exec cp {} "$TEMP_DIR/vps-configs/" \; 2>/dev/null || true
find /root -maxdepth 2 -name ".env" -exec cp --parents {} "$TEMP_DIR/vps-configs/" \; 2>/dev/null || true
echo "  OK — Configs da VPS copiadas"

echo "[4/4] Compactando e salvando backup..."
tar -czf "$ARQUIVO_BACKUP" -C "$TEMP_DIR" .
rm -rf "$TEMP_DIR"
TAMANHO=$(du -sh "$ARQUIVO_BACKUP" | cut -f1)
echo "  OK — Arquivo: $ARQUIVO_BACKUP ($TAMANHO)"

echo ""
echo "Limpando backups antigos (mantendo últimos $MAX_BACKUPS)..."
ls -t "$PASTA_BACKUP"/upvia-*.tar.gz 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | while read arquivo_antigo; do
  echo "  Removendo: $arquivo_antigo"
  rm -f "$arquivo_antigo"
done

echo ""
echo "Backups disponíveis:"
ls -lh "$PASTA_BACKUP"/upvia-*.tar.gz 2>/dev/null || echo "  (nenhum)"

echo ""
echo "BACKUP CONCLUÍDO — $DATA $HORA"
echo "=============================="
