'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { updateActivity } from '../actions';
import { ActivityFormFields, readActivityFormData, type ActivityFormDefaults } from '@/components/admin/ActivityFormFields';

interface EditActivityFormProps {
  activityId: string;
  missions: { id: string; label: string }[];
  defaults: ActivityFormDefaults;
}

export function EditActivityForm({ activityId, missions, defaults }: EditActivityFormProps) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(formData: FormData) {
    setLoading(true);
    setError(null);
    setSaved(false);
    try {
      await updateActivity(activityId, readActivityFormData(formData));
      setSaved(true);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Erro ao salvar atividade.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <form action={handleSubmit} className="bg-white rounded-xl shadow p-6 flex flex-col gap-4 max-w-xl">
      <ActivityFormFields missions={missions} defaults={defaults} />
      {error && <p className="text-ludile-error text-sm font-semibold">{error}</p>}
      {saved && <p className="text-ludile-success text-sm font-semibold">Atividade atualizada com sucesso.</p>}
      <div className="flex gap-3">
        <button
          type="submit"
          disabled={loading}
          className="bg-ludile-primary text-white px-4 py-3 rounded-xl font-bold"
        >
          {loading ? 'Salvando...' : 'Salvar alterações'}
        </button>
        <button
          type="button"
          onClick={() => router.push('/admin/atividades')}
          className="px-4 py-3 rounded-xl font-bold text-slate-600 border"
        >
          Voltar à lista
        </button>
      </div>
    </form>
  );
}
