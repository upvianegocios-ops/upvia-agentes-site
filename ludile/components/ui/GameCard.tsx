import type { ReactNode } from 'react';

export function GameCard({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`bg-white rounded-xl2 shadow-lg p-6 ${className}`}>{children}</div>
  );
}
