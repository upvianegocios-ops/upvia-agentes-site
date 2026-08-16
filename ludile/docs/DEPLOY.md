# Deploy — Ludilê

> **Pré-requisito bloqueante:** este passo a passo precisa de acesso SSH à
> VPS, que não estava disponível na máquina onde o projeto foi construído.
> Assim que o acesso existir, siga os passos abaixo em ordem. Nada aqui foi
> executado contra a VPS — só preparado localmente.

## 0. Antes de começar (seção 1 — auditoria obrigatória)

```bash
ssh root@SEU_IP_VPS
docker ps -a                 # confirmar que não existe container ludile-* nem porta 8000/5432 em uso
docker network ls | grep ludile
df -h && free -h             # confirmar espaço/memória disponíveis
```

Se qualquer porta/nome já estiver em uso, pare e ajuste `docker/supabase/.env`
antes de continuar — nunca force a subida por cima de algo existente.

## 1. Levar o código para a VPS

```bash
# Na sua máquina:
git add ludile/
git commit -m "feat: MVP Ludile - Mundo 1 Vila das Letras"
git push

# Na VPS:
git clone <url-do-repo> /root/ludile-deploy   # ou git pull se já clonado
cd /root/ludile-deploy/ludile
```

## 2. Gerar os segredos do Supabase self-hosted

**Nunca subir os containers com os valores de exemplo do `.env.example`.**

```bash
cd docker/supabase
cp .env.example .env
bash utils/generate-keys.sh      # gera JWT_SECRET, ANON_KEY, SERVICE_ROLE_KEY etc.
bash utils/add-new-auth-keys.sh  # gera as chaves assimétricas (ES256) mais novas
```

Edite manualmente em `.env`:

```
POSTGRES_PASSWORD=<senha forte, só para este projeto>
SITE_URL=https://ludile.upviaagentes.com.br        # ou o subdomínio escolhido
API_EXTERNAL_URL=https://ludile.upviaagentes.com.br/auth/v1
SUPABASE_PUBLIC_URL=https://ludile.upviaagentes.com.br
DASHBOARD_USERNAME=<usuário do Studio>
DASHBOARD_PASSWORD=<senha forte>
POOLER_TENANT_ID=ludile
STUDIO_DEFAULT_ORGANIZATION=Ludile
STUDIO_DEFAULT_PROJECT=Ludile
DISABLE_SIGNUP=false
```

`ENABLE_EMAIL_AUTOCONFIRM` já vem `true` no `.env.example` — decisão consciente
para o piloto fechado (sem SMTP configurado ainda, Elisa/Jean cadastram as
famílias piloto manualmente). Ver `docs/PENDENCIAS.md`, item 10. **Voltar
para `false` antes de abrir cadastro público**, quando houver SMTP real.

## 3. Subir o Supabase self-hosted

```bash
cd docker/supabase
docker compose up -d
docker compose ps          # todos os serviços devem ficar "healthy"
```

Isso cria a rede `ludile_default` e já aplica o schema do Ludilê
automaticamente (migrations `999-ludile-init.sql` e `9999-ludile-seed.sql`
montadas no container do banco).

## 4. Configurar o `.env` do app

```bash
cd ../..    # volta para ludile/
cp .env.example .env
```

Preencha:

```
NEXT_PUBLIC_SUPABASE_URL=http://envoy:8000        # nome do serviço na rede interna
NEXT_PUBLIC_SUPABASE_ANON_KEY=<ANON_KEY do docker/supabase/.env>
SUPABASE_SERVICE_ROLE_KEY=<SERVICE_ROLE_KEY do docker/supabase/.env>
NEXT_PUBLIC_SITE_URL=https://ludile.upviaagentes.com.br
```

## 5. Subir o app + Nginx

```bash
docker compose -f docker/docker-compose.app.yml up -d --build
docker compose -f docker/docker-compose.app.yml ps
curl http://127.0.0.1:8080/api/health
```

## 6. Publicar no subdomínio (duas opções — escolha uma)

### Opção A — EasyPanel/Traefik (recomendado, consistente com o resto da VPS)

1. No EasyPanel, criar um novo serviço apontando para a imagem já buildada
   (`ludile-app`) ou para o repositório, porta interna `3000`.
2. Configurar o domínio (`ludile.upviaagentes.com.br` ou subdomínio de
   teste do piloto) com SSL automático do EasyPanel.
3. Não é necessário o container `ludile-nginx` neste caso — pode ser
   removido do `docker-compose.app.yml` ou deixado só para uso local.

### Opção B — Nginx próprio + Certbot (se for fora do EasyPanel)

```nginx
# /etc/nginx/sites-available/ludile.conf no HOST (não no container)
server {
    listen 80;
    server_name ludile.upviaagentes.com.br;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/ludile.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d ludile.upviaagentes.com.br
```

## 7. Piloto privado não indexado (seção 27 — obrigatório antes de qualquer divulgação)

- [x] `robots.txt` já bloqueia indexação (`public/robots.txt`) e o Next.js
      já manda `X-Robots-Tag: noindex, nofollow` em toda rota
      (`next.config.js`).
- [ ] Confirmar que o subdomínio escolhido para o piloto **não** tem link
      público em nenhum lugar (site institucional, redes sociais).
- [ ] Cadastrar manualmente 1–2 famílias piloto (o próprio responsável cria
      o perfil da criança pelo fluxo normal de cadastro).
- [ ] Confirmar PIN da área dos responsáveis funcionando antes de liberar
      para a família piloto.

## 8. Verificação pós-deploy

```bash
curl https://ludile.upviaagentes.com.br/api/health
# {"status":"ok","database":"ok",...}
```

Repita o "teste especial do jogo" da seção 20 manualmente contra o ambiente
real (criar perfil → mapa → missão → errar → pista → acertar → recompensa →
sair/entrar → progresso mantido) antes de liberar para a escola piloto.

## Backup (seção 19)

```bash
# Banco:
docker exec ludile-db pg_dump -U postgres postgres > backup-ludile-$(date +%F).sql

# Volumes (uploads, config do Postgres):
tar -czf ludile-volumes-$(date +%F).tar.gz docker/supabase/volumes/db/data
```

Agendar via cron da mesma forma que o `vps/backup-diario.sh` do UpVia, mas
em pasta e destino próprios — nunca misturar com o backup do UpVia.

## Rollback

```bash
docker compose -f docker/docker-compose.app.yml down
docker compose -f docker/supabase/docker-compose.yml down   # mantém os volumes (dados) por padrão
```

Para restaurar um backup de banco: subir o stack limpo, depois
`psql ... < backup-ludile-<data>.sql` antes de religar o tráfego.
