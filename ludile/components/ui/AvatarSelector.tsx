'use client';

const AVATARS = [
  { id: 'raposa', label: 'Raposa', icon: '🦊' },
  { id: 'coruja', label: 'Coruja', icon: '🦉' },
  { id: 'gato', label: 'Gato', icon: '🐱' },
  { id: 'dino', label: 'Dinossauro', icon: '🦕' },
];

interface AvatarSelectorProps {
  value: string;
  onChange: (avatarId: string) => void;
}

export function AvatarSelector({ value, onChange }: AvatarSelectorProps) {
  return (
    <div role="radiogroup" aria-label="Escolha seu personagem" className="grid grid-cols-2 gap-4">
      {AVATARS.map((avatar) => (
        <button
          key={avatar.id}
          type="button"
          role="radio"
          aria-checked={value === avatar.id}
          onClick={() => onChange(avatar.id)}
          className={`min-h-[100px] rounded-xl2 border-4 flex flex-col items-center justify-center gap-1
            active:scale-95 transition-transform
            ${value === avatar.id ? 'border-ludile-primary bg-purple-50' : 'border-slate-200 bg-white'}`}
        >
          <span className="text-4xl" aria-hidden="true">
            {avatar.icon}
          </span>
          <span className="text-child-base font-bold">{avatar.label}</span>
        </button>
      ))}
    </div>
  );
}
