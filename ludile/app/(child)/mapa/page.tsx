import { redirect } from 'next/navigation';
import Link from 'next/link';
import { getActiveChildId } from '@/lib/session';
import { getMissionsForWorld, getMissionProgressForChild } from '@/lib/data/queries';
import { MapNode } from '@/components/ui/MapNode';

export default async function MapaPage() {
  const childId = getActiveChildId();
  if (!childId) redirect('/quem-vai-jogar');

  const missions = await getMissionsForWorld('vila_das_letras');
  const progress = await getMissionProgressForChild(childId);
  const progressByMission = new Map(progress.map((p) => [p.missionId, p]));

  return (
    <main className="min-h-screen p-6 flex flex-col items-center gap-8">
      <header className="text-center">
        <p className="text-5xl" aria-hidden="true">
          🏘️
        </p>
        <h1 className="text-3xl font-extrabold text-ludile-primary">Vila das Letras</h1>
      </header>

      <div className="grid grid-cols-3 sm:grid-cols-5 gap-6 max-w-2xl">
        {missions.map((mission, index) => {
          const prog = progressByMission.get(mission.id);
          const previousMission = missions[index - 1];
          const previousProg = previousMission ? progressByMission.get(previousMission.id) : undefined;
          const isUnlocked = index === 0 || previousProg?.status === 'completed';
          const status = prog?.status ?? (isUnlocked ? 'available' : 'locked');

          return (
            <Link key={mission.id} href={status === 'locked' ? '#' : `/missao/${mission.id}`}>
              <MapNode
                name={mission.name}
                icon="🔤"
                status={status}
                stars={prog?.starsEarned ?? 0}
              />
            </Link>
          );
        })}
      </div>
    </main>
  );
}
