'use client';

import { type ButtonHTMLAttributes, type ReactNode } from 'react';

interface GameButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode;
  variant?: 'primary' | 'secondary' | 'success' | 'ghost';
  icon?: ReactNode;
}

const VARIANT_CLASSES: Record<NonNullable<GameButtonProps['variant']>, string> = {
  primary: 'bg-ludile-primary text-white',
  secondary: 'bg-ludile-secondary text-slate-900',
  success: 'bg-ludile-success text-white',
  ghost: 'bg-white text-ludile-primary border-2 border-ludile-primary',
};

// Botão grande, com área de toque ampla (seção 5/16) — nunca depende de hover.
export function GameButton({
  children,
  variant = 'primary',
  icon,
  className = '',
  ...props
}: GameButtonProps) {
  return (
    <button
      type="button"
      className={`min-h-[64px] min-w-[64px] rounded-xl2 px-6 py-3 text-child-base font-bold
        shadow-md active:scale-95 transition-transform
        disabled:opacity-50 disabled:pointer-events-none
        flex items-center justify-center gap-3
        ${VARIANT_CLASSES[variant]} ${className}`}
      {...props}
    >
      {icon}
      {children}
    </button>
  );
}
