// Extracao dos dados de cada card de anuncio a partir do texto renderizado da
// pagina publica da Ad Library (facebook.com/ads/library). Sem login.
//
// A pagina desativa de proposito os links de CTA reais (aria-disabled=true nos
// botoes), entao NAO da pra extrair telefone/link de destino por aqui -- so da
// pra confirmar que o anuncio E do tipo "clique-pra-whatsapp" (pelo texto do
// botao, que fica visivel) e pegar os dados publicos do anuncio em si.

const MESES = {
  jan: '01', fev: '02', mar: '03', abr: '04', mai: '05', jun: '06',
  jul: '07', ago: '08', set: '09', out: '10', nov: '11', dez: '12'
};

function parseDataBr(raw) {
  // "19 de jun de 2026" -> "2026-06-19"
  if (!raw) return null;
  const m = raw.match(/(\d{1,2})\s+de\s+([a-zç]{3})[a-zç]*\s+de\s+(\d{4})/i);
  if (!m) return null;
  const [, dia, mesAbrev, ano] = m;
  const mes = MESES[mesAbrev.toLowerCase().slice(0, 3)];
  if (!mes) return null;
  return `${ano}-${mes}-${dia.padStart(2, '0')}`;
}

function ehAnuncioWhatsapp(cardText) {
  return /Enviar mensagem pelo WhatsApp/i.test(cardText)
    || /Send WhatsApp Message/i.test(cardText)
    || /API\.WHATSAPP\.COM/i.test(cardText);
}

function extrairCard(cardText) {
  const lines = cardText.split('\n').map(l => l.trim()).filter(l => l && l !== '​');

  const idMatch = cardText.match(/Identifica[cç][aã]o da biblioteca:\s*(\d+)/i);
  const dataMatch = cardText.match(/Veicula[cç][aã]o iniciada em\s*([^\n]+)/i);

  const idxVerDetalhes = lines.findIndex(l => /^Ver (detalhes|resumo)/i.test(l));
  const page_name = idxVerDetalhes >= 0 && lines[idxVerDetalhes + 1] ? lines[idxVerDetalhes + 1] : null;

  const idxPatrocinado = lines.findIndex(l => /^Patrocinado$/i.test(l));
  const bodyLines = idxPatrocinado >= 0 ? lines.slice(idxPatrocinado + 1) : [];
  // a ultima linha costuma ser o texto do botao de CTA -- tira ela do corpo do anuncio
  const ctaCandidatas = ['Shop Now', 'Saiba mais', 'Learn More', 'Cadastre-se', 'Install Now',
    'Enviar mensagem pelo WhatsApp', 'Send WhatsApp Message', 'AGENDAR AGORA'];
  const ultimaLinha = bodyLines[bodyLines.length - 1];
  const semCta = ctaCandidatas.some(c => ultimaLinha === c) ? bodyLines.slice(0, -1) : bodyLines;
  // remove linhas que sao so o dominio de destino em maiusculas (ex: "API.WHATSAPP.COM",
  // "MERCADOLIVRE.COM.BR") -- nao fazem parte do texto do anuncio em si.
  const corpo = semCta.filter(l => !/^[A-Z0-9.\-]+\.[A-Z]{2,}$/.test(l));

  if (!idMatch || !page_name) return null; // card nao reconhecido, ignora (defensivo)

  return {
    ad_archive_id: idMatch[1],
    page_name,
    ad_creative_body: corpo.join(' ').slice(0, 2000),
    ad_delivery_start_time: parseDataBr(dataMatch ? dataMatch[1] : null),
    ad_snapshot_url: `https://www.facebook.com/ads/library/?id=${idMatch[1]}`,
    eh_ctwa: ehAnuncioWhatsapp(cardText)
  };
}

module.exports = { extrairCard, ehAnuncioWhatsapp, parseDataBr };
