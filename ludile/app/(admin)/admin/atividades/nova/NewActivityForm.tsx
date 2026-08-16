'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createActivity } from '../actions';
import { ActivityFormFields, readActivityFormData } from '@/components/admin/ActivityFormFields';

export function NewActivityForm({ missions }: { missions: { id: string; label: string }[] }) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(formData: FormData) {
    setLoading(true);
    setError(null);
    try {
      await createActivity(readActivityFormData(formData));
      router.push('/admin/atividades');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Erro ao salvar atividade.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <form action={handleSubmit} className="bg-white rounded-xl shadow p-6 flex flex-col gap-4 max-w-xl">
      <ActivityFormFields missions={missions} />
      {error && <p className="text-ludile-error text-sm font-semibold">{error}</p>}
      <button
        type="submit"
        disabled={loading}
        className="bg-ludile-primary text-white px-4 py-3 rounded-xl font-bold"
      >
        {loading ? 'Salvando...' : 'Salvar atividade'}
      </button>
    </form>
  );
}
