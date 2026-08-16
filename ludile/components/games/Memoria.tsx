'use client';

import { useMemo, useState } from 'react';
import { QuestionCard } from '../ui/QuestionCard';
import type { GameProps } from '@/lib/game-engine/game-props';

interface Card {
  index: number;
  value: string;
}

function shuffle<T>(items: T[]): T[] {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j] as T, copy[i] as T];
  }
  return copy;
}

// Jogo 2 do MVP: memória de pares — seção 22, item 2.
export function Memoria({ activity, onComplete }: GameProps) {
  const startedAt = useMemo(() => Date.now(), []);
  const values = activity.options as string[];
  const cards = useMemo<Card[]>(
    () => shuffle(values.map((value, index) => ({ index, value }))),
    [values]
  );

  const [flipped, setFlipped] = useState<number[]>([]);
  const [matched, setMatched] = useState<Set<number>>(new Set());
  const [mismatches, setMismatches] = useState(0);
  const [hintsUsed, setHintsUsed] = useState(0);
  const [busy, setBusy] = useState(false);

  const totalPairs = values.length / 2;
  const allMatched = matched.size === values.length;

  function handleFlip(cardIndex: number) {
    if (busy || flipped.includes(cardIndex) || matched.has(cardIndex)) return;

    const nextFlipped = [...flipped, cardIndex];
    setFlipped(nextFlipped);

    if (nextFlipped.length === 2) {
      const [firstIdx, secondIdx] = nextFlipped;
      if (firstIdx === undefined || secondIdx === undefined) return;

      setBusy(true);
      const first = cards.find((c) => c.index === firstIdx)!;
      const second = cards.find((c) => c.index === secondIdx)!;

      window.setTimeout(() => {
        if (first.value === second.value) {
          const nextMatched = new Set(matched);
          nextMatched.add(firstIdx);
          nextMatched.add(secondIdx);
          setMatched(nextMatched);

          if (nextMatched.size === values.length) {
            onComplete({
              isCorrect: mismatches === 0,
              hintsUsed,
              timeSpentMs: Date.now() - startedAt,
            });
          }
        } else {
          setMismatches((m) => m + 1);
        }
        setFlipped([]);
        setBusy(false);
      }, 700);
    }
  }

  function handleHelp() {
    setHintsUsed((h) => h + 1);
  }

  return (
    <QuestionCard instruction={activity.instruction} onHelp={handleHelp}>
      <div className="grid grid-cols-3 gap-3">
        {cards.map((card) => {
          const isRevealed = flipped.includes(card.index) || matched.has(card.index);
          return (
            <button
              key={card.index}
              type="button"
              onClick={() => handleFlip(card.index)}
              disabled={isRevealed || allMatched}
              aria-label={isRevealed ? `Carta ${card.value}` : 'Carta virada para baixo'}
              className={`min-h-[72px] rounded-xl2 border-4 text-3xl font-extrabold
                active:scale-95 transition-transform
                ${matched.has(card.index) ? 'border-ludile-success bg-green-50' : 'border-ludile-primary bg-white'}`}
            >
              {isRevealed ? card.value : '❔'}
            </button>
          );
        })}
      </div>
      <p className="text-center text-sm text-slate-500 mt-2">
        Pares encontrados: {matched.size / 2} de {totalPairs}
      </p>
    </QuestionCard>
  );
}
