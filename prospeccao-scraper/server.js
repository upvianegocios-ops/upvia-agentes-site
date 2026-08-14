const express = require('express');
const { chromium } = require('playwright');
const { buscarTermo } = require('./buscar');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3500;
const AUTH_TOKEN = process.env.SCRAPER_TOKEN || null; // opcional, ver README

function checarToken(req, res, next) {
  if (!AUTH_TOKEN) return next(); // sem token configurado = sem checagem (uso interno na mesma rede)
  if (req.get('x-scraper-token') !== AUTH_TOKEN) return res.status(401).json({ erro: 'token invalido' });
  next();
}

app.get('/health', (req, res) => res.json({ ok: true }));

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const delayAleatorio = (minMs, maxMs) => sleep(minMs + Math.random() * (maxMs - minMs));

// POST /buscar { termos: string[], pais?: string }
// Devolve { ok, resultados: [{ termo, anuncios: [...] }] }
app.post('/buscar', checarToken, async (req, res) => {
  const termos = Array.isArray(req.body.termos) ? req.body.termos : [];
  const pais = req.body.pais || 'BR';
  if (!termos.length) return res.status(400).json({ erro: 'informe "termos" (array de strings)' });

  let browser;
  try {
    browser = await chromium.launch({ args: ['--no-sandbox'] });
    const resultados = [];
    for (let i = 0; i < termos.length; i++) {
      // atraso aleatorio entre buscas pra nao bater na Ad Library num padrao
      // obviamente automatizado (rajada de requests identicas de um so IP) --
      // confirmado em producao que isso derruba os resultados a zero depois de
      // ~20-30 buscas seguidas em poucos minutos.
      if (i > 0) await delayAleatorio(3000, 7000);
      const r = await buscarTermo(browser, termos[i], pais);
      resultados.push(r);
    }
    res.json({ ok: true, resultados });
  } catch (err) {
    res.status(500).json({ ok: false, erro: err.message });
  } finally {
    if (browser) await browser.close();
  }
});

app.listen(PORT, () => console.log(`prospeccao-scraper ouvindo na porta ${PORT}`));
