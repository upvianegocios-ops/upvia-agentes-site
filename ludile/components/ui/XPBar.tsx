import { ProgressBar } from './ProgressBar';

interface XPBarProps {
  xp: number;
  xpForNextLevel: number;
  level: number;
}

export function XPBar({ xp, xpForNextLevel, level }: XPBarProps) {
  const pct = xpForNextLevel > 0 ? (xp / xpForNextLevel) * 100 : 0;
  return (
    <div className="flex items-center gap-3">
      <div
        className="h-10 w-10 rounded-full bg-ludile-secondary text-slate-900 font-extrabold
          flex items-center justify-center shrink-0"
        aria-hidden="true"
      >
        {level}
      </div>
      <div className="flex-1">
        <ProgressBar value={pct} label={`Nível ${level} · ${xp}/${xpForNextLevel} XP`} />
      </div>
    </div>
  );
}
