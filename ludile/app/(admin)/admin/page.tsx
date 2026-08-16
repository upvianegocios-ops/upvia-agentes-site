import { getAdminStats } from '@/lib/data/admin-queries';

export default async function AdminHomePage() {
  const stats = await getAdminStats();

  const cards = [
    { label: 'Organizações (tenants)', value: stats.organizations },
    { label: 'Crianças cadastradas', value: stats.children },
    { label: 'Atividades no catálogo', value: stats.activities },
    { label: 'Tentativas registradas', value: stats.attempts },
  ];

  return (
    <div className="grid grid-cols-2 gap-4">
      {cards.map((c) => (
        <div key={c.label} className="bg-white rounded-xl shadow p-4">
          <p className="text-3xl font-extrabold text-ludile-primary">{c.value}</p>
          <p className="text-sm text-slate-500">{c.label}</p>
        </div>
      ))}
    </div>
  );
}
