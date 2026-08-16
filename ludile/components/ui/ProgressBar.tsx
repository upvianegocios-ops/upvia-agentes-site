interface ProgressBarProps {
  value: number; // 0-100
  label: string; // nunca só cor — sempre acompanhado de um rótulo (seção 6)
}

export function ProgressBar({ value, label }: ProgressBarProps) {
  const clamped = Math.min(100, Math.max(0, value));
  return (
    <div className="w-full">
      <div className="flex justify-between text-sm font-semibold text-slate-600 mb-1">
        <span>{label}</span>
        <span>{Math.round(clamped)}%</span>
      </div>
      <div
        role="progressbar"
        aria-valuenow={clamped}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label={label}
        className="h-4 w-full rounded-full bg-slate-200 overflow-hidden"
      >
        <div
          className="h-full rounded-full bg-ludile-primary transition-all duration-500"
          style={{ width: `${clamped}%` }}
        />
      </div>
    </div>
  );
}
