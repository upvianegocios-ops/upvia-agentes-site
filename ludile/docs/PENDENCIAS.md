# Pendências e riscos antes do piloto

Lista honesta do que foi construído mas não pôde ser validado ponta a
ponta neste ambiente, do que foi conscientemente simplificado para o MVP,
e das decisões já tomadas (com o porquê). Ler antes de liberar para a
escola/família piloto.

## Bloqueios de ambiente (não são decisões de produto)

1. **Deploy real na VPS ainda não aconteceu.** Tentativa de SSH a partir
   desta máquina (`ssh root@187.127.29.198`) chegou a alcançar o servidor
   mas falhou na autenticação: `Permission denied (publickey,password)` —
   não há chave privada correspondente nesta máquina em `~/.ssh` (só existe
   `known_hosts`, o que indica que alguém já se conectou a esse servidor
   *de outro lugar*, não daqui). Não tentei senha nem qualquer contorno.
   Todo o `docker/`/`nginx/` foi escrito, revisado e testado localmente
   (ver item 2), mas **nunca executado contra a VPS real** — falta uma
   chave SSH válida (ou acesso via console da Hostinger/EasyPanel) para
   destravar isso. Depois de resolvido, seguir `docs/DEPLOY.md` do início
   ao fim.
2. **Sem Docker nem Postgres local nesta máquina** — não foi possível
   rodar o stack self-hosted nem testar contra um banco real. O que **foi**
   validado localmente e está verde: `npm run typecheck` (zero erros),
   `npm run lint` (zero avisos), `npm test` (20/20 testes unitários
   passando — motor de dificuldade, recompensas, PIN, componente de UI),
   `npm run build` (build de produção completo, as 13 rotas compilando) e
   um smoke test manual do servidor local (`/`, `/login`, `/cadastro`
   respondendo 200; `/api/health` degradando graciosamente sem banco —
   inclusive corrigi ali um bug real de healthcheck que podia ficar
   pendurado indefinidamente sem timeout).
   **O "teste especial do jogo" da seção 20 (fluxo completo criança do
   zero, contra dado real) ainda não rodou de ponta a ponta** — só é
   possível depois do item 1 (deploy) ou de um ambiente com Docker local.
3. **Supabase Cloud não usado** — a organização já tinha 2/2 projetos
   gratuitos ocupados por `memoria-upvia` e `vendedor-ia-saas` (produção do
   UpVia). Em vez de mexer nesses projetos, o banco do Ludilê é
   self-hosted na própria VPS (decisão tomada com Elisa/Jean). Isso muda
   o "onde" mas não o "como" — o app usa `@supabase/supabase-js` do mesmo
   jeito.

## Decisões conscientes já tomadas para o MVP/piloto

- **Confirmação de e-mail desligada no cadastro** (`ENABLE_EMAIL_AUTOCONFIRM=true`
  em `docker/supabase/.env.example`) — decisão explícita para o piloto
  fechado: como Elisa/Jean vão cadastrar os perfis das famílias piloto
  manualmente, e ainda não há um provedor SMTP configurado, exigir
  confirmação por e-mail travaria o cadastro sem necessidade nenhuma nesse
  contexto restrito. **Reavaliar antes de abrir cadastro público** — nunca
  deixar autoconfirm ligado fora de um piloto fechado com famílias
  conhecidas (ver `docs/DEPLOY.md`, seção 2).
- **Fila offline permanece em `localStorage`** (`lib/offline/queue.ts`),
  como já documentado — suficiente para o volume do MVP. Migrar para
  IndexedDB só se o uso offline real crescer muito. Sem alteração nesta
  rodada.
- **Áudios/ícones seguem placeholder** — fallback de SpeechSynthesis do
  navegador cobre a experiência por enquanto; gravação/arte final fica
  para uma etapa separada.

## Simplificações conscientes do MVP

4. ~~Edição de atividade no admin~~ — **resolvido.** `/admin/atividades/[id]`
   agora tem formulário completo de edição (reaproveita os mesmos campos
   do formulário de criação via `components/admin/ActivityFormFields.tsx`),
   com link "Editar" na listagem. CRUD completo nas 4 operações.
5. **Assets de áudio/imagem reais** — `database/seed/001_vila_das_letras.sql`
   referencia caminhos (`/audio/letters/a.mp3` etc.) que **não existem
   ainda como arquivos**; o app cai automaticamente para o fallback
   SpeechSynthesis quando o arquivo não carrega, então a experiência
   funciona, mas sem a voz gravada de qualidade que o produto final merece.
   Ícones do app (`public/icons/icon.svg`) são placeholder de texto, não
   arte final. (Tratado separadamente, fora desta rodada.)
6. **Seletor de fonte para dislexia** — o CSS já suporta
   `body[data-font="dislexia"]` (`app/globals.css`), mas falta (a) a fonte
   OpenDyslexic de fato incluída no projeto e (b) a tela de configurações
   de acessibilidade que deixa a criança/responsável escolher isso. O
   restante da seção 6 (contraste, sem cor sozinha, toque grande,
   reduced-motion) está implementado.
7. **Offline (seção 17)** — fila de sincronização usa `localStorage`,
   como decidido acima. **Gravar a tentativa individual funciona offline,
   mas fechar a missão (`completeMission`) ainda exige rede** — se a
   criança terminar a missão sem internet, a tela de recompensa não
   aparece até voltar a conexão. Aceitável para o piloto fechado, mas vale
   resolver antes de uma escola com Wi-Fi instável depender disso.
8. **Realtime, Storage e Edge Functions do Supabase** estão no stack
   self-hosted (vendorizado) mas **não são usados por nenhuma tela ainda**
   — todo áudio/imagem hoje é servido como arquivo estático do Next.js
   (`public/`). Migrar para Supabase Storage é trivial (trocar a URL),
   mas não foi feito porque não havia asset real para subir.
9. **Painel administrativo** cobre atividades (CRUD completo agora);
   **não cobre ainda** fases (worlds/missions), perguntas de história
   (`story_questions`), usuários (`org_members`) nem estatísticas
   agregadas além do dashboard simples em `/admin`. O schema e as queries
   (`lib/data/admin-queries.ts`) já suportam expandir isso sem mudar a
   arquitetura.
10. **E-mail transacional (SMTP)** — decisão tomada acima (autoconfirm
    ligado para o piloto fechado). Continua faltando um provedor SMTP real
    para quando o produto sair do piloto fechado (recuperação de senha
    também depende disso).

## Antes de liberar para a escola (checklist)

- [ ] Resolver o acesso SSH à VPS (item 1) e rodar `docs/DEPLOY.md` do
      início ao fim contra a VPS real
- [ ] Rodar o teste especial do jogo (seção 20) manualmente no ambiente real
- [ ] Configurar SMTP real e voltar `ENABLE_EMAIL_AUTOCONFIRM` para `false`
- [ ] Gravar/contratar os áudios reais das letras e instruções
- [x] Edição de atividades no admin
- [x] Decisão sobre autoconfirm de e-mail no piloto (Elisa/Jean cadastram manualmente)
- [ ] Confirmar subdomínio do piloto não está indexado nem linkado publicamente
