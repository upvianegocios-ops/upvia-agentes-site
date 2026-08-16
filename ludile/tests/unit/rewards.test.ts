import { describe, expect, it } from 'vitest';
import { computeMissionStars, computeMissionResult } from '@/lib/game-engine/rewards';
import type { Activity } from '@/lib/game-engine/types';

function makeActivity(xp: number, coins: number): Activity {
  return {
    id: crypto.randomUUID(),
    missionId: 'mission-1',
    skillId: null,
    activityType: 'caca_letra',
    difficulty: 1,
    instruction: 'teste',
    audioUrl: null,
    question: {},
    options: [],
    correctAnswer: {},
    hint: null,
    reward: { xp, coins },
    orderIndex: 0,
  };
}

describe('computeMissionStars', () => {
  it('dá 3 estrelas quando tudo certo sem nenhuma pista', () => {
    const stars = computeMissionStars([
      { isCorrect: true, hintsUsed: 0 },
      { isCorrect: true, hintsUsed: 0 },
    ]);
    expect(stars).toBe(3);
  });

  it('dá 2 estrelas quando acertou tudo mas usou pistas', () => {
    const stars = computeMissionStars([
      { isCorrect: true, hintsUsed: 1 },
      { isCorrect: true, hintsUsed: 0 },
    ]);
    expect(stars).toBe(2);
  });

  it('nunca dá 0 estrelas — errar não é punido, é parte do aprendizado (seção 7)', () => {
    const stars = computeMissionStars([
      { isCorrect: false, hintsUsed: 2 },
      { isCorrect: true, hintsUsed: 3 },
    ]);
    expect(stars).toBeGreaterThanOrEqual(1);
  });

  it('retorna 1 estrela para lista vazia em vez de quebrar', () => {
    expect(computeMissionStars([])).toBe(1);
  });
});

describe('computeMissionResult', () => {
  it('soma XP e moedas de todas as atividades da missão', () => {
    const activities = [makeActivity(10, 2), makeActivity(12, 3)];
    const attempts = [
      { isCorrect: true, hintsUsed: 0 },
      { isCorrect: true, hintsUsed: 0 },
    ];
    const result = computeMissionResult(activities, attempts);
    expect(result.xpEarned).toBe(22);
    expect(result.coinsEarned).toBe(5);
    expect(result.starsEarned).toBe(3);
  });
});
