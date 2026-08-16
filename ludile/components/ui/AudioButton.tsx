'use client';

import { useState } from 'react';
import { playInstruction } from '@/lib/audio/speech';

interface AudioButtonProps {
  audioUrl?: string | null;
  text: string;
  label?: string;
}

// "Ouvir novamente" — presente em toda tela com áudio (seção 6).
export function AudioButton({ audioUrl = null, text, label = 'Ouvir novamente' }: AudioButtonProps) {
  const [playing, setPlaying] = useState(false);

  const handleClick = () => {
    setPlaying(true);
    playInstruction(audioUrl, text);
    window.setTimeout(() => setPlaying(false), 1200);
  };

  return (
    <button
      type="button"
      onClick={handleClick}
      aria-label={label}
      className="min-h-[56px] min-w-[56px] rounded-full bg-white shadow-md flex items-center
        justify-center text-2xl border-2 border-ludile-primary active:scale-95 transition-transform"
    >
      <span aria-hidden="true">{playing ? '🔊' : '🔈'}</span>
    </button>
  );
}
