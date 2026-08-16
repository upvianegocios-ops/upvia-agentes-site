import { redirect } from 'next/navigation';
import Link from 'next/link';
import { isCurrentUserSystemAdmin } from '@/lib/data/admin-queries';

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const isAdmin = await isCurrentUserSystemAdmin();
  if (!isAdmin) redirect('/');

  return (
    <div className="min-h-screen bg-slate-50">
      <nav className="bg-white border-b p-4 flex gap-6 items-center">
        <span className="font-extrabold text-ludile-primary">Ludilê — Admin</span>
        <Link href="/admin" className="text-sm font-semibold text-slate-600">
          Visão geral
        </Link>
        <Link href="/admin/atividades" className="text-sm font-semibold text-slate-600">
          Atividades
        </Link>
      </nav>
      <div className="p-6 max-w-4xl mx-auto">{children}</div>
    </div>
  );
}
