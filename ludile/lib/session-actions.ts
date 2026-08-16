'use server';

import { cookies } from 'next/headers';
import { CHILD_COOKIE } from './session';

// Server Action pura neste módulo (nada síncrono aqui) — é o que permite
// que Client Components (ex: app/(child)/personagem/novo/page.tsx) chamem
// setActiveChild diretamente. Leitura síncrona fica em lib/session.ts.
export async function setActiveChild(childId: string) {
  cookies().set(CHILD_COOKIE, childId, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: 60 * 60 * 24 * 30,
  });
}
