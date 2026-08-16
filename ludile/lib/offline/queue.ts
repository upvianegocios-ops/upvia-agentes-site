'use client';

// Fila de sincronização offline (seção 17): se a gravação da tentativa falhar
// por falta de conexão, guardamos localmente e tentamos de novo quando a
// internet voltar. Progresso da criança nunca se perde por estar offline.
//
// Limitação conhecida (documentada em PENDENCIAS.md): usa localStorage, que
// tem limite de alguns MB — suficiente para o volume de tentativas do MVP,
// mas deve migrar para IndexedDB se o volume de uso offline crescer muito.

const QUEUE_KEY = 'ludile_offline_attempt_queue';

export interface QueuedAttempt {
  id: string;
  payload: Record<string, unknown>;
  queuedAt: string;
}

export function queueAttempt(payload: Record<string, unknown>): void {
  if (typeof window === 'undefined') return;
  const queue = readQueue();
  queue.push({ id: crypto.randomUUID(), payload, queuedAt: new Date().toISOString() });
  window.localStorage.setItem(QUEUE_KEY, JSON.stringify(queue));
}

export function readQueue(): QueuedAttempt[] {
  if (typeof window === 'undefined') return [];
  try {
    return JSON.parse(window.localStorage.getItem(QUEUE_KEY) ?? '[]');
  } catch {
    return [];
  }
}

export async function flushQueue(sendFn: (payload: Record<string, unknown>) => Promise<void>): Promise<void> {
  const queue = readQueue();
  if (queue.length === 0) return;

  const remaining: QueuedAttempt[] = [];
  for (const item of queue) {
    try {
      await sendFn(item.payload);
    } catch {
      remaining.push(item);
    }
  }
  window.localStorage.setItem(QUEUE_KEY, JSON.stringify(remaining));
}
