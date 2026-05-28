import sys, re
sys.stdout.reconfigure(encoding='utf-8')

filepath = r"C:\Users\isaqu\OneDrive\Área de Trabalho\upvia-agentes\projeto site upvia\site_upvia_CORRIGIDO_6.html"

with open(filepath, 'r', encoding='utf-8') as f:
    html = f.read()

changes = []

def replace(old, new, label, html, count=1):
    if old in html:
        if count == 0:
            result = html.replace(old, new)
        else:
            result = html.replace(old, new, count)
        changes.append(f"OK: {label}")
        return result
    else:
        changes.append(f"MISS: {label}")
        return html

# ═══════════════════════════════════════════════════════════
# 1. HERO — H1
# ═══════════════════════════════════════════════════════════
html = replace(
    '<h1>Pare de perder clientes<br>por <span>não conseguir responder</span> a tempo.</h1>',
    '<h1>Sua Atendente Virtual que agenda clientes 24h por dia –<br><span>Pare de perder vendas pelo WhatsApp.</span></h1>',
    'Hero H1', html
)

# ═══════════════════════════════════════════════════════════
# 2. HERO — subtítulo
# ═══════════════════════════════════════════════════════════
html = replace(
    '<p>Sua atendente virtual trabalha 24 horas por dia: responde clientes, agenda horários, envia lembretes e ainda traz de volta quem sumiu. Tudo pelo WhatsApp.</p>',
    '<p>Recupere o controle da sua agenda e pare de perder clientes por falta de resposta. Uma secretária inteligente que nunca dorme e transforma conversas em agendamentos reais.</p>',
    'Hero subtítulo', html
)

# ═══════════════════════════════════════════════════════════
# 3. HERO — CTA primário
# ═══════════════════════════════════════════════════════════
html = replace(
    '<button class="btn-primary" onclick="irParaCheckout()">Teste 7 dias grátis →</button>',
    '<button class="btn-primary" onclick="irParaCheckout()">Quero testar sem compromisso →</button>',
    'Hero CTA primário', html
)

# ═══════════════════════════════════════════════════════════
# 4. HERO — badge
# ═══════════════════════════════════════════════════════════
html = replace(
    '<div class="hero-badge"><span class="dot"></span>Teste 7 dias grátis — sem compromisso</div>',
    '<div class="hero-badge"><span class="dot"></span>7 dias gratuitos — sem cartão, sem contrato, sem surpresa</div>',
    'Hero badge', html
)

# ═══════════════════════════════════════════════════════════
# 5. NAV — CTA
# ═══════════════════════════════════════════════════════════
html = replace(
    '>Teste 7 dias grátis<',
    '>Começar meu teste gratuito<',
    'Nav CTA', html
)

# ═══════════════════════════════════════════════════════════
# 6. SEÇÃO BENEFÍCIOS — substituir os 6 superpoderes técnicos
#    por "O que a UpvIA faz pelo seu lucro"
# ═══════════════════════════════════════════════════════════
OLD_BENEFICIOS = '''<div class="section-tag reveal">A Solução</div>
<h2 class="section-title reveal">6 superpoderes que a sua <span class="accent">Atendente IA</span> tem</h2>
<div class="grid3" style="grid-template-columns:repeat(auto-fit,minmax(340px,1fr))">
<div class="card reveal"><div class="benefit-num">01</div><h3>Atendimento humanizado 24h</h3><p>Nunca mais deixe seu cliente esperando. A IA responde em segundos, a qualquer hora, com personalidade e empatia.</p></div>
<div class="card reveal"><div class="benefit-num">02</div><h3>Agendamento inteligente</h3><p>Consulta sua agenda, oferece horários, faz agendamentos, cancelamentos e remarcações — tudo automaticamente.</p></div>
<div class="card reveal"><div class="benefit-num">03</div><h3>Follow-up que traz clientes de volta</h3><p>Quando um cliente some, a IA detecta e envia mensagens para trazê-lo de volta no momento certo.</p></div>
<div class="card reveal"><div class="benefit-num">04</div><h3>Relatório diário no WhatsApp</h3><p>Todo dia você recebe a agenda do dia seguinte. Sabe exatamente quem vem e qual serviço — sem abrir nenhum app.</p></div>
<div class="card reveal"><div class="benefit-num">05</div><h3>Comandos direto no WhatsApp</h3><p>Promoções, agendamentos, cancelamentos — manda um comando no seu WhatsApp e a IA executa na hora.</p></div>
<div class="card reveal"><div class="benefit-num">06</div><h3>Lembrete automático — zero furo</h3><p>2 horas antes de cada horário a IA lembra o cliente. Resultado: até 80% menos faltas na sua agenda.</p></div>
</div>'''

NEW_BENEFICIOS = '''<div class="section-tag reveal">O que a UpvIA faz pelo seu lucro</div>
<h2 class="section-title reveal">Chega de perder dinheiro por <span class="accent">falta de resposta</span></h2>
<p class="section-desc reveal" style="max-width:600px;margin:0 auto 48px">Menos de 10% do custo de uma funcionária humana — com 100% de disponibilidade, todos os dias, o ano inteiro.</p>
<div class="grid3" style="grid-template-columns:repeat(auto-fit,minmax(260px,1fr))">
<div class="card reveal">
<div class="benefit-num">01</div>
<h3>Recuperação de Leads</h3>
<p>Não perca mais clientes que entram em contato fora do horário comercial. A IA atende em segundos, 24h por dia — enquanto você descansa, sua agenda se preenche.</p>
</div>
<div class="card reveal">
<div class="benefit-num">02</div>
<h3>Redução de Furos na Agenda</h3>
<p>Lembretes automáticos que reduzem o absenteísmo em até 40%. Cada furo evitado é dinheiro real de volta no seu bolso.</p>
</div>
<div class="card reveal">
<div class="benefit-num">03</div>
<h3>Atendimento Instantâneo</h3>
<p>Respostas em milissegundos, 24/7, com o tom de voz do seu negócio. Seu cliente sente que está falando com uma secretária treinada — porque está.</p>
</div>
<div class="card reveal">
<div class="benefit-num">04</div>
<h3>Follow-up Inteligente</h3>
<p>Recupere clientes que pararam de responder. A IA retoma o contato de forma natural e no momento certo — sem parecer insistente, só oportuno.</p>
</div>
</div>'''

html = replace(OLD_BENEFICIOS, NEW_BENEFICIOS, 'Seção benefícios', html)

# ═══════════════════════════════════════════════════════════
# 7. SEÇÃO PLANOS — substituir bloco completo
# ═══════════════════════════════════════════════════════════
OLD_PLANOS = '''<section id="planos">
<div class="sec-inner" style="text-align:center">
<div class="section-tag reveal">Planos</div>
<h2 class="section-title reveal">Automação com tecnologia de ponta e <span class="accent">custo acessível</span></h2>
<p class="section-desc reveal" style="max-width:580px;margin:0 auto 48px">A diferença entre os planos é quantas agendas a IA gerencia.</p>
<div class="pricing-grid">

<div class="plan reveal">
<div class="plan-emoji">⚡</div><div class="plan-name">Light</div><div class="plan-profis">Até 1 agenda</div>
<div class="plan-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 250</div><div class="per">/mês</div></div>
<div class="plan-adesao">Sem taxa de adesão</div><div class="plan-adesao-info">Comece sem investimento inicial</div>
<ul class="plan-features">
<li>Atendimento automático 24h</li>
<li>Agendamento, remarcação e cancelamento</li>
<li>Lembrete 2h antes do atendimento</li>
<li>Relatório diário da agenda</li>
</ul>
<button class="plan-btn pri" onclick="irParaCheckout(\'light\')">Teste 7 dias grátis →</button>
</div>

<div class="plan feat reveal">
<div class="plan-emoji">🚀</div><div class="plan-name">Pro</div><div class="plan-profis">Até 5 agendas</div>
<div class="plan-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 400</div><div class="per">/mês</div></div>
<div class="plan-adesao">Adesão: R$ 700</div><div class="plan-adesao-info">Taxa única de implementação, configuração e hospedagem</div>
<ul class="plan-features">
<li>Tudo do Light</li>
<li>Até 5 agendas independentes</li>
<li>Disparo em massa para promoções</li>
</ul>
<button class="plan-btn pri" onclick="irParaCheckout(\'pro\')">Escolher Pro →</button>
</div>

<div class="plan reveal">
<div class="plan-emoji">👑</div><div class="plan-name">Premium</div><div class="plan-profis">Até 10 agendas</div>
<div class="plan-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 750</div><div class="per">/mês</div></div>
<div class="plan-adesao">Adesão: R$ 1.000</div><div class="plan-adesao-info">Taxa única de implementação, configuração e hospedagem</div>
<ul class="plan-features">
<li>Tudo do Pro</li>
<li>Até 10 agendas independentes</li>
<li>CRM com qualificação de leads</li>
<li>Follow-up inteligente (recupera clientes)</li>
<li>Upsell de vendas (mais faturamento)</li>
</ul>
<button class="plan-btn pri" onclick="irParaCheckout(\'premium\')">Escolher Premium →</button>
</div>

</div>
<p style="margin-top:20px;font-size:14px;color:#555">Teste 7 dias grátis em qualquer plano — cancele quando quiser.</p>
<button class="seller-link" style="margin-top:12px" onclick="irParaCadastro(\'vendedor\')">Cadastro do vendedor</button>
</div>
</section>'''

NEW_PLANOS = '''<section id="planos">
<div class="sec-inner" style="text-align:center">
<div class="section-tag reveal">Planos</div>
<h2 class="section-title reveal">Invista no crescimento — <span class="accent">sem contratos e sem surpresas</span></h2>

<div class="card reveal" style="max-width:720px;margin:0 auto 48px;background:linear-gradient(135deg,rgba(0,210,255,0.06),rgba(108,92,231,0.08));border:1px solid rgba(0,210,255,0.2);padding:28px 32px;text-align:left">
<div style="font-size:20px;font-weight:700;color:#00D2FF;margin-bottom:10px">✅ Teste antes de pagar</div>
<p style="font-size:16px;color:#CCCCDD;line-height:1.7;margin:0">Você testa por <strong>7 dias sem compromisso</strong>. Só realiza o pagamento se a automação realmente transformar o seu fluxo de atendimento. <span style="color:#A29BFE;font-weight:600">Sem contratos, sem letras miúdas, sem cobrança antecipada.</span></p>
</div>

<div class="pricing-grid">

<div class="plan reveal">
<div class="plan-emoji">⚡</div><div class="plan-name">Essencial</div>
<div class="plan-profis">Ideal para quem está começando</div>
<div class="plan-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 297</div><div class="per">/mês</div></div>
<ul class="plan-features">
<li>Atendimento automático 24h</li>
<li>Agendamento, remarcação e cancelamento</li>
<li>Lembretes automáticos — até 40% menos furos</li>
<li>Relatório diário da agenda no WhatsApp</li>
</ul>
<button class="plan-btn pri" onclick="irParaCheckout(\'light\')">Começar meu teste gratuito →</button>
</div>

<div class="plan feat reveal">
<div class="plan-emoji">🚀</div><div class="plan-name">Pro</div>
<div class="plan-profis">O mais escolhido — Follow-up e promoções</div>
<div class="plan-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 497</div><div class="per">/mês</div></div>
<ul class="plan-features">
<li>Tudo do Essencial</li>
<li>Follow-up inteligente que recupera clientes</li>
<li>Disparo de promoções para toda a base</li>
<li>Respostas com tom de voz do seu negócio</li>
</ul>
<button class="plan-btn pri" onclick="irParaCheckout(\'pro\')">Quero testar sem compromisso →</button>
</div>

<div class="plan reveal">
<div class="plan-emoji">👑</div><div class="plan-name">Premium</div>
<div class="plan-profis">Escala total — CRM e Upsell automático</div>
<div class="plan-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 797</div><div class="per">/mês</div></div>
<ul class="plan-features">
<li>Tudo do Pro</li>
<li>CRM integrado com qualificação de leads</li>
<li>Upsell automático — mais faturamento por cliente</li>
<li>Atendimento multiagenda ilimitado</li>
</ul>
<button class="plan-btn pri" onclick="irParaCheckout(\'premium\')">Escalar meu negócio →</button>
</div>

</div>
<p style="margin-top:24px;font-size:14px;color:#555">Cancele quando quiser, sem multa e sem burocracia.</p>
<button class="seller-link" style="margin-top:12px" onclick="irParaCadastro(\'vendedor\')">Cadastro do vendedor</button>
</div>
</section>'''

html = replace(OLD_PLANOS, NEW_PLANOS, 'Seção planos', html)

# ═══════════════════════════════════════════════════════════
# 8. CHECKOUT — remover taxas de adesão do page-checkout
# ═══════════════════════════════════════════════════════════
html = replace(
    "Adesão: R$ 700",
    "Sem taxa de adesão",
    'Checkout adesão Pro', html
)
html = replace(
    "Adesão: R$ 1.000",
    "Sem taxa de adesão",
    'Checkout adesão Premium', html
)
# Remover info de taxa de adesão no checkout
html = replace(
    "Taxa única de implementação, configuração e hospedagem",
    "Comece gratuitamente por 7 dias",
    'Checkout adesão info', html, count=0
)

# ═══════════════════════════════════════════════════════════
# 9. CHECKOUT — atualizar preços no page-checkout
# ═══════════════════════════════════════════════════════════
# co-adesao + amt price in checkout
html = replace(
    '<div class="co-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 250</div>',
    '<div class="co-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 297</div>',
    'Checkout preço Light', html
)
html = replace(
    '<div class="co-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 400</div>',
    '<div class="co-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 497</div>',
    'Checkout preço Pro', html
)
html = replace(
    '<div class="co-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 750</div>',
    '<div class="co-price"><div class="lbl">Mensalidade</div><div class="amt">R$ 797</div>',
    'Checkout preço Premium', html
)

# ═══════════════════════════════════════════════════════════
# 10. CTA "Quero minha Atendente" e outros genéricos → foco em conversão
# ═══════════════════════════════════════════════════════════
html = replace(
    '>Quero minha Atendente →<',
    '>Quero testar sem compromisso →<',
    'CTA Quero Atendente', html
)
# Botões "Começar teste grátis" (fora do checkout/cadastro)
html = replace(
    '>Começar teste grátis →<',
    '>Quero testar sem compromisso →<',
    'CTA Começar teste grátis', html, count=0
)

# ═══════════════════════════════════════════════════════════
# 11. Modal de planos — atualizar nomes e preços
# ═══════════════════════════════════════════════════════════
html = replace(
    '>⚡ Light — R$ 250/mês<',
    '>⚡ Essencial — R$ 297/mês<',
    'Modal plano Light', html
)
html = replace(
    '>🚀 Pro — R$ 400/mês<',
    '>🚀 Pro — R$ 497/mês<',
    'Modal plano Pro', html
)
html = replace(
    '>👑 Premium — R$ 750/mês<',
    '>👑 Premium — R$ 797/mês<',
    'Modal plano Premium', html
)

# ═══════════════════════════════════════════════════════════
# 12. Cadastro wizard — plano cards com preços
# ═══════════════════════════════════════════════════════════
html = replace('R$ 250<', 'R$ 297<', 'Wizard Light preço', html, count=0)
html = replace('R$ 400<', 'R$ 497<', 'Wizard Pro preço', html, count=0)
html = replace('R$ 750<', 'R$ 797<', 'Wizard Premium preço', html, count=0)

# ═══════════════════════════════════════════════════════════
# 13. SEÇÃO PROBLEMA — adicionar linha de "custo comparativo"
#     após o grid de cards do problema
# ═══════════════════════════════════════════════════════════
OLD_PROB_END = '''</div>
</div>
</section>

<section id="beneficios"'''

NEW_PROB_END = '''</div>
<div class="card reveal" style="max-width:680px;margin:48px auto 0;background:linear-gradient(135deg,rgba(108,92,231,0.08),rgba(0,210,255,0.05));border:1px solid rgba(162,155,254,0.2);padding:24px 32px;text-align:center">
<p style="font-size:18px;font-weight:600;color:#E8E8F0;line-height:1.6">A UpvIA custa <span style="color:#00D2FF;font-weight:800">menos de 10% do salário</span> de uma recepcionista — e atende <span style="color:#A29BFE;font-weight:800">24h por dia, 7 dias por semana, 365 dias por ano.</span></p>
</div>
</div>
</section>

<section id="beneficios"'''

html = replace(OLD_PROB_END, NEW_PROB_END, 'Linha custo comparativo', html)

# ═══════════════════════════════════════════════════════════
# 14. DEPOIMENTOS — área comentada antes do FAQ
# ═══════════════════════════════════════════════════════════
OLD_FAQ = '<section id="faq" style="background:linear-gradient(180deg,#07070D,#0A0A14)">'

NEW_FAQ = '''<!--
═══════════════════════════════════════════════════════
DEPOIMENTOS — Inserir quando tiver clientes reais
Para ativar: remova os comentários <!-- e -->
═══════════════════════════════════════════════════════

<section id="depoimentos" style="background:linear-gradient(180deg,#0A0A14,#07070D)">
<div class="sec-inner" style="text-align:center">
<div class="section-tag">Clientes reais, resultados reais</div>
<h2 class="section-title">O que dizem os nossos <span class="accent">primeiros clientes</span></h2>
<div class="grid3" style="margin-top:48px">

<div class="card">
<div style="font-size:24px;color:#F0C040;margin-bottom:12px">★★★★★</div>
<p style="font-style:italic;color:#CCCCDD;margin-bottom:16px">"DEPOIMENTO REAL DO CLIENTE AQUI"</p>
<div style="font-weight:700">Nome do Cliente</div>
<div style="font-size:13px;color:#8888AA">Tipo de negócio — Cidade</div>
</div>

<div class="card">
<div style="font-size:24px;color:#F0C040;margin-bottom:12px">★★★★★</div>
<p style="font-style:italic;color:#CCCCDD;margin-bottom:16px">"DEPOIMENTO REAL DO CLIENTE AQUI"</p>
<div style="font-weight:700">Nome do Cliente</div>
<div style="font-size:13px;color:#8888AA">Tipo de negócio — Cidade</div>
</div>

<div class="card">
<div style="font-size:24px;color:#F0C040;margin-bottom:12px">★★★★★</div>
<p style="font-style:italic;color:#CCCCDD;margin-bottom:16px">"DEPOIMENTO REAL DO CLIENTE AQUI"</p>
<div style="font-weight:700">Nome do Cliente</div>
<div style="font-size:13px;color:#8888AA">Tipo de negócio — Cidade</div>
</div>

</div>
</div>
</section>
-->

<section id="faq" style="background:linear-gradient(180deg,#07070D,#0A0A14)">'''

html = replace(OLD_FAQ, NEW_FAQ, 'Área depoimentos (comentada)', html)

# ═══════════════════════════════════════════════════════════
# 15. Qualquer menção restante a "Taxa de Adesão" / "taxa de adesão"
# ═══════════════════════════════════════════════════════════
html = re.sub(r'[Tt]axa de [Aa]des[aã]o[^<"]{0,60}', '', html)
html = re.sub(r'Ades[aã]o: R\$[\s\d\.]+', '', html)
changes.append("OK: Limpeza geral Taxa de Adesão")

# ═══════════════════════════════════════════════════════════
# SALVAR
# ═══════════════════════════════════════════════════════════
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(html)

print("=== RESULTADO ===")
for c in changes:
    print(c)

print(f"\nArquivo salvo: {len(html):,} bytes")
