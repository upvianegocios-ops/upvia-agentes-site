export type ActivityType =
  | 'caca_letra'
  | 'memoria'
  | 'qual_e_o_som'
  | 'comeca_com'
  | 'monte_a_silaba'
  | 'monte_a_palavra'
  | 'qual_e_a_palavra'
  | 'leia_e_escolha';

// Fonte única de verdade para o admin (formulários de criar/editar
// atividade) — evita a lista de tipos duplicar e divergir do union acima.
export const ACTIVITY_TYPES: ActivityType[] = [
  'caca_letra',
  'memoria',
  'qual_e_o_som',
  'comeca_com',
  'monte_a_silaba',
  'monte_a_palavra',
  'qual_e_a_palavra',
  'leia_e_escolha',
];

export interface Activity {
  id: string;
  missionId: string;
  skillId: string | null;
  activityType: ActivityType;
  difficulty: number; // 1-5
  instruction: string;
  audioUrl: string | null;
  question: Record<string, unknown>;
  options: unknown[];
  correctAnswer: Record<string, unknown>;
  hint: string | null;
  reward: { xp: number; coins: number };
  orderIndex: number;
}

export interface AttemptRecord {
  isCorrect: boolean;
  hintsUsed: number;
  timeSpentMs: number;
  difficulty: number;
  createdAt: string;
}

export interface AdaptiveState {
  currentDifficulty: number;
  recentAttempts: AttemptRecord[];
}

export interface AdaptiveDecision {
  nextDifficulty: number;
  showVisualExplanation: boolean;
  suggestShorterActivity: boolean;
  reason: string;
}

export interface MissionResult {
  starsEarned: 1 | 2 | 3;
  xpEarned: number;
  coinsEarned: number;
}
