import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Paleta padrão do Ludilê — cada organization pode sobrescrever via
        // CSS custom properties (branding), nunca via novo build (seção 13b).
        ludile: {
          primary: 'var(--ludile-primary, #6C4FE0)',
          secondary: 'var(--ludile-secondary, #FFC93C)',
          success: '#3CCB7F',
          error: '#FF6B6B',
          bg: '#FFF9F0',
        },
      },
      fontSize: {
        'child-base': ['1.25rem', { lineHeight: '1.8' }],
        'child-lg': ['1.75rem', { lineHeight: '1.6' }],
      },
      borderRadius: {
        xl2: '1.5rem',
      },
    },
  },
  plugins: [],
};

export default config;
