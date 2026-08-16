# Game Design — Ludilê (MVP: Mundo 1, Vila das Letras)

## Escopo do MVP (seção 21)

10 letras (A, E, I, O, U, M, P, T, B, L) · 20 atividades · 3 tipos de jogo ·
1 mundo · mapa com progresso · XP/estrelas/moedas · área dos responsáveis ·
autenticação · painel administrativo básico · PWA · áudio.

## Tipos de jogo implementados

| Tipo | Componente | Habilidade (seção 8) |
|---|---|---|
| Caça-letra | `components/games/CacaLetra.tsx` | Fase 1 — reconhecimento de letras |
| Memória | `components/games/Memoria.tsx` | Fase 1 — reconhecimento de letras |
| Qual é o som? | `components/games/QualEOSom.tsx` | Fase 2 — associação grafema-fonema |

Os outros 5 tipos da seção 22 (`comeca_com`, `monte_a_silaba`,
`monte_a_palavra`, `qual_e_a_palavra`, `leia_e_escolha`) já têm o
`activity_type` reservado no schema e no `ActivityRenderer` — bastam novos
componentes de jogo + conteúdo nas fases seguintes (seções 8 e 22), sem
mudar o motor genérico.

## Motor genérico (seção 23)

`ActivityRenderer` despacha por `activity_type`. Cada atividade é um
registro genérico (`instruction`, `question`, `options`, `correct_answer`,
`hint`, `reward`, `difficulty`) — nenhum jogo tem conteúdo hardcoded fora
do banco, então o painel admin pode criar atividades novas sem deploy.

## Sistema de ajuda progressiva (seção 23)

`lib/game-engine/difficulty.ts#nextHelpLevel`: tentativa 1 → "vamos tentar
de novo", tentativa 2 → pista (`activity.hint`), tentativa 3+ → exemplo.
Nunca revela a resposta sem contexto.

## Recompensas e estrelas (seção 7 e 10)

- XP e moedas por atividade são sempre concedidos ao acertar — nunca
  removidos depois (regra dura da seção 7).
- Estrelas da missão (`lib/game-engine/rewards.ts#computeMissionStars`):
  - 3 estrelas — tudo certo, sem nenhuma pista
  - 2 estrelas — tudo certo, com pista(s)
  - 1 estrela — completou com erro(s) — **nunca 0 estrelas, errar não é
    punido**

## Motor adaptativo (seção 9)

Determinístico e explicável (nunca IA/diagnóstico — seção 9 e 24):

- Acerto sem pista → sobe 1 nível de dificuldade (máx. 5)
- Dois erros seguidos → desce 1 nível (mín. 1)
- Três erros seguidos → sinaliza para mostrar explicação visual/sonora
- Tempo de resposta subindo + acerto caindo na janela recente → sinaliza
  sugestão de pausa ("sinais de cansaço", nunca força a criança a parar)

Testado em `tests/unit/difficulty.test.ts`.

## Acessibilidade aplicada (seção 6)

- Nunca cor sozinha: toda resposta certa/errada tem ícone (`✅`/`❌`) junto
  da cor (`components/ui/OptionButton.tsx`).
- Fonte legível por padrão, com hook para `OpenDyslexic` via
  `body[data-font="dislexia"]` (`app/globals.css`) — a implementação do
  seletor de fonte na UI de configurações fica para a próxima iteração
  (ver `docs/PENDENCIAS.md`).
- Áreas de toque ≥ 64px (`GameButton`, `OptionButton`, `MapNode`).
- Botão "ouvir novamente" (`AudioButton`) em toda tela de atividade.
- `prefers-reduced-motion` respeitado globalmente; `accessibility_settings`
  por criança já existe no schema (`child_profiles.accessibility_settings`)
  para velocidade de animação e modo de concentração.

## Progressão do mapa

Missões (uma por letra) desbloqueiam sequencialmente: a missão N só fica
disponível quando a missão N-1 está `completed`
(`app/(child)/mapa/page.tsx`). Sem exigência de uso diário, sem cronômetro,
sem remoção de progresso por erro (seção 7).
