import { randomBytes, scryptSync, timingSafeEqual } from 'crypto';

// PIN da área dos responsáveis nunca reaproveita a senha de login (seção 11):
// é uma segunda barreira simples, pensada para impedir que a criança entre
// sozinha, não para proteção contra ataque sofisticado.

export function hashPin(pin: string): string {
  const salt = randomBytes(16).toString('hex');
  const hash = scryptSync(pin, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}

export function verifyPin(pin: string, stored: string): boolean {
  const [salt, hash] = stored.split(':');
  if (!salt || !hash) return false;
  const candidate = scryptSync(pin, salt, 64);
  const expected = Buffer.from(hash, 'hex');
  if (candidate.length !== expected.length) return false;
  return timingSafeEqual(candidate, expected);
}
