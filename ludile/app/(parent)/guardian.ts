import { cookies } from 'next/headers';

export const GUARDIAN_COOKIE = 'ludile_guardian_verified';

// Só leitura síncrona, só para Server Components — a mutação (checkOrSetPin)
// mora em actions.ts, sozinha no módulo, porque uma Server Action chamada
// por um Client Component (PinGate.tsx) precisa estar isolada de qualquer
// export síncrono que use next/headers.
export function isGuardianVerified(): boolean {
  return cookies().get(GUARDIAN_COOKIE)?.value === '1';
}
