interface BadgeProps {
  name: string;
  iconUrl?: string | null;
  earned?: boolean;
}

export function Badge({ name, iconUrl, earned = true }: BadgeProps) {
  return (
    <div
      className={`flex flex-col items-center gap-1 w-24 text-center ${earned ? '' : 'opacity-30 grayscale'}`}
    >
      <div className="h-16 w-16 rounded-full bg-ludile-secondary flex items-center justify-center text-2xl">
        {iconUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={iconUrl} alt="" className="h-10 w-10" aria-hidden="true" />
        ) : (
          <span aria-hidden="true">🏅</span>
        )}
      </div>
      <span className="text-xs font-bold text-slate-700">{name}</span>
    </div>
  );
}
