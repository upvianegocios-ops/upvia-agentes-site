import Link from 'next/link';
import { listActivitiesForAdmin } from '@/lib/data/admin-queries';
import { ActivityRow } from './ActivityRow';

export default async function AdminAtividadesPage() {
  const activities = await listActivitiesForAdmin();

  return (
    <div className="flex flex-col gap-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-extrabold">Atividades</h1>
        <Link
          href="/admin/atividades/nova"
          className="bg-ludile-primary text-white px-4 py-2 rounded-xl font-bold text-sm"
        >
          + Nova atividade
        </Link>
      </div>
      <div className="bg-white rounded-xl shadow overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead>
            <tr className="border-b bg-slate-50">
              <th className="py-2 px-4">Instrução / Missão</th>
              <th className="py-2 px-4">Tipo</th>
              <th className="py-2 px-4">Dificuldade</th>
              <th className="py-2 px-4">Status</th>
              <th className="py-2 px-4"></th>
            </tr>
          </thead>
          <tbody>
            {activities.map((a) => (
              <ActivityRow key={a.id} activity={a} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
