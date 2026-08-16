import { redirect } from 'next/navigation';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/server';
import { getChildrenForUser } from '@/lib/data/queries';
import { setActiveChild } from '@/lib/session-actions';
import { GameButton } from '@/components/ui/GameButton';

export default async function QuemVaiJogarPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const children = await getChildrenForUser(user.id);

  async function selecionar(formData: FormData) {
    'use server';
    const childId = formData.get('childId') as string;
    await setActiveChild(childId);
    redirect('/mapa');
  }

  return (
    <main className="min-h-screen flex flex-col items-center gap-8 p-6">
      <h1 className="text-3xl font-extrabold text-ludile-primary text-center">Quem vai jogar?</h1>
      <div className="grid grid-cols-2 gap-4 w-full max-w-sm">
        {children.map((child) => (
          <form key={child.id} action={selecionar}>
            <input type="hidden" name="childId" value={child.id} />
            <button
              type="submit"
              className="min-h-[120px] w-full rounded-xl2 border-4 border-ludile-primary bg-white
                flex flex-col items-center justify-center gap-2 active:scale-95 transition-transform"
            >
              <span className="text-4xl" aria-hidden="true">
                🦊
              </span>
              <span className="text-child-base font-bold">{child.nickname}</span>
            </button>
          </form>
        ))}
      </div>
      <Link href="/personagem/novo">
        <GameButton variant="secondary">+ Criar novo personagem</GameButton>
      </Link>
    </main>
  );
}
