'use server';

import { createClient } from '@/lib/supabase/server';
import { computeMissionResult, type ActivityAttemptSummary } from '@/lib/game-engine/rewards';
import type { Activity } from '@/lib/game-engine/types';

interface RecordAttemptInput {
  organizationId: string;
  childId: string;
  activityId: string;
  isCorrect: boolean;
  hintsUsed: number;
  timeSpentMs: number;
  difficulty: number;
}

export async function recordAttempt(input: RecordAttemptInput) {
  const supabase = createClient();
  const { error } = await supabase.from('attempts').insert({
    organization_id: input.organizationId,
    child_id: input.childId,
    activity_id: input.activityId,
    is_correct: input.isCorrect,
    hints_used: input.hintsUsed,
    time_spent_ms: input.timeSpentMs,
    difficulty_at_attempt: input.difficulty,
  });
  if (error) throw error;
}

interface CompleteMissionInput {
  organizationId: string;
  childId: string;
  missionId: string;
  activities: Activity[];
  attempts: ActivityAttemptSummary[];
}

export async function completeMission(input: CompleteMissionInput) {
  const supabase = createClient();
  const result = computeMissionResult(input.activities, input.attempts);

  const { error } = await supabase.from('game_progress').upsert(
    {
      organization_id: input.organizationId,
      child_id: input.childId,
      mission_id: input.missionId,
      status: 'completed',
      stars_earned: result.starsEarned,
      xp_earned: result.xpEarned,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'child_id,mission_id' }
  );
  if (error) throw error;

  return result;
}

export async function createChildProfile(input: {
  organizationId: string;
  parentUserId: string;
  nickname: string;
  avatarId: string;
}) {
  const supabase = createClient();
  const { data: child, error } = await supabase
    .from('child_profiles')
    .insert({
      organization_id: input.organizationId,
      nickname: input.nickname,
      avatar_id: input.avatarId,
    })
    .select('id')
    .single();
  if (error) throw error;

  const { error: relError } = await supabase.from('child_parent_relationships').insert({
    organization_id: input.organizationId,
    child_id: child.id,
    parent_user_id: input.parentUserId,
  });
  if (relError) throw relError;

  return child.id as string;
}
