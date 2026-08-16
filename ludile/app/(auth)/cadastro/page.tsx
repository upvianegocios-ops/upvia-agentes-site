'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { GameButton } from '@/components/ui/GameButton';
import { GameCard } from '@/components/ui/GameCard';

export default function CadastroPage() {
  const router = useRouter();
  const [familyName, setFamilyName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const supabase = createClient();

    // Consentimento do responsável + minimização de dados (seção 14):
    // só coletamos e-mail/senha do responsável e o nome da família.
    const { error: signUpError } = await supabase.auth.signUp({ email, password });
    if (signUpError) {
      setError('Não foi possível criar a conta. Verifique os dados e tente novamente.');
      setLoading(false);
      return;
    }

    const { error: rpcError } = await supabase.rpc('create_family_organization', {
      family_name: familyName,
    });
    setLoading(false);
    if (rpcError) {
      setError('Conta criada, mas houve um problema ao configurar a família. Fale com o suporte.');
      return;
    }

    router.push('/personagem/novo');
  }

  return (
    <main className="min-h-screen flex items-center justify-center p-6">
      <GameCard className="max-w-sm w-full flex flex-col gap-4">
        <h1 className="text-2xl font-extrabold text-ludile-primary text-center">
          Criar conta da família
        </h1>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <label className="flex flex-col gap-1">
            <span className="font-bold text-slate-700">Nome da família</span>
            <input
              required
              value={familyName}
              onChange={(e) => setFamilyName(e.target.value)}
              className="min-h-[56px] rounded-xl border-2 border-slate-300 px-4"
              placeholder="Ex: Família Silva"
            />
          </label>
          <label className="flex flex-col gap-1">
            <span className="font-bold text-slate-700">Seu e-mail</span>
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
              minLength={8}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="min-h-[56px] rounded-xl border-2 border-slate-300 px-4"
            />
          </label>
          <p className="text-xs text-slate-500">
            Ao continuar, você concorda com a nossa Política de Privacidade e confirma que é
            responsável legal pela(s) criança(s) cadastrada(s).
          </p>
          {error && <p className="text-ludile-error text-sm font-semibold">{error}</p>}
          <GameButton disabled={loading} type="submit">
            {loading ? 'Criando...' : 'Criar conta'}
          </GameButton>
        </form>
      </GameCard>
    </main>
  );
}
