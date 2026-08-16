import { ACTIVITY_TYPES } from '@/lib/game-engine/types';

export interface ActivityFormDefaults {
  missionId?: string;
  activityType?: string;
  difficulty?: number;
  instruction?: string;
  audioUrl?: string | null;
  question?: string;
  options?: string;
  correctAnswer?: string;
  hint?: string | null;
  rewardXp?: number;
  rewardCoins?: number;
}

interface ActivityFormFieldsProps {
  missions: { id: string; label: string }[];
  defaults?: ActivityFormDefaults;
}

// Campos compartilhados entre "Nova atividade" e "Editar atividade" — o
// admin tem CRUD completo (seção 12), então o mesmo formulário serve para
// criar e para editar, só muda a action que recebe o submit.
export function ActivityFormFields({ missions, defaults = {} }: ActivityFormFieldsProps) {
  return (
    <>
      <label className="flex flex-col gap-1">
        <span className="font-bold text-sm">Missão</span>
        <select name="missionId" required defaultValue={defaults.missionId} className="border rounded-lg p-2">
          {missions.map((m) => (
            <option key={m.id} value={m.id}>
              {m.label}
            </option>
          ))}
        </select>
      </label>
      <label className="flex flex-col gap-1">
        <span className="font-bold text-sm">Tipo de jogo</span>
        <select name="activityType" required defaultValue={defaults.activityType} className="border rounded-lg p-2">
          {ACTIVITY_TYPES.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </select>
      </label>
      <label className="flex flex-col gap-1">
        <span className="font-bold text-sm">Dificuldade (1-5)</span>
        <input
          type="number"
          name="difficulty"
          min={1}
          max={5}
          defaultValue={defaults.difficulty ?? 1}
          className="border rounded-lg p-2"
        />
      </label>
      <label className="flex flex-col gap-1">
        <span className="font-bold text-sm">Instrução</span>
        <input name="instruction" required defaultValue={defaults.instruction} className="border rounded-lg p-2" />
      </label>
      <label className="flex flex-col gap-1">
        <span className="font-bold text-sm">URL do áudio (opcional)</span>
        <input name="audioUrl" defaultValue={defaults.audioUrl ?? ''} className="border rounded-lg p-2" />
      </label>
      <label className="flex flex-col gap-1">
        <span className="font-bold text-sm">question (JSON)</span>
        <textarea name="question" defaultValue={defaults.question ?? '{}'} className="border rounded-lg p-2 font-mono text-xs" />
      </label>
      <label className="flex flex-col gap-1">
        <span className="font-bold text-sm">options (JSON array)</span>
        <textarea name="options" defaultValue={defaults.options ?? '[]'} className="border rounded-lg p-2 font-mono text-xs" />
      </label>
      <label className="flex flex-col gap-1">
        <span className="font-bold text-sm">correctAnswer (JSON)</span>
        <textarea
          name="correctAnswer"
          defaultValue={defaults.correctAnswer ?? '{}'}
          className="border rounded-lg p-2 font-mono text-xs"
        />
      </label>
      <label className="flex flex-col gap-1">
        <span className="font-bold text-sm">Dica (opcional)</span>
        <input name="hint" defaultValue={defaults.hint ?? ''} className="border rounded-lg p-2" />
      </label>
      <div className="flex gap-4">
        <label className="flex flex-col gap-1">
          <span className="font-bold text-sm">XP</span>
          <input
            type="number"
            name="rewardXp"
            defaultValue={defaults.rewardXp ?? 10}
            className="border rounded-lg p-2 w-24"
          />
        </label>
        <label className="flex flex-col gap-1">
          <span className="font-bold text-sm">Moedas</span>
          <input
            type="number"
            name="rewardCoins"
            defaultValue={defaults.rewardCoins ?? 2}
            className="border rounded-lg p-2 w-24"
          />
        </label>
      </div>
    </>
  );
}

export function readActivityFormData(formData: FormData) {
  return {
    missionId: String(formData.get('missionId')),
    activityType: String(formData.get('activityType')),
    difficulty: Number(formData.get('difficulty')),
    instruction: String(formData.get('instruction')),
    audioUrl: (formData.get('audioUrl') as string) || null,
    question: String(formData.get('question') || '{}'),
    options: String(formData.get('options') || '[]'),
    correctAnswer: String(formData.get('correctAnswer') || '{}'),
    hint: (formData.get('hint') as string) || null,
    rewardXp: Number(formData.get('rewardXp') || 10),
    rewardCoins: Number(formData.get('rewardCoins') || 2),
  };
}
