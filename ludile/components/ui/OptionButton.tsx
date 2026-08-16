'use client';

interface OptionButtonProps {
  label: string;
  icon?: string;
  selected?: boolean;
  status?: 'idle' | 'correct' | 'incorrect';
  onClick: () => void;
  disabled?: boolean;
}

// Nunca usa só cor para indicar certo/errado — sempre ícone + texto (seção 6).
export function OptionButton({ label, icon, selected, status = 'idle', onClick, disabled }: OptionButtonProps) {
  const statusStyles =
    status === 'correct'
      ? 'border-ludile-success bg-green-50'
      : status === 'incorrect'
        ? 'border-ludile-error bg-red-50'
        : selected
          ? 'border-ludile-primary bg-purple-50'
          : 'border-slate-200 bg-white';

  const statusIcon = status === 'correct' ? '✅' : status === 'incorrect' ? '❌' : null;

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={`min-h-[72px] w-full rounded-xl2 border-4 px-4 py-3 text-child-lg font-bold
        flex items-center justify-center gap-2 transition-colors active:scale-95
        disabled:opacity-60 ${statusStyles}`}
    >
      {icon && <span aria-hidden="true">{icon}</span>}
      <span>{label}</span>
      {statusIcon && <span aria-hidden="true">{statusIcon}</span>}
    </button>
  );
}
