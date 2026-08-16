import type { Metadata, Viewport } from 'next';
import './globals.css';
import { RegisterServiceWorker } from './register-sw';

const APP_NAME = process.env.NEXT_PUBLIC_APP_NAME ?? 'Ludilê';

export const metadata: Metadata = {
  title: `${APP_NAME} — a aventura da alfabetização`,
  description:
    'Ferramenta educacional lúdica e acessível para apoiar a alfabetização infantil, com foco em acessibilidade para dislexia e TDAH.',
  manifest: '/manifest.json',
  robots: { index: false, follow: false }, // piloto privado, seção 27
  appleWebApp: { capable: true, statusBarStyle: 'default', title: APP_NAME },
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5, // nunca travar o zoom — acessibilidade
  themeColor: '#6c4fe0',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <body>
        {children}
        <RegisterServiceWorker />
      </body>
    </html>
  );
}
