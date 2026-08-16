import type { AdaptiveDecision, AdaptiveState, AttemptRecord } from './types';

// Motor de dificuldade adaptativo — seção 9 do documento mestre.
// Regra de ouro: é um algoritmo determinístico e explicável, NUNCA um
// "diagnóstico" de IA. Só ajusta dificuldade, sugere explicação e sugere
// pausa — nunca rotula a criança.

export const MIN_DIFFICULTY = 1;
export const MAX_DIFFICULTY = 5;
const WINDOW_SIZE = 6;
const FATIGUE_TIME_MULTIPLIER = 1.4;
const FATIGUE_ACCURACY_DROP = 0.2;

function clampDifficulty(value: number): number {
  return Math.min(MAX_DIFFICULTY, Math.max(MIN_DIFFICULTY, value));
}

function average(values: number[]): number {
  if (values.length === 0) return 0;
  return values.reduce((sum, v) => sum + v, 0) / values.length;
}

function accuracy(attempts: AttemptRecord[]): number {
  if (attempts.length === 0) return 1;
  return attempts.filter((a) => a.isCorrect).length / attempts.length;
}

/**
 * Sinais de cansaço: tempo de resposta subindo e acerto caindo na segunda
 * metade da janela recente, comparada com a primeira metade.
 */
function detectFatigue(attempts: AttemptRecord[]): boolean {
  if (attempts.length < WINDOW_SIZE) return false;
  const mid = Math.floor(attempts.length / 2);
  const firstHalf = attempts.slice(0, mid);
  const secondHalf = attempts.slice(mid);

  const timeIncreased =
    average(secondHalf.map((a) => a.timeSpentMs)) >
    average(firstHalf.map((a) => a.timeSpentMs)) * FATIGUE_TIME_MULTIPLIER;
  const accuracyDropped = accuracy(secondHalf) < accuracy(firstHalf) - FATIGUE_ACCURACY_DROP;

  return timeIncreased && accuracyDropped;
}

export function decideNextDifficulty(state: AdaptiveState, latest: AttemptRecord): AdaptiveDecision {
  const attempts = [...state.recentAttempts, latest].slice(-WINDOW_SIZE);
  let next = state.currentDifficulty;
  let reason = 'Sem sinal suficiente para mudar a dificuldade.';

  const lastTwo = attempts.slice(-2);
  const repeatedError = lastTwo.length === 2 && lastTwo.every((a) => !a.isCorrect);

  if (latest.isCorrect && latest.hintsUsed === 0) {
    next = clampDifficulty(state.currentDifficulty + 1);
    reason = 'Acerto sem precisar de pistas: aumentando a dificuldade.';
  } else if (repeatedError) {
    next = clampDifficulty(state.currentDifficulty - 1);
    reason = 'Dois erros seguidos: reduzindo a dificuldade.';
  }

  const lastThree = attempts.slice(-3);
  const showVisualExplanation =
    lastThree.length === 3 && lastThree.filter((a) => !a.isCorrect).length === 3;
  if (showVisualExplanation) {
    reason = 'Vários erros seguidos: hora de mostrar uma explicação visual/sonora.';
  }

  const suggestShorterActivity = detectFatigue(attempts);
  if (suggestShorterActivity) {
    reason = 'Sinais de cansaço detectados: sugerindo uma atividade mais curta.';
  }

  return {
    nextDifficulty: next,
    showVisualExplanation,
    suggestShorterActivity,
    reason,
  };
}

/**
 * Sistema de ajuda progressiva no erro (seção 23):
 * tentativa 1 → tentar de novo · tentativa 2 → pista · tentativa 3 → exemplo.
 * Nunca revela a resposta sem contexto.
 */
export type HelpLevel = 'tentar_novamente' | 'pista' | 'exemplo';

export function nextHelpLevel(attemptNumber: number): HelpLevel {
  if (attemptNumber <= 1) return 'tentar_novamente';
  if (attemptNumber === 2) return 'pista';
  return 'exemplo';
}
