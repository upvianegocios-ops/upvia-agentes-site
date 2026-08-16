import type { Activity, MissionResult } from './types';

// Regras duras da seção 7: nunca punir por erro, nunca remover progresso.
// Estrelas medem desempenho na missão, mas o XP/moedas da atividade em si
// sempre é concedido ao acertar — nunca é retirado depois de ganho.

export interface ActivityAttemptSummary {
  isCorrect: boolean;
  hintsUsed: number;
}

export function computeMissionStars(attempts: ActivityAttemptSummary[]): 1 | 2 | 3 {
  if (attempts.length === 0) return 1;
  const totalHints = attempts.reduce((sum, a) => sum + a.hintsUsed, 0);
  const allCorrectFirstTry = attempts.every((a) => a.isCorrect) && totalHints === 0;
  const allCorrect = attempts.every((a) => a.isCorrect);

  if (allCorrectFirstTry) return 3;
  if (allCorrect) return 2;
  return 1;
}

export function computeMissionResult(
  activities: Activity[],
  attempts: ActivityAttemptSummary[]
): MissionResult {
  const xpEarned = activities.reduce((sum, a) => sum + a.reward.xp, 0);
  const coinsEarned = activities.reduce((sum, a) => sum + a.reward.coins, 0);
  const starsEarned = computeMissionStars(attempts);

  return { starsEarned, xpEarned, coinsEarned };
}
