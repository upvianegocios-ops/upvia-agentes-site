'use server';

import { cookies } from 'next/headers';
import { createClient } from '@/lib/supabase/server';
import { hashPin, verifyPin } from '@/lib/pin';
import { GUARDIAN_COOKIE } from './guardian';

export async function checkOrSetPin(organizationId: string, pin: string): Promise<{ ok: boolean; error?: string }> {
  if (!/^\d{4,6}$/.test(pin)) {
    return { ok: false, error: 'O PIN deve ter de 4 a 6 números.' };
  }

  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: 'Sessão expirada. Faça login novamente.' };

  const { data: existing } = await supabase
    .from('guardian_pins')
    .select('pin_hash')
    .eq('organization_id', organizationId)
    .eq('user_id', user.id)
    .maybeSingle();

  if (!existing) {
    // Primeiro acesso: o valor digitado define o PIN.
    await supabase.from('guardian_pins').insert({
      organization_id: organizationId,
      user_id: user.id,
      pin_hash: hashPin(pin),
    });
  } else if (!verifyPin(pin, existing.pin_hash)) {
    return { ok: false, error: 'PIN incorreto.' };
  }

  cookies().set(GUARDIAN_COOKIE, '1', {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: 60 * 15, // 15 minutos — reautentica periodicamente
  });

  return { ok: true };
}
