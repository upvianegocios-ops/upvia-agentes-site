'use client';

// Fallback obrigatório de áudio (seção 15): a Web SpeechSynthesis API do
// navegador funciona sem nenhuma integração externa. TTS externo (opcional)
// entra depois, desacoplado, sem bloquear o app quando ausente.

export interface SpeakOptions {
  rate?: number; // velocidade configurável (seção 6)
  pitch?: number;
  onEnd?: () => void;
}

export function isSpeechSynthesisAvailable(): boolean {
  return typeof window !== 'undefined' && 'speechSynthesis' in window;
}

export function speak(text: string, options: SpeakOptions = {}): void {
  if (!isSpeechSynthesisAvailable()) return;

  window.speechSynthesis.cancel(); // não empilha falas — sempre a mais recente
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = 'pt-BR';
  utterance.rate = options.rate ?? 0.95;
  utterance.pitch = options.pitch ?? 1.1;
  if (options.onEnd) utterance.onend = options.onEnd;

  window.speechSynthesis.speak(utterance);
}

export function stopSpeaking(): void {
  if (isSpeechSynthesisAvailable()) {
    window.speechSynthesis.cancel();
  }
}

/**
 * Toca um áudio pré-gravado (storage) se existir; senão usa o fallback de
 * SpeechSynthesis com o texto informado. Nunca deixa a instrução muda.
 */
export function playInstruction(audioUrl: string | null, fallbackText: string, rate = 0.95): void {
  if (audioUrl) {
    const audio = new Audio(audioUrl);
    audio.onerror = () => speak(fallbackText, { rate });
    audio.play().catch(() => speak(fallbackText, { rate }));
    return;
  }
  speak(fallbackText, { rate });
}
