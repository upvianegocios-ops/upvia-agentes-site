'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { toggleActivityActive, deleteActivity } from './actions';
import type { AdminActivityRow } from '@/lib/data/admin-queries';

export function ActivityRow({ activity }: { activity: AdminActivityRow }) {
  const [isPending, startTransition] = useTransition();
  const [removed, setRemoved] = useState(false);

  if (removed) return null;

  return (
    <tr className="border-b">
      <td className="py-2 pr-4">
        <p className="font-semibold">{activity.instruction}</p>
        <p className="text-xs text-slate-500">
          {activity.worldName} — {activity.missionName}
        </p>
      </td>
      <td className="py-2 pr-4">{activity.activityType}</td>
      <td className="py-2 pr-4">{activity.difficulty}</td>
      <td className="py-2 pr-4">
        <button
          type="button"
          disabled={isPending}
          onClick={() =>
            startTransition(async () => {
              await toggleActivityActive(activity.id, !activity.isActive);
            })
          }
          className={`px-3 py-1 rounded-full text-xs font-bold ${
            activity.isActive ? 'bg-green-100 text-green-700' : 'bg-slate-200 text-slate-600'
          }`}
        >
          {activity.isActive ? 'Ativa' : 'Inativa'}
        </button>
      </td>
      <td className="py-2">
        <div className="flex gap-3 items-center">
          <Link href={`/admin/atividades/${activity.id}`} className="text-ludile-primary text-sm font-bold">
            Editar
          </Link>
          <button
            type="button"
            disabled={isPending}
            onClick={() =>
              startTransition(async () => {
                if (confirm('Remover esta atividade do catálogo?')) {
                  await deleteActivity(activity.id);
                  setRemoved(true);
                }
              })
            }
            className="text-ludile-error text-sm font-bold"
          >
            Excluir
          </button>
        </div>
      </td>
    </tr>
  );
}
