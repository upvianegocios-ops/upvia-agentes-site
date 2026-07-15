# Changelog

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
