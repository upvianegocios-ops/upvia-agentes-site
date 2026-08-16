'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { AvatarSelector } from '@/components/ui/AvatarSelector';
import { GameButton } from '@/components/ui/GameButton';
import { GameCard } from '@/components/ui/GameCard';
import { createChildProfile } from '../../game-actions';
import { setActiveChild } from '@/lib/session-actions';
import { createClient } from '@/lib/supabase/client';

export default function NovoPersonagemPage() {
  const router = useRouter();
  const [nickname, setNickname] = useState('');
  const [avatarId, setAvatarId] = useState('raposa');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleCreate() {
    if (!nickname.trim()) {
      setError('Escolha um apelido para o personagem.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        router.push('/login');
        return;
      }

      const { data: membership } = await supabase
        .from('org_members')
        .select('organization_id')
        .eq('user_id', user.id)
        .eq('role', 'parent')
        .limit(1)
        .single();

      if (!membership) {
        setError('Não encontramos a organização da família. Fale com o suporte.');
        return;
      }

      const childId = await createChildProfile({
        organizationId: membership.organization_id,
        parentUserId: user.id,
        nickname: nickname.trim(),
        avatarId,
      });
      await setActiveChild(childId);
      router.push('/mapa');
    } catch {
      setError('Não foi possível criar o personagem agora. Tente novamente.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen flex flex-col items-center justify-center gap-6 p-6">
      <GameCard className="max-w-sm w-full flex flex-col gap-5">
        <h1 className="text-2xl font-extrabold text-ludile-primary text-center">
          Vamos criar seu personagem!
        </h1>
        <AvatarSelector value={avatarId} onChange={setAvatarId} />
        <label className="flex flex-col gap-1">
          <span className="font-bold text-slate-700">Como você quer ser chamado?</span>
          <input
            value={nickname}
            onChange={(e) => setNickname(e.target.value)}
            maxLength={20}
            className="min-h-[56px] rounded-xl border-2 border-slate-300 px-4 text-child-base"
            placeholder="Apelido"
          />
        </label>
        {error && <p className="text-ludile-error text-sm font-semibold">{error}</p>}
        <GameButton onClick={handleCreate} disabled={loading}>
          {loading ? 'Criando...' : 'Começar a aventura!'}
        </GameButton>
      </GameCard>
    </main>
  );
}
