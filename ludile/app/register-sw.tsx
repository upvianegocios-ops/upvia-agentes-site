'use client';

import { useEffect } from 'react';

export function RegisterServiceWorker() {
  useEffect(() => {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(() => {
        // instalação do app continua funcionando online mesmo se o SW falhar
      });
    }
  }, []);

  return null;
}
