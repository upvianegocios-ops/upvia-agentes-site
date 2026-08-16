'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { ActivityRenderer } from '@/components/games/ActivityRenderer';
import { RewardModal } from '@/components/ui/RewardModal';
import { ProgressBar } from '@/components/ui/ProgressBar';
import { GameButton } from '@/components/ui/GameButton';
import { recordAttempt, completeMission } from '../../game-actions';
import { decideNextDifficulty } from '@/lib/game-engine/difficulty';
import { queueAttempt, flushQueue } from '@/lib/offline/queue';
import type { Activity } from '@/lib/game-engine/types';
import type { ActivityAttemptSummary } from '@/lib/game-engine/rewards';
import type { GameCompletionResult } from '@/lib/game-engine/game-props';

interface MissionPlayerProps {
  missionId: string;
  organizationId: string;
  childId: string;
  activities: Activity[];
}

export function MissionPlayer({ missionId, organizationId, childId, activities }: MissionPlayerProps) {
  const router = useRouter();
  const [index, setIndex] = useState(0);
  const [attempts, setAttempts] = useState<ActivityAttemptSummary[]>([]);
  const [banner, setBanner] = useState<string | null>(null);
  const [reward, setReward] = useState<{ stars: 1 | 2 | 3; xp: number; coins: number } | null>(null);

  const currentActivity = activities[index];
  const isLastActivity = index === activities.length - 1;

  useEffect(() => {
    const flush = () =>
      flushQueue((payload) => recordAttempt(payload as unknown as Parameters<typeof recordAttempt>[0]));
    flush();
    window.addEventListener('online', flush);
    return () => window.removeEventListener('online', flush);
  }, []);

  async function handleComplete(result: GameCompletionResult) {
    if (!currentActivity) return;

    const attemptPayload = {
      organizationId,
      childId,
      activityId: currentActivity.id,
      isCorrect: result.isCorrect,
      hintsUsed: result.hintsUsed,
      timeSpentMs: result.timeSpentMs,
      difficulty: currentActivity.difficulty,
    };
    try {
      await recordAttempt(attemptPayload);
    } catch {
      // Offline ou falha de rede: guarda localmente e sincroniza depois (seção 17).
      queueAttempt(attemptPayload);
    }

    const decision = decideNextDifficulty(
      { currentDifficulty: currentActivity.difficulty, recentAttempts: [] },
      {
        isCorrect: result.isCorrect,
        hintsUsed: result.hintsUsed,
        timeSpentMs: result.timeSpentMs,
        difficulty: currentActivity.difficulty,
        createdAt: new Date().toISOString(),
      }
    );
    if (decision.suggestShorterActivity) {
      setBanner('Que tal descansar um pouquinho? Você pode continuar quando quiser. 💛');
    } else if (decision.showVisualExplanation) {
      setBanner('Vamos com calma, vamos tentar juntos! 🌟');
    } else {
      setBanner(null);
    }

    const nextAttempts = [...attempts, { isCorrect: result.isCorrect, hintsUsed: result.hintsUsed }];
    setAttempts(nextAttempts);

    if (isLastActivity) {
      const missionResult = await completeMission({
        organizationId,
        childId,
        missionId,
        activities,
        attempts: nextAttempts,
      });
      setReward({ stars: missionResult.starsEarned, xp: missionResult.xpEarned, coins: missionResult.coinsEarned });
    } else {
      window.setTimeout(() => setIndex((i) => i + 1), 900);
    }
  }

  if (!currentActivity) {
    return null;
  }

  if (reward) {
    return (
      <RewardModal
        open
        stars={reward.stars}
        xpEarned={reward.xp}
        coinsEarned={reward.coins}
        onContinue={() => router.push('/mapa')}
      />
    );
  }

  return (
    <main className="min-h-screen p-6 flex flex-col gap-6 items-center">
      <div className="w-full max-w-lg flex items-center gap-4">
        <GameButton variant="ghost" onClick={() => router.push('/mapa')} aria-label="Voltar ao mapa">
          🏠
        </GameButton>
        <div className="flex-1">
          <ProgressBar
            value={(index / activities.length) * 100}
            label={`Atividade ${index + 1} de ${activities.length}`}
          />
        </div>
      </div>

      {banner && (
        <p role="status" className="text-child-base font-bold text-ludile-primary text-center">
          {banner}
        </p>
      )}

      <ActivityRenderer activity={currentActivity} onComplete={handleComplete} />
    </main>
  );
}
