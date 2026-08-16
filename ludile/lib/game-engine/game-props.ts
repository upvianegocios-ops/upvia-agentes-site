import type { Activity } from './types';

export interface GameCompletionResult {
  isCorrect: boolean;
  hintsUsed: number;
  timeSpentMs: number;
}

export interface GameProps {
  activity: Activity;
  onComplete: (result: GameCompletionResult) => void;
}
