import { notFound } from 'next/navigation';
import { getActivityForAdmin, listMissionsForSelect } from '@/lib/data/admin-queries';
import { EditActivityForm } from './EditActivityForm';

export default async function EditarAtividadePage({ params }: { params: { id: string } }) {
  const [activity, missions] = await Promise.all([
    getActivityForAdmin(params.id),
    listMissionsForSelect(),
  ]);

  if (!activity) notFound();

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-extrabold">Editar atividade</h1>
      <EditActivityForm
        activityId={activity.id}
        missions={missions}
        defaults={{
          missionId: activity.missionId,
          activityType: activity.activityType,
          difficulty: activity.difficulty,
          instruction: activity.instruction,
          audioUrl: activity.audioUrl,
          question: JSON.stringify(activity.question, null, 2),
          options: JSON.stringify(activity.options, null, 2),
          correctAnswer: JSON.stringify(activity.correctAnswer, null, 2),
          hint: activity.hint,
          rewardXp: activity.rewardXp,
          rewardCoins: activity.rewardCoins,
        }}
      />
    </div>
  );
}
