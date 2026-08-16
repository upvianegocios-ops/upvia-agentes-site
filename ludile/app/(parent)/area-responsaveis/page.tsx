import { redirect } from 'next/navigation';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/server';
import { isGuardianVerified } from '../guardian';
import { getChildrenForUser, getChildSkillProgress, getChildAttemptsSummary } from '@/lib/data/queries';
import { PinGate } from './PinGate';
import { GameCard } from '@/components/ui/GameCard';

export default async function AreaResponsaveisPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const children = await getChildrenForUser(user.id);
  const organizationId = children[0]?.organizationId;

  if (!organizationId) {
    return (
      <main className="min-h-screen flex items-center justify-center p-6 text-center">
        <p>Cadastre o primeiro personagem antes de acessar a área dos responsáveis.</p>
      </main>
    );
  }

  if (!isGuardianVerified()) {
    return <PinGate organizationId={organizationId} />;
  }

  const dashboards = await Promise.all(
    children.map(async (child) => ({
      child,
      skills: await getChildSkillProgress(child.id),
      summary: await getChildAttemptsSummary(child.id),
    }))
  );

  return (
    <main className="min-h-screen p-6 flex flex-col gap-6 max-w-2xl mx-auto">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-extrabold text-ludile-primary">Área dos responsáveis</h1>
        <Link href="/mapa" className="text-ludile-primary underline font-bold">
          Voltar ao jogo
        </Link>
      </div>

      {dashboards.map(({ child, skills, summary }) => (
        <GameCard key={child.id} className="flex flex-col gap-3">
          <h2 className="text-xl font-extrabold">{child.nickname}</h2>
          <div className="flex gap-6 text-sm text-slate-600">
            <span>{summary.totalAttempts} atividades realizadas</span>
            <span>{summary.accuracyRate}% de acerto</span>
            <span>{summary.averageHints} pistas em média por atividade</span>
          </div>
          {skills.length > 0 ? (
            <ul className="flex flex-col gap-2">
              {skills.map((s) => (
                <li key={s.skillCode} className="flex justify-between text-sm">
                  <span>{s.skillName}</span>
                  <span className="font-bold">{s.masteryLevel}%</span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-slate-400">Ainda sem atividades registradas.</p>
          )}
          <p className="text-xs text-slate-400">
            Observação: relatórios descrevem desempenho em habilidades específicas, nunca um
            diagnóstico. Para avaliação clínica, procure um profissional especializado.
          </p>
        </GameCard>
      ))}
    </main>
  );
}
