'use client';

import { useMemo, useState } from 'react';
import { QuestionCard } from '../ui/QuestionCard';
import { OptionButton } from '../ui/OptionButton';
import { speak } from '@/lib/audio/speech';
import type { GameProps } from '@/lib/game-engine/game-props';

// Jogo 3 do MVP: "Qual é o som?" — ouvir e escolher a letra (seção 22, item 3).
export function QualEOSom({ activity, onComplete }: GameProps) {
  const startedAt = useMemo(() => Date.now(), []);
  const options = activity.options as string[];
  const correctAnswer = (activity.correctAnswer as { answer: string }).answer;
  const soundText = (activity.question as { sound?: string }).sound ?? correctAnswer;

  const [selected, setSelected] = useState<string | null>(null);
  const [status, setStatus] = useState<'idle' | 'correct' | 'incorrect'>('idle');
  const [hintsUsed, setHintsUsed] = useState(0);
  const [attempts, setAttempts] = useState(0);

  function handleSelect(option: string) {
    if (status === 'correct') return;
    setSelected(option);
    setAttempts((a) => a + 1);

    if (option === correctAnswer) {
      setStatus('correct');
      onComplete({
        isCorrect: attempts === 0,
        hintsUsed,
        timeSpentMs: Date.now() - startedAt,
      });
    } else {
      setStatus('incorrect');
      window.setTimeout(() => setStatus('idle'), 600);
    }
  }

  function handleHelp() {
    setHintsUsed((h) => h + 1);
    speak(activity.hint ?? `Preste atenção no som: ${soundText}`);
  }

  return (
    <QuestionCard instruction={activity.instruction} onHelp={handleHelp}>
      <div className="flex justify-center mb-2">
        <button
          type="button"
          onClick={() => speak(soundText, { rate: 0.8 })}
          className="min-h-[64px] min-w-[64px] rounded-full bg-ludile-primary text-white text-3xl
            shadow-md active:scale-95 transition-transform"
          aria-label="Tocar o som"
        >
          🔊
        </button>
      </div>
      <div className="grid grid-cols-3 gap-3">
        {options.map((option) => (
          <OptionButton
            key={option}
            label={option}
            onClick={() => handleSelect(option)}
            selected={selected === option}
            status={selected === option ? status : 'idle'}
          />
        ))}
      </div>
    </QuestionCard>
  );
}
