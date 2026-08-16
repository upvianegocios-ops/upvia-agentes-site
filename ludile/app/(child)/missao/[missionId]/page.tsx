import { redirect } from 'next/navigation';
import { getActiveChildId } from '@/lib/session';
import { getActivitiesForMission } from '@/lib/data/queries';
import { createClient } from '@/lib/supabase/server';
import { MissionPlayer } from './MissionPlayer';

export default async function MissaoPage({ params }: { params: { missionId: string } }) {
  const childId = getActiveChildId();
  if (!childId) redirect('/quem-vai-jogar');

  const supabase = createClient();
  const { data: child } = await supabase
    .from('child_profiles')
    .select('organization_id')
    .eq('id', childId)
    .single();

  if (!child) redirect('/quem-vai-jogar');

  const activities = await getActivitiesForMission(params.missionId);

  if (activities.length === 0) {
    return (
      <main className="min-h-screen flex items-center justify-center p-6 text-center">
        <p className="text-child-base">Esta missão ainda não tem atividades cadastradas.</p>
      </main>
    );
  }

  return (
    <MissionPlayer
      missionId={params.missionId}
      organizationId={child.organization_id}
      childId={childId}
      activities={activities}
    />
  );
}
