import { GameCard } from './GameCard';
import { GameButton } from './GameButton';

interface MissionCardProps {
  name: string;
  description: string;
  onStart: () => void;
}

export function MissionCard({ name, description, onStart }: MissionCardProps) {
  return (
    <GameCard className="flex flex-col items-center text-center gap-4 max-w-sm mx-auto">
      <h2 className="text-child-lg font-extrabold text-ludile-primary">{name}</h2>
      <p className="text-child-base text-slate-600">{description}</p>
      <GameButton onClick={onStart} icon={<span aria-hidden="true">▶️</span>}>
        Começar missão
      </GameButton>
    </GameCard>
  );
}
