'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { checkOrSetPin } from '../actions';
import { GameButton } from '@/components/ui/GameButton';
import { GameCard } from '@/components/ui/GameCard';

export function PinGate({ organizationId }: { organizationId: string }) {
  const router = useRouter();
  const [pin, setPin] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    const result = await checkOrSetPin(organizationId, pin);
    setLoading(false);
    if (!result.ok) {
      setError(result.error ?? 'PIN incorreto.');
      return;
    }
    router.refresh();
  }

  return (
    <main className="min-h-screen flex items-center justify-center p-6">
      <GameCard className="max-w-xs w-full flex flex-col gap-4 text-center">
        <p className="text-4xl" aria-hidden="true">
          🔒
        </p>
        <h1 className="text-xl font-extrabold text-ludile-primary">Área dos responsáveis</h1>
        <p className="text-sm text-slate-500">
          Digite o PIN de 4 a 6 números. Se é a primeira vez, o número digitado será cadastrado
          como seu PIN.
        </p>
        <form onSubmit={handleSubmit} className="flex flex-col gap-3">
          <input
            type="password"
            inputMode="numeric"
            pattern="[0-9]*"
            maxLength={6}
            value={pin}
            onChange={(e) => setPin(e.target.value)}
            className="min-h-[56px] rounded-xl border-2 border-slate-300 px-4 text-center text-2xl tracking-widest"
            aria-label="PIN"
          />
          {error && <p className="text-ludile-error text-sm font-semibold">{error}</p>}
          <GameButton disabled={loading} type="submit">
            {loading ? 'Verificando...' : 'Entrar'}
          </GameButton>
        </form>
      </GameCard>
    </main>
  );
}
