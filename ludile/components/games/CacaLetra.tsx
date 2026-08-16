'use client';

import { useMemo, useState } from 'react';
import { QuestionCard } from '../ui/QuestionCard';
import type { GameProps } from '@/lib/game-engine/game-props';

// Jogo 1 do MVP: "Encontre a letra X" numa grade — seção 22, item 1.
export function CacaLetra({ activity, onComplete }: GameProps) {
  const startedAt = useMemo(() => Date.now(), []);
  const letters = activity.options as string[];
  const targetPositions = (activity.correctAnswer as { positions: number[] }).positions;

  const [found, setFound] = useState<Set<number>>(new Set());
  const [wrongClicks, setWrongClicks] = useState(0);
  const [hintsUsed, setHintsUsed] = useState(0);
  const [hintPosition, setHintPosition] = useState<number | null>(null);

  const allFound = found.size === targetPositions.length;

  function handleClick(index: number) {
    if (allFound || found.has(index)) return;

    if (targetPositions.includes(index)) {
      const next = new Set(found);
      next.add(index);
      setFound(next);
      setHintPosition(null);

      if (next.size === targetPositions.length) {
        onComplete({
          isCorrect: wrongClicks === 0,
          hintsUsed,
          timeSpentMs: Date.now() - startedAt,
        });
      }
    } else {
      setWrongClicks((w) => w + 1);
    }
  }

  function handleHelp() {
    const remaining = targetPositions.find((p) => !found.has(p));
    if (remaining !== undefined) {
      setHintsUsed((h) => h + 1);
      setHintPosition(remaining);
    }
  }

  return (
    <QuestionCard
      instruction={activity.instruction}
      audioUrl={activity.audioUrl}
      onHelp={handleHelp}
    >
      <div className="grid grid-cols-3 gap-3">
        {letters.map((letter, index) => {
          const isFound = found.has(index);
          const isHinted = hintPosition === index;
          return (
            <button
              key={index}
              type="button"
              onClick={() => handleClick(index)}
              disabled={isFound}
              aria-label={`Letra ${letter}`}
              className={`min-h-[72px] rounded-xl2 border-4 text-3xl font-extrabold
                active:scale-95 transition-transform disabled:opacity-70
                ${isFound ? 'border-ludile-success bg-green-50' : isHinted ? 'border-ludile-secondary bg-yellow-50' : 'border-slate-200 bg-white'}`}
            >
              {letter}
              {isFound && (
                <span aria-hidden="true" className="ml-1">
                  ✅
                </span>
              )}
            </button>
          );
        })}
      </div>
      <p className="text-center text-sm text-slate-500 mt-2">
        Encontradas: {found.size} de {targetPositions.length}
      </p>
    </QuestionCard>
  );
}
