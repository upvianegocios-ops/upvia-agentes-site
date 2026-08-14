const { chromium } = require('playwright');
const { extrairCard } = require('./extract');

// Busca um termo na Ad Library publica (sem login) e devolve so os anuncios
// clique-pra-WhatsApp encontrados. Reaproveita o browser entre chamadas (ver server.js).
async function buscarTermo(browser, termo, pais) {
  const context = await browser.newContext({ viewport: { width: 1280, height: 1400 } });
  const page = await context.newPage();
  try {
    const url = `https://www.facebook.com/ads/library/?active_status=active&ad_type=all&country=${encodeURIComponent(pais)}&q=${encodeURIComponent(termo)}`;
    await page.goto(url, { waitUntil: 'load', timeout: 30000 });
    await page.waitForTimeout(1500);
    const searchBox = page.locator('input[placeholder*="Pesquisar"], input[placeholder*="Search"]').first();
    if (await searchBox.count()) {
      await searchBox.click();
      await page.keyboard.press('Enter');
    }
    await page.waitForTimeout(6000);

    // extrai o texto de cada card (mesmo algoritmo validado manualmente: sobe do
    // marcador "Identificacao da biblioteca" ate achar um container do tamanho de card)
    const cardTexts = await page.evaluate(() => {
      const marks = [...document.querySelectorAll('*')].filter(el =>
        el.children.length === 0 && /Identifica[cç][aã]o da biblioteca/i.test(el.textContent || '')
      );
      const out = [];
      for (const mark of marks) {
        let node = mark;
        let card = null;
        for (let i = 0; i < 12 && node; i++) {
          node = node.parentElement;
          if (!node) break;
          const rect = node.getBoundingClientRect();
          if (rect.height > 150 && rect.height < 1000 && rect.width < 550) { card = node; break; }
        }
        if (card) out.push(card.innerText);
      }
      return out;
    });

    const cards = cardTexts.map(extrairCard).filter(Boolean);
    const ctwaCards = cards.filter(c => c.eh_ctwa);
    return { ok: true, termo, total_cards_lidos: cards.length, total_ctwa: ctwaCards.length, anuncios: ctwaCards };
  } catch (err) {
    return { ok: false, termo, erro: err.message, anuncios: [] };
  } finally {
    await context.close();
  }
}

module.exports = { buscarTermo };
