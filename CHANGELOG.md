# Changelog

## 2026-08-04 — AtendentIA Multi-Atendimento SaaS (race condition — IA respondia depois de #pausar/#parar)

**Problema:** Andressa (tenant `studio_andrade`) estava respondendo uma cliente manualmente e mandou `#pausar`/`#parar` para travar a IA naquele contato. A IA continuou respondendo em paralelo, atropelando as respostas manuais — obrigou a desconectar o WhatsApp da instância pra conseguir atender.

**Causa raiz:** `#parar` já era reconhecido (mesmo regex de `#pausar`/`#humano`/`#pause` em `Decisor Central`) e a gravação/leitura do lock (`trava_atendimento_humano`) já usava chave consistente — não era bug de comando nem de chave. O lock (`humano_assumiu`) só era checado **uma vez**, no início da execução (`Supabase - Buscar Sessao` → `Humano Assumiu?`), antes do buffer/debounce (`Intervalo`, node `Wait`). Se o dono mandasse `#pausar`/`#parar` **enquanto a mensagem do cliente já estava esperando o debounce**, a execução em curso acordava do `Wait` e ia direto pra `Atendente` sem re-checar o lock — respondendo mesmo com a trava já ativa. Falha arquitetural pré-existente (já estava lá no `Wait` de 4s antes do fix de buffer de 2026-07-15), mas o fix de buffer/debounce (`8958ec6`) aumentou a janela de espera de 4s pra 12s (`Config Debounce`), triplicando a chance de a corrida acontecer.

**Correção aplicada:** novo trecho `Compara → Supabase - Recheck Trava Pos Buffer → Humano Assumiu Apos Buffer?` inserido antes de `Rotear Decisao Buffer`. Re-checa `humano_assumiu` (mesma lógica do `Humano Assumiu?` original, incluindo janela de 120min) logo antes de decidir consolidar/perguntar/enviar. Se o dono assumiu durante a espera, para em `IA Bloqueada Apos Buffer` (não envia); senão segue normal pro fluxo existente. Nenhum node/conexão existente foi removido ou renomeado.

**Aplicação:** `PATCH` recusado pela API (`405 PATCH method not allowed`, mesmo comportamento do fix de 15/07). Autorizado `PUT` com o workflow completo (179 nodes, não parcial) — mesmo precedente. Antes de aplicar a correção real, foi feito um round-trip de teste (PUT com os 176 nodes originais inalterados) pra confirmar que a API não esvaziava nada; só depois foi enviado o PUT com a correção. Pós-aplicação: 179 nodes confirmados via GET independente, sem conexão pendurada, sem duplicidade, e os caminhos existentes (`Decisor Central`, `Switch1`, `Validar RemoteJid → Ativar Trava`, `Rotear Decisao Buffer`) continuam intactos. Execuções reais logo após o deploy (webhook, incluindo uma passando pelo caminho `Ativar Trava`) rodaram com sucesso, sem erro novo.

**Validado por:** usuário autorizou diagnóstico e o `PUT` explicitamente nesta conversa.
**Backup:** `n8n-workflows/AtendentIA-Multi-Atendimento-SaaS-backup-2026-07-31-pre-fix-lock-race-buffer.json` (antes) e `n8n-workflows/AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-04-pos-fix-lock-race-buffer.json` (depois).
**Commits:** ver commit desta alteração.

---

### ⚠️ ADENDO (mesmo dia, algumas horas depois) — teste ao vivo revelou a causa raiz real + uma regressão introduzida pelo fix acima

O usuário pediu pra automatizar o teste ao vivo do cenário (mensagem de cliente entra no buffer, `#pausar` chega dentro dos 12s, confirmar que a IA NÃO responde; e teste inverso, cliente novo sem interferência, confirmar que responde normal). Simulei os dois cenários com números de teste fake (`5500000099xxx`, nunca usados por cliente real) direto no webhook de produção (`/webhook/atendente-webhook`, instância `studio-andrade`). Isso expôs dois problemas que a análise estática não pegou:

**1) Causa raiz real do bug original — regex quebrado (backspace literal em vez de `\b`):** no node `Decisor Central`, os dois regexes de detecção de comando —
`/^#(reativar|retomar|voltar|despausar)\b/i` e `/^#(pausar|humano|pause|parar)\b/i` — continham um **caractere de backspace literal (código 8)** no lugar da sequência de dois caracteres `\` + `b` (confirmado via `charCodeAt`, replay isolado do código exato contra o input exato capturado na execução de teste). Um regex com backspace literal exige um caractere de backspace de verdade no texto pra casar, o que nunca acontece em mensagem real — ou seja, `isPauseCmd` e `isReactivateCmd` eram **sempre `false`**, pra qualquer mensagem, desde que esse trecho foi escrito. Resultado: `#pausar`/`#parar`/`#humano`/`#pause` e `#reativar`/`#retomar`/`#voltar`/`#despausar` **nunca ativavam nem desativavam a trava** — caíam no `else` (`comando_proprietario`), que só funciona se o número bater com o dono E é interpretado por uma IA que não conhece esses comandos. Esse era o bug de verdade que a Andressa sofreu — não só a corrida com o buffer (que também era real, mas nunca chegava a importar, porque a trava nunca era escrita pelo comando). Corrigido: os dois caracteres de backspace foram substituídos pela sequência correta `\b`. Validado: replay local confirma `#pausar`→match, `#pausaria`→não-match (boundary funcionando), etc.

**2) Regressão introduzida pelo meu próprio fix de race condition:** o node Postgres `Supabase - Recheck Trava Pos Buffer` (novo, adicionado no fix acima) devolve **apenas as colunas da query** (`humano_assumiu`, `humano_assumiu_em`) — um node Postgres não repassa os campos de entrada automaticamente. Isso descartava `_acao`, `telefone`, `instancia`, `text`, `mensagens` etc. antes de chegar em `Rotear Decisao Buffer`, cujo switch depende de `$json._acao`. Com `_acao` ausente, nenhuma regra do switch casava — a mensagem morria em silêncio, sem erro, sem resposta. Isso quebrou o caminho normal (sem trava ativa) pra **qualquer tenant**, não só Studio Andrade, desde o deploy do primeiro fix (~13:10 UTC) até a correção (~19:44 UTC), sempre que uma conversa passava pelo buffer/debounce sem lock ativo — ou seja, a maioria das conversas normais nesse intervalo. Pego e corrigido no mesmo teste ao vivo, antes de declarar o trabalho concluído.

**Correção da regressão:** novo node `Restaurar Dados Pos Recheck` (Code) entre `Supabase - Recheck Trava Pos Buffer` e `Humano Assumiu Apos Buffer?` — remonta o item completo a partir de `$('Compara').first().json` + os campos de lock da query, antes de seguir pro `Humano Assumiu Apos Buffer?` / `Rotear Decisao Buffer`.

**Teste final (3ª rodada, após as duas correções, contra produção real):**
- Cliente teste manda mensagem → entra no buffer → dono manda `#pausar` 3s depois (dentro dos 12s de debounce) → `_acao: humano_falou` confirmado, trava gravada (`Supabase - Ativar Trava`) → mensagem original do cliente re-checa a trava após o Wait e para em `IA Bloqueada Apos Buffer` — **não responde**. ✅
- Cliente teste novo, sem interferência → buffer normal → `Restaurar Dados Pos Recheck` → `Rotear Decisao Buffer` → `Acumula` → `Atendente` gerou resposta real e coerente (preço de esmaltação em gel decorada, usando a tabela de preços do tenant) → `resposta ao cliente` enviou sem erro. **Comportamento normal 100% preservado.** ✅

Dados de teste (6 números fake `5500000099xxx`) removidos de `dados_cliente` e `trava_atendimento_humano` após validação.

**Backup:** `AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-04-pre-fix-decisor-central-backspace-regex.json`, `AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-04-pre-fix-dataloss-recheck-buffer.json`, `AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-04-pos-fix-completo-validado.json` (estado final, 180 nodes).

**Auditoria retroativa (concluída):** varredura de todas as 983 execuções `webhook` da janela `2026-08-04T13:13:39Z`–`2026-08-04T19:43:50Z` (todos os tenants), buscando a assinatura exata do bug (`Rotear Decisao Buffer` rodou, nenhum dos 3 branches — `Acumula`/`Marcar Pergunta Feita`/`Para o Fluxo` — rodou depois, e não foi um bloqueio legítimo via `IA Bloqueada Apos Buffer`).

**Resultado: 13 mensagens reais de 9 clientes distintos ficaram sem resposta da IA**, todas em **um único tenant: `ariane-d-avila-afonso-advocaci`** (nenhum outro tenant, incluindo `studio_andrade`, foi afetado nessa janela). Números/horários (UTC):
- `5528992515342` — 14:08 — "Cansado... mas seguimos"
- `555384514026` — 14:13 — "Bom dia essa é o empréstimo que eu fiz pra fazer p..."
- `555399479727` — 15:08 — "Bom diaa, bora essa quinta?"
- `555399907907` — 15:10 (3 msgs) — "Olá, Dra. Ariane." / "Bom dia." / "Muito prazer, me chamo Yago Caldeira, advogado da..."
- `555391757916` — 16:03 (2 msgs) — "Oi" / "Boa tarde"
- `555391477884` — 16:38 (2 msgs) — **percebeu o bug em tempo real**: "Bugou teu chat kkkkk" / "Ta toda hora me mandando opções de atendimento 😂" — candidato prioritário pra um follow-up pessoal, esse cliente sabe que algo quebrou
- `554195142615` — 17:17 — mensagem de áudio (sem texto extraído)
- `555196176229` — 17:36 — mensagem de áudio (sem texto extraído)
- `555399404636` — 18:30 — "Oi 🌷"

Execution IDs (pra conferir no n8n): 124615, 124635, 124810, 124833, 124834, 124842, 125026, 125027, 125146, 125147, 125254, 125286, 125450.

**Pendente:** avisar a Ariane (tenant `ariane-d-avila-afonso-advocaci`) pra fazer follow-up manual com esses 9 contatos, priorizando `555391477884` (já percebeu o bug) e `555384514026`/`555399907907` (mensagens com conteúdo que sugere assunto sensível/profissional).

## 2026-07-16 — AtendentIA Multi-Atendimento SaaS (hotfix urgente — Task Runner travando)

**Problema:** na noite de 2026-07-15 (~23:02-23:33 BRT), a fila de mensagens do N8N encheu — mensagens novas de qualquer tenant ficavam "Waiting in the queue" indefinidamente. Reportado como possível fila zumbi + timeout de 300s no node `Montar Buffer Atualizado` (execução #95002).

**Causa raiz:** `detectarTipo()` no node `Montar Buffer Atualizado` (criado no fix do buffer/debounce de 2026-07-15) chamava `$('Envio de Imagens').first()`, `$('Mensagem de Audio').first()` e `$('Envio de Documentos').first()` — nodes que só rodam em UM dos 5 branches do `Switch` por execução. Referenciar um node sem `runData` na execução atual **trava o Task Runner do N8N** (processo externo que roda o código dos nodes Code) em vez de lançar um erro capturável pelo `try/catch`. Cada vez que isso acontecia, o N8N suspeitava o runner de estar sem resposta e o reiniciava à força depois de 300s — derrubando em cascata **todas as outras execuções concorrentes que estavam usando aquele mesmo processo**, de qualquer tenant, incluindo nodes sem nenhuma relação com o bug (ex: `Filtro + Extrair` chegou a falhar com "Task request timed out after 60 seconds").

**Confirmado:** afetou pelo menos `studio-andrade` e `ariane-d-avila-afonso-advocaci` — pelo menos 3 reinícios forçados do runner identificados (execuções #94901, #94929, #94952, além da #95002).

**Diagnóstico separado:** havia também uma execução isolada travada em "running" desde 2026-07-10 (ID 81887), mas pertence a outro workflow (`Cadastro Automatico UpvIA v5`) — não relacionada a este bug. A API pública do N8N não permite parar/deletar execução em "running" (`"Cannot delete a running execution"`); só dá pra encerrar pela interface. Pendente: Elisa parar manualmente pela UI se quiser (baixo impacto, não estava bloqueando o AtendentIA).

**Correção aplicada:** `detectarTipo()` reescrito para ler o tipo da mensagem direto do payload bruto do `Webhook` (node que sempre roda, sem ambiguidade) em vez de referenciar nodes de outros branches. Adicionado try/catch externo no node inteiro — se falhar, falha rápido e o buffer no Redis fica intacto (TTL 300s) pra próxima mensagem retomar, sem travar a fila.

**Validado por:** Elisa (autorizou ação imediata dada a urgência; diagnóstico revisado por completo, incluindo evidência da execução #95002 e da rajada de erros).
**Backup:** `n8n-workflows/AtendentIA-Multi-Atendimento-SaaS-backup-2026-07-16-pre-hotfix-task-runner-hang.json` (antes) e `...-pos-hotfix-task-runner-hang.json` (depois).
**Commits:** `357ecbe` (backup), `e1c03aa` (hotfix)

**Pendente:** validação ao vivo de que o buffer/debounce (mensagens múltiplas, incluindo fotos/áudio/documento) funciona sem travar a fila. Elisa decidir se quer parar manualmente a execução zumbi #81887 (outro workflow, baixo impacto).

## 2026-07-15 — AtendentIA Multi-Atendimento SaaS

**Problema:** Trava automática de IA quando o dono do número manda mensagem manual (`Decisor Central` → `Supabase - Ativar Trava (Humano Falou)`) estava ativa globalmente para todos os tenants desde 2026-07-11, sem opção de desligar. Tenant Ariane D'Avila Afonso Advocacia precisa desse comportamento (evita a IA responder terceiros institucionais que ela mesma contatou), mas outros tenants como Studio Andrade não — e estavam tendo clientes travados sem saber.

**Causa raiz:** Feature adicionada em 2026-07-11 sem configuração por tenant.

**Correção aplicada:**
1. Nova coluna `clientes_sistema.trava_conversas_iniciadas_pelo_owner` (boolean, default `false`). `true` apenas para `ariane-d-avila-afonso-advocaci`.
2. Novo node `Carregar Flag Trava Owner` (lookup leve, antes do `Decisor Central`) + `Decisor Central` editado para só travar mensagem manual sem `#` quando a flag do tenant for `true`.
3. Novo comando `#reativar` / `#retomar` / `#voltar` / `#despausar` para o dono destravar manualmente um contato (`Switch1` + `Validar RemoteJid Reativar` + `Supabase - Reativar IA (Comando Owner)` + `Confirmar Reativacao`).
4. Limpeza de dados: 68 contatos travados residuais (66 Studio Andrade + 2 UpvIA Automações) resetados via `UPDATE trava_atendimento_humano`, já que a trava nunca deveria ter sido ativada pra esses tenants. Os 76 contatos travados da Ariane não foram tocados (comportamento desejado).

**Validado por:** Elisa (diagnóstico revisado e aprovado antes do PATCH; aplicação via `PUT` autorizada explicitamente após a API recusar `PATCH` com 405).
**Backup:** `n8n-workflows/AtendentIA-Multi-Atendimento-SaaS-backup-2026-07-14-1318-pre-trava-owner-diagnostico.json` (antes) e `n8n-workflows/AtendentIA-Multi-Atendimento-SaaS-backup-2026-07-15-0147-pos-trava-owner-configuravel.json` (depois).
**Migração:** `supabase/migrations/20260714_add_trava_conversas_iniciadas_pelo_owner.sql`
**Commits:** `736ce67` (backup), `21b1811` (feature)

**Pendente:** validação ao vivo dos 3 cenários (Ariane trava, Studio Andrade não trava, `#reativar` funciona) — ver conversa do Claude Code.

## 2026-07-15 — AtendentIA Multi-Atendimento SaaS (buffer/debounce de mensagens)

**Problema:** cliente mandando várias mensagens em sequência (principalmente fotos, ex: cliente da Ariane D'Avila Afonso enviando fotos de um processo) recebia uma resposta separada da IA por mensagem, em vez de uma análise única e consolidada.

**Causa raiz:** já existia um mecanismo de buffer/debounce (Redis + node `Wait`), mas estava quebrado em 5 pontos: (1) chave gravada no Redis (`telefone`) não batia com a chave lida (`instancia:telefone`); (2) o campo `instancia` nem existia nesse trecho do fluxo; (3) a gravação fazia `SET` (sobrescreve) em vez de acumular lista; (4) o node `Compara` sempre seguia em frente por causa do fallback, então o `Wait` não impedia nada; (5) o tempo de espera configurado era 4s (sem unidade explícita), não 12s. Resultado prático: cada mensagem processava e respondia sozinha, imediatamente.

**Correção aplicada:**
1. `Config Debounce` (novo): centraliza `debounce_segundos = 12` e `limite_fotos_referencia = 5`.
2. `Mensagem` (editado): passa a incluir `instancia` (de `Montar Contexto Dinamico`), corrigindo a causa raiz das chaves quebradas.
3. `Buscar Buffer Atual` + `Montar Buffer Atualizado` (novos): leem o buffer existente e acrescentam a mensagem nova numa lista real (tipo + conteúdo + timestamp), em vez de sobrescrever.
4. `Incluir Mensagem` / `Buscar Mensagens` (editados/corrigidos): chave consistente `instancia:telefone` nos dois lados.
5. `Intervalo` (editado): usa `Config Debounce` (12s) em vez do valor fixo de 4.
6. `Compara` (reescrito): vira o juiz do debounce — só a execução da mensagem mais recente segue adiante (`souAMaisRecente`); as demais param sozinhas (`stale`).
7. `Rotear Decisao Buffer` + `Marcar Pergunta Feita` + `Perguntar Mais Fotos` (novos): quando o buffer atinge 5 fotos, manda "Recebi essas imagens, são todas ou vai enviar mais alguma?", marca que já perguntou (não repete) e volta pro `Intervalo` aguardando mais 12s antes de decidir consolidar. Limite técnico da OpenAI (1500 imagens/512MB por request, confirmado na doc oficial) está muito acima disso — 5 é só um gatilho de UX, não um corte técnico.
8. Reordenado `Acumula → Atendente → Apaga Mensagens` (era `Acumula → Apaga Mensagens → Atendente`): o buffer só é limpo depois que a IA responde com sucesso; se falhar, a execução para sozinha e o buffer fica intacto pra próxima mensagem retomar.

Aplica pra todos os tenants (não é específico da Ariane).

**Validado por:** Elisa (diagnóstico e desenho da lógica revisados e aprovados antes do PATCH).
**Backup:** `n8n-workflows/AtendentIA-Multi-Atendimento-SaaS-backup-2026-07-15-pre-buffer-debounce.json` (antes) e `n8n-workflows/AtendentIA-Multi-Atendimento-SaaS-backup-2026-07-15-1119-pos-buffer-debounce.json` (depois).
**Commits:** `114162a` (backup), `8958ec6` (fix)

**Pendente:** validação ao vivo — mandar 3-4 fotos em sequência rápida (menos de 12s entre elas) e confirmar resposta única; mandar 5+ fotos e confirmar a pergunta de confirmação; testar prioritariamente no tenant Ariane.
