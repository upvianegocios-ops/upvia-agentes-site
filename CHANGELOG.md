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
