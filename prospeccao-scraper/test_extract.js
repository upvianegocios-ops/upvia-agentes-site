const { extrairCard } = require('./extract');

const exemplos = [
  {
    nome: 'Mercado Livre (nao CTWA)',
    texto: `​
Ativo
Identificação da biblioteca: 851035167690857
Veiculação iniciada em 19 de jun de 2026
Plataformas
​
​
Esse anúncio tem várias versões
​
Abrir menu suspenso
​
Ver detalhes do anúncio
Mercado Livre
Patrocinado
Entrega rápida e devolução grátis em até 30 dias. Compre no Mercado Livre hoje!
MERCADOLIVRE.COM.BR
Capa De Corte Cabelo Barbearia Profissional Nylon Kit Com 4
Compre produtos com Frete Grátis no mesmo dia no Mercado Livre Brasil. Encontre milhares de marcas e produtos a preços incríveis.
Shop Now`,
    esperado: { ctwa: false, id: '851035167690857', page: 'Mercado Livre' }
  },
  {
    nome: 'Barbearia Spazio (CTWA)',
    texto: `​
Ativo
Identificação da biblioteca: 899978355889516
Veiculação iniciada em 1 de ago de 2026
Plataformas
​
Abrir menu suspenso
​
Ver detalhes do anúncio
Barbearia Spazio
Patrocinado
Se você é barbeiro e quer aumentar o ticket médio da sua barbearia, chama a gente.
API.WHATSAPP.COM
Enviar mensagem pelo WhatsApp`,
    esperado: { ctwa: true, id: '899978355889516', page: 'Barbearia Spazio' }
  }
];

let pass = 0, fail = 0;
for (const ex of exemplos) {
  const r = extrairCard(ex.texto);
  const ok = r && r.ad_archive_id === ex.esperado.id && r.page_name === ex.esperado.page && r.eh_ctwa === ex.esperado.ctwa;
  console.log(ex.nome, '->', ok ? 'OK' : 'FALHOU', JSON.stringify(r));
  if (ok) pass++; else fail++;
}
console.log(`\n${pass} passaram, ${fail} falharam`);
process.exit(fail ? 1 : 0);
