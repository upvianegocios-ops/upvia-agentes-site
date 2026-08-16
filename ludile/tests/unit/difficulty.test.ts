import { describe, expect, it } from 'vitest';
import { decideNextDifficulty, nextHelpLevel, MAX_DIFFICULTY, MIN_DIFFICULTY } from '@/lib/game-engine/difficulty';
import type { AdaptiveState, AttemptRecord } from '@/lib/game-engine/types';

function attempt(overrides: Partial<AttemptRecord> = {}): AttemptRecord {
  return {
    isCorrect: true,
    hintsUsed: 0,
    timeSpentMs: 3000,
    difficulty: 2,
    createdAt: new Date().toISOString(),
    ...overrides,
  };
}

describe('decideNextDifficulty', () => {
  it('aumenta a dificuldade em um acerto sem pistas', () => {
    const state: AdaptiveState = { currentDifficulty: 2, recentAttempts: [] };
    const result = decideNextDifficulty(state, attempt({ isCorrect: true, hintsUsed: 0 }));
    expect(result.nextDifficulty).toBe(3);
  });

  it('nunca ultrapassa a dificuldade máxima', () => {
    const state: AdaptiveState = { currentDifficulty: MAX_DIFFICULTY, recentAttempts: [] };
    const result = decideNextDifficulty(state, attempt({ isCorrect: true, hintsUsed: 0 }));
    expect(result.nextDifficulty).toBe(MAX_DIFFICULTY);
  });

  it('reduz a dificuldade depois de dois erros seguidos', () => {
    const firstError = attempt({ isCorrect: false });
    const state: AdaptiveState = { currentDifficulty: 3, recentAttempts: [firstError] };
    const result = decideNextDifficulty(state, attempt({ isCorrect: false }));
    expect(result.nextDifficulty).toBe(2);
  });

  it('nunca desce abaixo da dificuldade mínima', () => {
    const firstError = attempt({ isCorrect: false });
    const state: AdaptiveState = { currentDifficulty: MIN_DIFFICULTY, recentAttempts: [firstError] };
    const result = decideNextDifficulty(state, attempt({ isCorrect: false }));
    expect(result.nextDifficulty).toBe(MIN_DIFFICULTY);
  });

  it('sinaliza explicação visual depois de três erros seguidos', () => {
    const history = [attempt({ isCorrect: false }), attempt({ isCorrect: false })];
    const state: AdaptiveState = { currentDifficulty: 2, recentAttempts: history };
    const result = decideNextDifficulty(state, attempt({ isCorrect: false }));
    expect(result.showVisualExplanation).toBe(true);
  });

  it('não acusa cansaço quando o desempenho está estável', () => {
    const stableHistory = Array.from({ length: 5 }, () => attempt({ isCorrect: true, timeSpentMs: 2000 }));
    const state: AdaptiveState = { currentDifficulty: 2, recentAttempts: stableHistory };
    const result = decideNextDifficulty(state, attempt({ isCorrect: true, timeSpentMs: 2000 }));
    expect(result.suggestShorterActivity).toBe(false);
  });

  it('detecta sinais de cansaço quando o tempo sobe e o acerto cai', () => {
    // Janela cheia (6 tentativas): 3 rápidas/certas seguidas de 3 lentas/erradas.
    const history = [
      attempt({ isCorrect: true, timeSpentMs: 1500 }),
      attempt({ isCorrect: true, timeSpentMs: 1600 }),
      attempt({ isCorrect: true, timeSpentMs: 1400 }),
      attempt({ isCorrect: false, timeSpentMs: 6000 }),
      attempt({ isCorrect: false, timeSpentMs: 6200 }),
    ];
    const state: AdaptiveState = { currentDifficulty: 2, recentAttempts: history };

    const result = decideNextDifficulty(state, attempt({ isCorrect: false, timeSpentMs: 6500 }));

    expect(result.suggestShorterActivity).toBe(true);
  });
});

describe('nextHelpLevel', () => {
  it('segue a progressão tentar de novo -> pista -> exemplo', () => {
    expect(nextHelpLevel(1)).toBe('tentar_novamente');
    expect(nextHelpLevel(2)).toBe('pista');
    expect(nextHelpLevel(3)).toBe('exemplo');
    expect(nextHelpLevel(4)).toBe('exemplo');
  });
});
