import type { ReactNode } from 'react';
import { AudioButton } from './AudioButton';
import { GameCard } from './GameCard';

interface QuestionCardProps {
  instruction: string;
  audioUrl?: string | null;
  onHelp?: () => void;
  children: ReactNode;
}

// Navegação sempre visível: 🏠 voltar · 🔊 ouvir novamente · ❓ ajuda (seção 23).
export function QuestionCard({ instruction, audioUrl, onHelp, children }: QuestionCardProps) {
  return (
    <GameCard className="max-w-lg mx-auto flex flex-col gap-6">
      <div className="flex items-center justify-between gap-3">
        <p className="text-child-lg font-bold text-slate-800 flex-1">{instruction}</p>
        <AudioButton audioUrl={audioUrl} text={instruction} />
      </div>
      {children}
      {onHelp && (
        <button
          type="button"
          onClick={onHelp}
          className="self-center text-ludile-primary font-bold underline text-child-base"
        >
          ❓ Preciso de ajuda
        </button>
      )}
    </GameCard>
  );
}
