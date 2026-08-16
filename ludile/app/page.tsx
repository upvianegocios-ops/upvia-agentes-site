import Link from 'next/link';
import { GameButton } from '@/components/ui/GameButton';

const APP_NAME = process.env.NEXT_PUBLIC_APP_NAME ?? 'Ludilê';

export default function HomePage() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center gap-8 p-6 text-center">
      <div>
        <p className="text-6xl mb-2" aria-hidden="true">
          📖✨
        </p>
        <h1 className="text-4xl font-extrabold text-ludile-primary">{APP_NAME}</h1>
        <p className="text-child-base text-slate-600 mt-2">A aventura de aprender a ler!</p>
      </div>
      <div className="flex flex-col gap-4 w-full max-w-xs">
        <Link href="/login">
          <GameButton className="w-full">Entrar</GameButton>
        </Link>
        <Link href="/cadastro">
          <GameButton variant="secondary" className="w-full">
            Criar conta da família
          </GameButton>
        </Link>
      </div>
    </main>
  );
}
