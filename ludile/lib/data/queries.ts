import { createClient } from '@/lib/supabase/server';
import type { Activity } from '@/lib/game-engine/types';

export interface World {
  id: string;
  code: string;
  name: string;
  description: string | null;
  icon: string | null;
  orderIndex: number;
}

export interface Mission {
  id: string;
  worldId: string;
  code: string;
  name: string;
  description: string | null;
  orderIndex: number;
}

export interface ChildProfile {
  id: string;
  organizationId: string;
  nickname: string;
  avatarId: string;
  accessibilitySettings: Record<string, unknown>;
}

export interface MissionProgress {
  missionId: string;
  status: 'locked' | 'available' | 'in_progress' | 'completed';
  starsEarned: number;
}

export async function getActiveWorlds(): Promise<World[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('worlds')
    .select('id, code, name, description, icon, order_index')
    .eq('is_active', true)
    .order('order_index');

  if (error) throw error;
  return (data ?? []).map((w) => ({
    id: w.id,
    code: w.code,
    name: w.name,
    description: w.description,
    icon: w.icon,
    orderIndex: w.order_index,
  }));
}

export async function getMissionsForWorld(worldCode: string): Promise<Mission[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('missions')
    .select('id, world_id, code, name, description, order_index, worlds!inner(code)')
    .eq('worlds.code', worldCode)
    .eq('is_active', true)
    .order('order_index');

  if (error) throw error;
  return (data ?? []).map((m) => ({
    id: m.id,
    worldId: m.world_id,
    code: m.code,
    name: m.name,
    description: m.description,
    orderIndex: m.order_index,
  }));
}

export async function getActivitiesForMission(missionId: string): Promise<Activity[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('activities')
    .select('*')
    .eq('mission_id', missionId)
    .eq('is_active', true)
    .order('order_index');

  if (error) throw error;
  return (data ?? []).map((a) => ({
    id: a.id,
    missionId: a.mission_id,
    skillId: a.skill_id,
    activityType: a.activity_type,
    difficulty: a.difficulty,
    instruction: a.instruction,
    audioUrl: a.audio_url,
    question: a.question,
    options: a.options,
    correctAnswer: a.correct_answer,
    hint: a.hint,
    reward: a.reward,
    orderIndex: a.order_index,
  }));
}

export async function getMissionProgressForChild(childId: string): Promise<MissionProgress[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('game_progress')
    .select('mission_id, status, stars_earned')
    .eq('child_id', childId);

  if (error) throw error;
  return (data ?? []).map((p) => ({
    missionId: p.mission_id,
    status: p.status,
    starsEarned: p.stars_earned,
  }));
}

export interface SkillProgress {
  skillCode: string;
  skillName: string;
  masteryLevel: number;
}

export interface AttemptsSummary {
  totalAttempts: number;
  accuracyRate: number;
  averageHints: number;
}

export async function getChildSkillProgress(childId: string): Promise<SkillProgress[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('child_skill_progress')
    .select('mastery_level, skills!inner(code, name)')
    .eq('child_id', childId);

  if (error) throw error;
  return (data ?? []).map((row) => {
    const skill = (row as unknown as { skills: { code: string; name: string } }).skills;
    return {
      skillCode: skill.code,
      skillName: skill.name,
      masteryLevel: Number(row.mastery_level),
    };
  });
}

export async function getChildAttemptsSummary(childId: string): Promise<AttemptsSummary> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('attempts')
    .select('is_correct, hints_used')
    .eq('child_id', childId);

  if (error) throw error;
  const attempts = data ?? [];
  const totalAttempts = attempts.length;
  const correct = attempts.filter((a) => a.is_correct).length;

  return {
    totalAttempts,
    accuracyRate: totalAttempts > 0 ? Math.round((correct / totalAttempts) * 100) : 0,
    averageHints:
      totalAttempts > 0
        ? Number((attempts.reduce((s, a) => s + a.hints_used, 0) / totalAttempts).toFixed(1))
        : 0,
  };
}

export async function getChildrenForUser(userId: string): Promise<ChildProfile[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from('child_parent_relationships')
    .select('child_profiles!inner(id, organization_id, nickname, avatar_id, accessibility_settings, is_active)')
    .eq('parent_user_id', userId);

  if (error) throw error;
  return (data ?? [])
    .map((row) => {
      const child = (row as unknown as { child_profiles: Record<string, unknown> }).child_profiles;
      return {
        id: child.id as string,
        organizationId: child.organization_id as string,
        nickname: child.nickname as string,
        avatarId: child.avatar_id as string,
        accessibilitySettings: (child.accessibility_settings ?? {}) as Record<string, unknown>,
        isActive: child.is_active as boolean,
      };
    })
    .filter((c) => c.isActive)
    .map(({ id, organizationId, nickname, avatarId, accessibilitySettings }) => ({
      id,
      organizationId,
      nickname,
      avatarId,
      accessibilitySettings,
    }));
}
