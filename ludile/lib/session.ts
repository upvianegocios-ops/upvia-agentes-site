import { cookies } from 'next/headers';

export const CHILD_COOKIE = 'ludile_child_id';

// Só leitura síncrona, só para uso em Server Components — a mutação
// (setActiveChild) mora em lib/session-actions.ts, separada, porque uma
// Server Action chamada por um Client Component precisa estar sozinha no
// seu módulo (ver comentário lá).
export function getActiveChildId(): string | null {
  return cookies().get(CHILD_COOKIE)?.value ?? null;
}
