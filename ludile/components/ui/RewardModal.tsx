'use client';

import { GameButton } from './GameButton';

interface RewardModalProps {
  open: boolean;
  stars: 1 | 2 | 3;
  xpEarned: number;
  coinsEarned: number;
  onContinue: () => void;
}

export function RewardModal({ open, stars, xpEarned, coinsEarned, onContinue }: RewardModalProps) {
  if (!open) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Recompensa da missão"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    >
      <div className="bg-white rounded-xl2 shadow-xl p-8 text-center max-w-sm w-full">
        <p className="text-5xl mb-2" aria-hidden="true">
          🎉
        </p>
        <h2 className="text-child-lg font-extrabold text-ludile-primary mb-2">Muito bem!</h2>
        <p aria-label={`${stars} de 3 estrelas`} className="text-3xl mb-4">
          {'⭐'.repeat(stars)}
          {'☆'.repeat(3 - stars)}
        </p>
        <div className="flex justify-center gap-6 mb-6 text-child-base font-bold text-slate-700">
          <span>✨ +{xpEarned} XP</span>
          <span>🪙 +{coinsEarned}</span>
        </div>
        <GameButton onClick={onContinue} variant="success">
          Continuar
        </GameButton>
      </div>
    </div>
  );
}
