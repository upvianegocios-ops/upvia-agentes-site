import { listMissionsForSelect } from '@/lib/data/admin-queries';
import { NewActivityForm } from './NewActivityForm';

export default async function NovaAtividadePage() {
  const missions = await listMissionsForSelect();
  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-xl font-extrabold">Nova atividade</h1>
      <NewActivityForm missions={missions} />
    </div>
  );
}
