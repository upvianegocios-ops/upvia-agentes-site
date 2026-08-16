'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/client';
import { GameButton } from '@/components/ui/GameButton';
import { GameCard } from '@/components/ui/GameCard';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const supabase = createClient();
    const { error: signInError } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (signInError) {
      setError('E-mail ou senha incorretos.');
      return;
    }
    router.push('/quem-vai-jogar');
  }

  return (
    <main className="min-h-screen flex items-center justify-center p-6">
      <GameCard className="max-w-sm w-full flex flex-col gap-4">
        <h1 className="text-2xl font-extrabold text-ludile-primary text-center">Entrar</h1>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <label className="flex flex-col gap-1">
            <span className="font-bold text-slate-700">E-mail</span>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="min-h-[56px] rounded-xl border-2 border-slate-300 px-4"
            />
          </label>
          <label className="flex flex-col gap-1">
            <span className="font-bold text-slate-700">Senha</span>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="min-h-[56px] rounded-xl border-2 border-slate-300 px-4"
            />
          </label>
          {error && <p className="text-ludile-error text-sm font-semibold">{error}</p>}
          <GameButton disabled={loading} type="submit">
            {loading ? 'Entrando...' : 'Entrar'}
          </GameButton>
        </form>
        <p className="text-center text-sm text-slate-500">
          Ainda não tem conta?{' '}
          <Link href="/cadastro" className="text-ludile-primary font-bold underline">
            Criar conta da família
          </Link>
        </p>
      </GameCard>
    </main>
  );
}
