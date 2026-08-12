# Changelog

## 2026-08-12 (manhã) — AtendentIA Multi-Atendimento SaaS (hotfix: regressão na trava automática, causada pelo fix de notificação de ontem)

**Problema (relato real da Ariane):** depois dos testes de ontem à noite, a IA voltou a responder clientes mesmo com a Ariane já respondendo manualmente pelo WhatsApp — a trava automática (`trava_conversas_iniciadas_pelo_owner`) parou de ativar.

**Causa raiz:** regressão introduzida pelo próprio fix de notificação de ontem (ver entrada anterior). O node novo `Carregar Dedup Notificacao Handoff` foi ligado **em série** entre `Carregar Flag Trava Owner` e `Decisor Central`, substituindo o que este último recebe como `$json`. `Decisor Central` lê `item.json.trava_conversas_iniciadas_pelo_owner` direto (sem `$('...')`), campo que só existe no resultado de `Carregar Flag Trava Owner` — com o node novo no meio, esse campo virou sempre `undefined`, e o guard `if (!travaOwnerAtivada) continue;` passou a pular sempre o branch da trava automática.

**Confirmado em produção:** 27 mensagens manuais da Ariane ontem à noite (contato 555391229712 entre outros) — `Supabase - Ativar Trava (Humano Falou)` não rodou em nenhuma. Caso concreto: exec `133709` ("Perdão minha secretária te atendeu", ela mesma respondendo) → trava não ativa → exec `133712`, cliente manda "Desculpa o horário dra" → IA responde de novo, por cima da Ariane.

**Correção:** `Carregar Flag Trava Owner` volta a alimentar `Decisor Central` diretamente, e passa a alimentar `Carregar Dedup Notificacao Handoff` **em paralelo** (mesmo padrão de fan-out já usado em `Pediu Humano?`), não mais em série. `Carregar Dedup Notificacao Handoff` vira nó-folha (sem saída), lido só por referência cruzada `$('Carregar Dedup Notificacao Handoff')` pelos nodes de notificação — não muda nada da lógica de dedup em si. Diff mínimo: os 202 nodes ficaram byte-a-byte idênticos, só a conexão de `Carregar Flag Trava Owner` mudou.

**Validado em produção real:** após o fix, mensagens manuais da Ariane voltaram a marcar `_acao: "humano_falou"` no `Decisor Central` e ativar a trava (`Supabase - Ativar Trava` rodando); mensagem de cliente logo em seguida ("Bom dia") não gerou resposta da IA — trava funcionando.

**Backup:** `AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-12-1056-pre-fix-regressao-trava-automatica.json` (antes) → `AtendentIA-Multi-Atendimento-SaaS-NOVO-2026-08-12-fix-regressao-trava-automatica.json` (depois, estado final, 202 nodes).

**Lição:** ao inserir um node novo no meio de uma cadeia existente, checar se algum node downstream lê `$json` direto (em vez de `$('NomeDoNode')`) antes de substituir a ligação em série — nesses casos, ligar em paralelo (fan-out) em vez de intercalar.

---

## 2026-08-11 (noite) — AtendentIA Multi-Atendimento SaaS (fix: notificação de handoff disparando em toda resposta da IA durante a triagem)

**Problema (relato real da Ariane):** a notificação "🔔 Atendimento pronto para você" disparava a cada resposta da IA durante uma triagem em andamento (várias por conversa), não só quando a triagem de fato terminava — spam.

**Causa raiz:** não era bug de lógica quebrada — `notificar_toda_interacao=true` (ligado só pra Ariane desde 06/08) fazia exatamente o que foi projetado pra fazer: notificar em toda resposta da IA. Na prática, com triagens de várias perguntas, isso virou ruído. Não existia nenhuma trava contra repetição em nenhum dos 2 gatilhos "sobre o cliente" (`toda_interacao` / `pediu_humano`).

**Migração** (`supabase/migrations/20260811_dedup_e_conclusao_triagem_notificacao.sql`) — 2 colunas novas: `clientes_sistema.palavras_conclusao_triagem` (mesmo padrão de `palavras_urgencia`, várias variações separadas por vírgula pra tolerar paráfrase da IA — pra Ariane: `vou encaminhar,passarei essas informações,dra. ariane vai analisar,dra. ariane vai retornar,entrará em contato`) + `trava_atendimento_humano.notificacao_handoff_enviada_em` (timestamp de dedup, reaproveitando a mesma janela de 2h de `humano_assumiu_em`).

**Nodes novos:** `Carregar Dedup Notificacao Handoff` (lê `humano_assumiu` + `notificacao_handoff_enviada_em` do contato, cedo no fluxo) e `Marcar Notificacao Enviada` (grava o timestamp de dedup antes de `Avisar Jean`, só nos branches `toda_interacao`/`pediu_humano` — não em `Notificar Bloqueio Institucional`, feature separada). `Avaliar Notificacao Pos Resposta` só marca `toda_interacao` quando a IA de fato sinaliza fim de triagem (match em `palavras_conclusao_triagem`) E ainda não notificou nessa sessão; `urgente` continua disparando sempre, sem respeitar a trava de dedup (emergência real merece alerta mesmo repetido).

**2 bugs pegos e corrigidos durante o teste ao vivo:**
1. `ctx.palavras_conclusao_triagem` chegava `undefined` em `Avaliar Notificacao Pos Resposta` — `Carregar Dados Negocio` usa lista explícita de colunas (não `SELECT *`) e `Montar Contexto Dinamico` mapeia campos explicitamente pro `ctx`; a coluna nova não passava por nenhum dos dois. Corrigido adicionando `cs.palavras_conclusao_triagem` na query e o mapeamento correspondente no `ctx`.
2. Ver entrada seguinte (regressão na trava automática) — pego só no dia seguinte, via relato real da Ariane.

**Aplicado via API (PUT), não "Import from File":** autorização explícita pra essa exceção pontual à regra do `SKILL_GOVERNANCA.md`. Descoberto durante a aplicação que o body do PUT só aceita os campos read-write do schema oficial (`name, nodes, connections, settings, staticData, pinData` — nunca `id`/`active`/`versionId`/etc, que são read-only) e que o `settings` desta instância específica do n8n só aceita um subconjunto de campos mais antigo que o da doc do GitHub (sem `binaryMode`/`timeSavedMode`/`availableInMCP`) — provavelmente a causa raiz do incidente histórico de PUT "esvaziando" workflows.

**Backup:** `AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-11-2005-pre-fix-notificacao-spam-triagem.json` (antes) → `AtendentIA-Multi-Atendimento-SaaS-NOVO-2026-08-11-2350-fix2-ctx-palavras-conclusao.json` (depois, estado final, 202 nodes).

---

## 2026-08-06 (noite, 3) — AtendentIA Multi-Atendimento SaaS (feature: bloqueio automático por palavra-chave — contatos institucionais/profissionais)

**Objetivo:** a lista manual `contatos_bloqueados` da Ariane precisava ser atualizada toda vez que um novo contato profissional (vara, tribunal, advogado parceiro, perito, procurador) aparecia — inviável de manter. A IA estava triando gente que não é cliente.

**Migração** (`supabase/migrations/20260806_add_bloqueio_palavra_chave.sql`) — 2 colunas em `clientes_sistema`: `bloqueio_por_palavra_chave` (bool, default `false`) + `palavras_chave_bloqueio` (text, csv). Aplicada via workflow n8n temporário (mesmo método de hoje mais cedo). Ativado só pra Ariane: `vara,tribunal,forum,comarca,procurador,procuradoria,advogado,advogada,dr.,dra.,oab,perito,pericia,cartorio,delegacia,ministerio publico,promotoria,juiz,juiza,oficial de justica`.

**Onde entra no fluxo:** logo após `Montar Contexto Dinamico`, antes de `Guard Erro Contexto` — não em "depois de identificar o contato" como o pedido original sugeria, porque a checagem só precisa de `pushName`+texto (já disponíveis desde o início) e inserir mais cedo evita criar registro em `dados_cliente` pra um contato que vai ser ignorado de qualquer forma.

**Nodes novos:** `Verificar Palavra Chave Institucional` (checa pushName E texto da mensagem) → `Contato Institucional Detectado?` (IF) → match: `Ativar Trava Bloqueio Institucional` (grava `humano_assumiu=true`, mesmo padrão de `Supabase - Ativar Trava`) → `Notificar Bloqueio Institucional` → `Avisar Jean` (reaproveitado). Sem match: segue pro `Guard Erro Contexto` normal.

**Decisão de design — correspondência por borda de palavra, não substring:** `"dra"` como substring bateria em "qua**dra**", "consi**dra**" e outras palavras comuns — usa regex com borda de palavra (`(^|[^a-z0-9])palavra($|[^a-z0-9])`) sobre texto normalizado (sem acento, minúsculo) nos dois lados. Testado localmente antes de aplicar: "quadra de tênis" e "considera isso" **não** disparam; "Dra. Fulana" e "aqui é o perito Fulano" disparam corretamente.

**Riscos conhecidos e aceitos (usuário optou por manter a lista como especificada):**
- `dr.`/`dra.` continuam podendo disparar em uso informal não-profissional ("oi dr, tudo bem?") ou contato salvo por vaidade sem ser advogado de verdade — borda de palavra resolve o problema de substring, não resolve ambiguidade semântica. Sem confirmação extra da IA antes de bloquear (mudaria a promessa de bloqueio silencioso do pedido original).
- Trade-off oposto também existe: `"oab"` com borda de palavra **não** bate em `"OAB123"` (sem espaço) — só em uso isolado da palavra. Prioriza evitar falso positivo (bloquear cliente real) sobre pegar todo falso negativo.

**Validado (3 cenários, produção real, tenant Ariane):**
- Contato salvo como "Dr. Joao Advogado" + mensagem comum → bloqueado por nome salvo, IA não rodou, notificação disparou. ✅
- Contato com nome comum + "aqui é o perito Fulano, preciso falar com a Dra Ariane" → bloqueado por conteúdo, IA não rodou, notificação disparou. ✅
- Cliente normal (nome comum, mensagem comum) → não bloqueado, IA respondeu normalmente, notificação padrão de `toda_interacao` continuou funcionando sem interferência do novo bloqueio. ✅

**Backup:** `AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-06-pre-fix-bloqueio-institucional.json` (antes) → `...-pos-fix-bloqueio-institucional-validado.json` (depois, estado final, 200 nodes).

---

## 2026-08-06 (noite, 2) — AtendentIA Multi-Atendimento SaaS (bug crítico — notificações com quebra de linha falhavam silenciosamente)

**Contexto:** Ariane simulou uma conversa real (contato "Jean Andrade", auto-identificado como Jean Carlo Andrade da Silva, caso de cirurgia de pedra no rim pelo SUS) pra gravar a tela recebendo a notificação. Pedido pra localizar a execução e confirmar/disparar a notificação.

**Investigação:** localizada a conversa real (5 mensagens, tenant `ariane-d-avila-afonso-advocaci`, telefone `555384742117`, 17:24–17:34 UTC). **3 das 5 notificações foram enviadas, mas as 2 que mencionam o caso da cirurgia em detalhe — exatamente as mais relevantes pra gravação — falharam silenciosamente.**

**Causa raiz:** `Avisar Jean` monta o corpo da requisição HTTP inserindo `{{ $json.texto_notificacao }}` direto dentro de uma string JSON manual (`"text": "{{ ... }}"`). Quando o texto tem quebra de linha real (`\n`) — o que é comum em respostas da IA com mais de uma frase, e o próprio "Continue o atendimento de [nome]." adicionado hoje mais cedo sempre gera `\n\n` — a quebra de linha crua invalida o JSON. O node tem `onError: continueRegularOutput`, então a execução inteira aparecia como "success" mesmo com esse node falhando por dentro — só aparecia checando o campo de erro do node especificamente.

**Correção:** `jsonBody` reescrito pra usar `{{ JSON.stringify(...) }}` nos dois campos (`number` e `text`) em vez de interpolação manual de string — escapa newline/aspas/etc corretamente, robusto pra qualquer conteúdo que a IA gerar.

**Validado:** reenviei um teste com resposta multi-parágrafo (a mesma condição que causou a falha original) — `Avisar Jean` completou sem erro e a Evolution API confirmou o envio (`status: PENDING`) com o texto multi-linha preservado corretamente.

**Backup:** `AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-06-pre-fix-avisar-jean-json-escape.json` (antes) → `...-pos-fix-avisar-jean-json-escape-validado.json` (depois).
**Pendente:** decidir com o usuário se reenvia manualmente um resumo da conversa real do Jean Andrade agora que o bug está corrigido, ou se pede pra simular de novo.

---

## 2026-08-06 (noite) — AtendentIA Multi-Atendimento SaaS (correção urgente — notificação de handoff disparando pra ação da própria Ariane)

**Problema (feedback real da Ariane, print com 6+ notificações repetidas):** o gatilho "trava automática" (`trava_conversas_iniciadas_pelo_owner`) — implementado horas antes na feature de notificação — disparava toda vez que a própria Ariane mandava mensagem normal pra alguém, avisando ela de uma ação que ela mesma acabou de tomar. Ruído puro, gerou spam.

**Causa raiz:** na hora de desenhar a feature, perguntei especificamente se `#pausar` deveria notificar e recomendei que não (ação deliberada, o dono já sabe) — mas propus que a trava automática (efeito colateral de mensagem normal do dono) DEVERIA notificar, por ser "menos consciente". Na prática ficou claro que a distinção não importa: as duas são ações da própria Ariane, e ela não precisa ser avisada de nenhuma das duas.

**Correção:** desconectada a ligação `Supabase - Ativar Trava (Humano Falou) → Notificar Trava Automatica?` (volta a ser beco sem saída, como era antes de hoje). Os 3 nodes desse branch (`Notificar Trava Automatica?`, `Montar Notificacao Trava Automatica`, `Avisar Handoff Trava Automatica`) continuam no workflow mas inertes — não removidos, só desconectados (mais fácil de auditar/reverter).

**Gatilhos que continuam ativos** (únicos que fazem sentido — sempre sobre o CLIENTE, nunca sobre ação da Ariane):
1. Cliente pediu atendimento humano explicitamente (`Pediu Humano?`)
2. Pré-triagem concluída pela IA / urgência identificada (`Avaliar Notificacao Pos Resposta`, via `notificar_toda_interacao` e `palavras_urgencia`)

**Melhoria de mensagem (pedido junto):** os 2 gatilhos acima agora usam o `pushName` (nome do WhatsApp do cliente) em vez de só o número de telefone, e adicionam uma frase de call-to-action no final: "Continue o atendimento de [nome]." Exemplo real testado: *"🔔 Atendimento pronto para você: Joana Teste Verificação — [resumo]. Continue o atendimento de Joana Teste Verificação."*

**Validado:** reenviei os 2 cenários — mensagem normal da Ariane pra um contato (trava automática) → confirmado que NÃO dispara mais nenhuma notificação; cliente novo conversando → confirmado que a notificação dispara com nome + call-to-action corretos.

**Backup:** `AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-06-pre-fix-desconectar-trava-automatica.json` (antes) → `...-pos-fix-desconectar-trava-automatica-validado.json` (depois, estado final, 196 nodes).

---

## 2026-08-06 (tarde) — AtendentIA Multi-Atendimento SaaS (feature: notificação automática de handoff pra atendimento humano)

**Objetivo:** hoje quando a IA passa o atendimento pro humano, o dono do número não recebe alerta ativo — precisa checar o WhatsApp manualmente. Implementada notificação automática, configurável por tenant, via self-message (mesmo número da instância).

**Migração Supabase** (`supabase/migrations/20260806_add_notificacao_handoff_atendimento.sql`) — 4 colunas novas em `clientes_sistema`, todas com default seguro:
- `notificar_atendimento_humano` (bool, default `true`) — liga/desliga notificações padrão (trava automática + cliente pediu humano + falha detectada)
- `notificar_toda_interacao` (bool, default `false`, `true` só pra Ariane) — notifica em toda resposta da IA, não só handoff — modelo "sempre revisão humana", já que ela nunca deixa a IA agendar sozinha (REGRAS ABSOLUTAS — AGENDAMENTO no prompt dela)
- `palavras_urgencia` (text, nullable; Ariane: `"situação urgente"`) — frases checadas na resposta da IA, notificação imediata com prefixo 🚨 independente dos outros flags
- `palavras_falha_atendimento` (text, nullable) — frases indicando que a IA não resolveu, só conta se `notificar_atendimento_humano=true`

Aplicada via workflow n8n temporário (webhook + Postgres, credencial já existente `Postgres account 2`) já que o MCP do Supabase estava indisponível na sessão — criado, disparado uma vez, resultado conferido, deletado.

**Decisão de design — detecção de urgência:** em vez de tentar re-detectar "prisão em flagrante"/"mandado"/etc diretamente no texto do cliente (raso, arriscado), a IA da Ariane já é instruída (seção "CLASSIFICAÇÃO DA URGÊNCIA" do prompt dela) a responder literalmente **"situação urgente"** quando classifica um caso como prioridade máxima — a notificação detecta essa confirmação da própria IA, que já tem o contexto completo. Confirmado num teste real: mensagem sobre prisão em flagrante → IA respondeu citando "situação urgente" → notificação 🚨 disparou corretamente.

**#pausar/#parar explícito NUNCA notifica** (ação deliberada do dono, ele já sabe) — só a trava automática (`trava_conversas_iniciadas_pelo_owner`, efeito colateral de mensagem normal) notifica. Adicionado campo `_motivo_lock` (`comando_explicito` | `trava_automatica`) em `Decisor Central` pra fazer essa distinção, que antes não existia (os dois casos geravam o mesmo `_acao: humano_falou`).

**Nodes novos:** `Notificar Trava Automatica?` (IF) + `Montar Notificacao Trava Automatica` + `Avisar Handoff Trava Automatica` (branch da trava automática, pendurado em `Supabase - Ativar Trava` que antes era um beco sem saída) · `Montar Notificacao Pediu Humano` (novo branch paralelo de `Pediu Humano?`) · `Avaliar Notificacao Pos Resposta` + `Montar Notificacao Pos Resposta` (branch novo pendurado em `Atendente`, decide urgente/falha/toda_interacao). **Node generalizado:** `Avisar Jean` — antes só mandava um texto fixo de "pediu atendimento humano", agora recebe `texto_notificacao` pronto de qualquer uma das 3 origens acima e serve qualquer tenant/motivo.

### 2 bugs pegos e corrigidos durante o teste ao vivo

1. **Hang do Task Runner (300s timeout)** em `Montar Notificacao Pediu Humano` — usava `$('Mensagem').item.json`, o mesmo padrão de acessor `.item` com pairedItem ambíguo que já tinha causado o hotfix de 16/07 (trava o runner em vez de lançar erro capturável). Trocado por `$('Filtro + Extrair').first().json` (roda uma única vez, sem ambiguidade — mesmo padrão já usado em `detectarTipo()` e `Compara`). Não causou dano colateral desta vez (pouco tráfego concorrente no momento), mas é a mesma classe de bug que já derrubou execuções de outros tenants antes — `CLAUDE.md` já tinha o aviso, só não bati o olho a tempo.

2. **`evo_api_url`/`evo_api_key` NULL no banco** — `clientes_sistema.evo_api_url`/`evo_api_key` vêm nulos pra pelo menos a Ariane; a API global (`evo.upviaagentes.com` + chave global do `CLAUDE.md`) sempre foi o fallback de fato usado em produção via `Montar Contexto Dinamico` (`txt(negocio.evo_api_url) || 'https://...'`), só que a query nova (`Carregar Flag Trava Owner`) não tinha esse fallback. **Isso chegou a afetar 3 interações reais** de um cliente real da Ariane (`555384514026`) entre o deploy e a correção — a trava automática funcionou normal (não foi afetada), só a notificação nova falhou silenciosamente nessas 3 vezes. Corrigido com o mesmo fallback.

### Validação final (5 cenários, produção real)
- Ariane, mensagem urgente (prisão em flagrante) → 🚨 URGENTE, IA citou "situação urgente" corretamente. ✅
- Ariane, mensagem normal → 🔔 toda_interacao. ✅
- Studio Andrade, cliente pede humano ("quero falar com atendente") → 🔔 gatilho generalizado funcionando em outro tenant. ✅
- Ariane, `#pausar` → confirmado que NÃO notifica. ✅
- Ariane, mensagem normal dela pra um contato → trava automática notifica corretamente. ✅

**Backup:** `AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-06-pre-fix-notificacao-handoff.json` (antes) → `...-pre-fix-pediu-humano-hang.json` → `...-pre-fix-evo-api-fallback.json` → `...-pos-fix-notificacao-handoff-validado.json` (estado final, 196 nodes).
**Pendente:** nada bloqueante. `palavras_falha_atendimento` fica vazio até algum tenant configurar suas próprias frases (feature opt-in, sem uso ainda).

---

## 2026-08-06 (manhã) — AtendentIA Multi-Atendimento SaaS (race condition no buffer — rajada de mensagens gerava respostas fragmentadas/duplicadas)

**Problema:** cliente da tenant `ariane-d-avila-afonso-advocaci` (Mayara Vargas) mandou 16 mensagens em rajada (7,8s) — a IA respondeu 15 vezes, cada resposta interpretando um pedaço diferente e incompleto da conversa, sem nunca consolidar numa resposta única nem avançar a coleta de dados.

**Causa raiz (confirmada com dados reais de execução, não só análise estática):** o mecanismo de buffer/debounce (`Buscar Buffer Atual` → `Montar Buffer Atualizado` → `Incluir Mensagem`) fazia GET+modifica+SET no Redis sem nenhuma trava. Com 16 execuções concorrentes fazendo isso ao mesmo tempo, cada escrita sobrescrevia a anterior (lost update) — e o único mecanismo de desempate (`Compara`: "sou a mensagem mais recente?") era uma comparação otimista sobre um valor (`buffer.latest`) escrito da mesma forma insegura. Resultado real medido: das 15 execuções concorrentes, **15 (100%) se consideraram "a mais recente"** e todas enviaram resposta. Falha pré-existente desde a reescrita do buffer de 15/07 — sem relação com o fix de lock `humano_assumiu` de 04/08 (que roda depois de `Compara`, upstream de onde a corrida acontece).

**Correção aplicada (aprovada pelo usuário):** reescrita do mecanismo de acúmulo/consolidação usando primitivas atômicas do Redis:
1. `Redis - Empilhar Mensagem` (RPUSH) substitui o GET+modifica+SET — cada execução empilha só a própria mensagem, impossível perder mensagem por sobrescrita concorrente.
2. `Redis - Incrementar Lock Rajada` (INCR atômico, TTL 20s) — exatamente UMA execução por rajada recebe o valor 1 (garantido pelo Redis mesmo sob concorrência) e vira a responsável por esperar o debounce e consolidar; todas as outras só empilham e param (`Sou o Primeiro da Rajada?`).
3. Como só a vencedora do lock chega em `Compara` agora, a checagem antiga de "sou a mais recente" deixou de ser necessária.
4. Drenagem do buffer via `Redis - Contar Buffer` (LLEN) + loop (`Loop Drenar Buffer`/`Redis - Pop Mensagem`, FIFO) — o Redis nativo do n8n não tem LRANGE, então a leitura completa da lista precisa de um loop.
5. Checagem de "5+ fotos, perguntar se são todas" preservada, mas desacoplada do conteúdo do buffer — agora usa um contador atômico (`Redis - Incrementar Contador Fotos`) verificado ANTES de drenar, evitando ter que drenar-e-restaurar destrutivamente.
6. `Compara`, `Marcar Pergunta Feita` e `Apaga Mensagens` mantiveram os nomes (evita quebrar referências de `Restaurar Dados Pos Recheck` e Rotear Decisao Buffer) mas foram reescritos por dentro.

**3 bugs pegos e corrigidos durante o teste ao vivo, antes de declarar concluído** (nenhum chegou a afetar cliente real — todos os testes usaram números fake `550000008880x`):
1. `Loop Drenar Buffer` (SplitInBatches) com os outputs invertidos — o output "loop" de verdade é o índice 1, não o 0 como a documentação interna (`CLAUDE.md`) registrava. Confirmado empiricamente rodando a rajada de teste (a primeira tentativa quebrou com `Cannot assign to read only property 'name' of object 'Error: Node 'Redis - Pop Mensagem' hasn't been executed'` — o mesmo tipo de erro fatal do hotfix de 16/07, mas dessa vez capturado em teste, não em produção). `CLAUDE.md` e `SKILL_AUDITOR_N8N.md` devem ser corrigidos para refletir isso.
2. Consequência do bug 1: nenhuma resposta saía (pior que o bug original). Corrigido invertendo os dois outputs.
3. `Compara` usava `$('Redis - Pop Mensagem').all()` pra juntar as mensagens drenadas — isso só retorna a ÚLTIMA rodada do node dentro do loop, não todas. A forma correta é `$input.all()` (a entrada direta do node, que o branch "done" do SplitInBatches já agrega corretamente). Sem essa correção, só a última mensagem da rajada aparecia na resposta consolidada.

**Validação final (3 testes ao vivo, produção real, apos as 3 correções):**
- Rajada de 12 mensagens rápidas → **exatamente 1 resposta enviada**, consolidando as 12 mensagens em ordem no texto final. ✅
- Mensagem única, sem rajada → 1 resposta normal e coerente, sem regressão. ✅
- Rajada + `#pausar` no meio do debounce (mesmo teste do fix de 04/08) → segue bloqueando corretamente, os dois mecanismos funcionam em conjunto. ✅

**Não testado:** o fluxo de confirmação de 5+ fotos ("são todas as fotos?") não foi exercitado ao vivo nesta rodada — a lógica foi revisada mas não simulada com mensagens de imagem reais.

**Aplicação:** `PATCH` nem tentado desta vez (já sabido que a API recusa). `PUT` direto, com round-trip de segurança e backups antes/depois de cada uma das 4 aplicações (fix principal + 2 correções de bug + estado final).
**Backup:** `AtendentIA-Multi-Atendimento-SaaS-backup-2026-08-06-pre-fix-buffer-race-rajada.json` (antes de tudo) → `...-pre-fix-loop-drenar-indices.json` → `...-pre-fix-compara-input-all.json` → `...-pos-fix-buffer-race-rajada-validado.json` (estado final, 190 nodes).
**Pendente:** limpar as linhas de teste (`dados_cliente`/`trava_atendimento_humano`, telefones `550000008880x`) do Supabase — não foi possível nesta sessão porque a ferramenta de acesso ao Supabase desconectou no meio da tarefa. Baixo risco (números obviamente fake, e as chaves Redis usadas já expiraram sozinhas pelo TTL).

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
