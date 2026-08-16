import { createClient } from '@/lib/supabase/server';

export async function isCurrentUserSystemAdmin(): Promise<boolean> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return false;

  const { data } = await supabase
    .from('org_members')
    .select('id')
    .eq('user_id', user.id)
    .eq('role', 'system_admin')
    .limit(1)
    .maybeSingle();

  return Boolean(data);
}

export interface AdminActivityRow {
  id: string;
  instruction: string;
  activityType: string;
  difficulty: number;
  isActive: boolean;
  missionName: string;
  worldName: string;
}

export async function listActivitiesForAdmin(): Promise<AdminActivityRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('activities')
    .select(
      'id, instruction, activity_type, difficulty, is_active, missions!inner(name, worlds!inner(name))'
    )
    .order('order_index');

  if (error) throw error;
  return (data ?? []).map((row) => {
    const mission = (row as unknown as { missions: { name: string; worlds: { name: string } } }).missions;
    return {
      id: row.id,
      instruction: row.instruction,
      activityType: row.activity_type,
      difficulty: row.difficulty,
      isActive: row.is_active,
      missionName: mission.name,
      worldName: mission.worlds.name,
    };
  });
}

export interface AdminActivityDetail {
  id: string;
  missionId: string;
  activityType: string;
  difficulty: number;
  instruction: string;
  audioUrl: string | null;
  question: unknown;
  options: unknown;
  correctAnswer: unknown;
  hint: string | null;
  rewardXp: number;
  rewardCoins: number;
}

export async function getActivityForAdmin(activityId: string): Promise<AdminActivityDetail | null> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('activities')
    .select(
      'id, mission_id, activity_type, difficulty, instruction, audio_url, question, options, correct_answer, hint, reward'
    )
    .eq('id', activityId)
    .maybeSingle();

  if (error) throw error;
  if (!data) return null;

  const reward = (data.reward ?? {}) as { xp?: number; coins?: number };
  return {
    id: data.id,
    missionId: data.mission_id,
    activityType: data.activity_type,
    difficulty: data.difficulty,
    instruction: data.instruction,
    audioUrl: data.audio_url,
    question: data.question,
    options: data.options,
    correctAnswer: data.correct_answer,
    hint: data.hint,
    rewardXp: reward.xp ?? 10,
    rewardCoins: reward.coins ?? 2,
  };
}

export interface AdminStats {
  organizations: number;
  children: number;
  activities: number;
  attempts: number;
}

export async function getAdminStats(): Promise<AdminStats> {
  const supabase = createClient();
  const [orgs, children, activities, attempts] = await Promise.all([
    supabase.from('organizations').select('id', { count: 'exact', head: true }),
    supabase.from('child_profiles').select('id', { count: 'exact', head: true }),
    supabase.from('activities').select('id', { count: 'exact', head: true }),
    supabase.from('attempts').select('id', { count: 'exact', head: true }),
  ]);

  return {
    organizations: orgs.count ?? 0,
    children: children.count ?? 0,
    activities: activities.count ?? 0,
    attempts: attempts.count ?? 0,
  };
}

export async function listMissionsForSelect(): Promise<{ id: string; label: string }[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('missions')
    .select('id, name, worlds!inner(name)')
    .order('order_index');
  if (error) throw error;
  return (data ?? []).map((m) => ({
    id: m.id,
    label: `${(m as unknown as { worlds: { name: string } }).worlds.name} — ${m.name}`,
  }));
}
