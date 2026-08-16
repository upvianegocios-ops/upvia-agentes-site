'use client';

interface MapNodeProps {
  name: string;
  icon: string;
  status: 'locked' | 'available' | 'in_progress' | 'completed';
  stars: number; // 0-3
  onClick?: () => void;
}

const STATUS_LABEL: Record<MapNodeProps['status'], string> = {
  locked: 'Bloqueada',
  available: 'Disponível',
  in_progress: 'Em progresso',
  completed: 'Concluída',
};

export function MapNode({ name, icon, status, stars, onClick }: MapNodeProps) {
  const locked = status === 'locked';
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={locked}
      aria-label={`${name} — ${STATUS_LABEL[status]}`}
      className={`flex flex-col items-center gap-1 min-h-[88px] min-w-[88px] rounded-full
        p-4 shadow-md active:scale-95 transition-transform disabled:opacity-40
        ${status === 'completed' ? 'bg-ludile-secondary' : 'bg-white border-4 border-ludile-primary'}`}
    >
      <span className="text-3xl" aria-hidden="true">
        {locked ? '🔒' : icon}
      </span>
      <span className="text-xs font-bold text-slate-700">{name}</span>
      {!locked && (
        <span aria-hidden="true" className="text-sm">
          {'⭐'.repeat(stars)}
          {'☆'.repeat(3 - stars)}
        </span>
      )}
    </button>
  );
}
