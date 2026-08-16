import { describe, expect, it } from 'vitest';
import { hashPin, verifyPin } from '@/lib/pin';

describe('PIN da área dos responsáveis', () => {
  it('verifica corretamente um PIN válido', () => {
    const stored = hashPin('1234');
    expect(verifyPin('1234', stored)).toBe(true);
  });

  it('rejeita um PIN incorreto', () => {
    const stored = hashPin('1234');
    expect(verifyPin('0000', stored)).toBe(false);
  });

  it('nunca guarda o PIN em texto puro', () => {
    const stored = hashPin('1234');
    expect(stored).not.toContain('1234');
  });

  it('gera hashes diferentes para o mesmo PIN (salt aleatório)', () => {
    expect(hashPin('1234')).not.toBe(hashPin('1234'));
  });
});
