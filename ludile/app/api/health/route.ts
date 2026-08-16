import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

// GET /api/health — seção 19. Nunca retorna dados sensíveis.
export async function GET() {
  const startedAt = Date.now();
  let database: 'ok' | 'error' = 'ok';

  try {
    const supabase = createClient();
    // Nunca deixa o healthcheck pendurado se o banco estiver inalcançável —
    // um endpoint de liveness precisa responder rápido mesmo quando degradado.
    const { error } = await supabase
      .from('worlds')
      .select('id')
      .limit(1)
      .abortSignal(AbortSignal.timeout(3000));
    if (error) database = 'error';
  } catch {
    database = 'error';
  }

  return NextResponse.json({
    status: database === 'ok' ? 'ok' : 'degraded',
    database,
    version: process.env.npm_package_version ?? '0.1.0',
    timestamp: new Date().toISOString(),
    latencyMs: Date.now() - startedAt,
  });
}
