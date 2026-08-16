'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import { isCurrentUserSystemAdmin } from '@/lib/data/admin-queries';

async function assertAdmin() {
  const isAdmin = await isCurrentUserSystemAdmin();
  if (!isAdmin) throw new Error('Acesso negado: apenas system_admin pode gerenciar o catálogo.');
}

export interface ActivityFormInput {
  missionId: string;
  activityType: string;
  difficulty: number;
  instruction: string;
  audioUrl: string | null;
  question: string; // JSON string vindo do form
  options: string; // JSON string
  correctAnswer: string; // JSON string
  hint: string | null;
  rewardXp: number;
  rewardCoins: number;
}

function parseJsonField(raw: string, fieldName: string): unknown {
  try {
    return JSON.parse(raw);
  } catch {
    throw new Error(`Campo "${fieldName}" precisa ser um JSON válido.`);
  }
}

export async function createActivity(input: ActivityFormInput) {
  await assertAdmin();
  const supabase = createClient();
  const { error } = await supabase.from('activities').insert({
    mission_id: input.missionId,
    activity_type: input.activityType,
    difficulty: input.difficulty,
    instruction: input.instruction,
    audio_url: input.audioUrl,
    question: parseJsonField(input.question, 'question'),
    options: parseJsonField(input.options, 'options'),
    correct_answer: parseJsonField(input.correctAnswer, 'correct_answer'),
    hint: input.hint,
    reward: { xp: input.rewardXp, coins: input.rewardCoins },
  });
  if (error) throw error;
  revalidatePath('/admin/atividades');
}

export async function updateActivity(activityId: string, input: ActivityFormInput) {
  await assertAdmin();
  const supabase = createClient();
  const { error } = await supabase
    .from('activities')
    .update({
      mission_id: input.missionId,
      activity_type: input.activityType,
      difficulty: input.difficulty,
      instruction: input.instruction,
      audio_url: input.audioUrl,
      question: parseJsonField(input.question, 'question'),
      options: parseJsonField(input.options, 'options'),
      correct_answer: parseJsonField(input.correctAnswer, 'correct_answer'),
      hint: input.hint,
      reward: { xp: input.rewardXp, coins: input.rewardCoins },
      updated_at: new Date().toISOString(),
    })
    .eq('id', activityId);
  if (error) throw error;
  revalidatePath('/admin/atividades');
  revalidatePath(`/admin/atividades/${activityId}`);
}

export async function toggleActivityActive(activityId: string, isActive: boolean) {
  await assertAdmin();
  const supabase = createClient();
  const { error } = await supabase.from('activities').update({ is_active: isActive }).eq('id', activityId);
  if (error) throw error;
  revalidatePath('/admin/atividades');
}

export async function deleteActivity(activityId: string) {
  await assertAdmin();
  const supabase = createClient();
  const { error } = await supabase.from('activities').delete().eq('id', activityId);
  if (error) throw error;
  revalidatePath('/admin/atividades');
}
