$path = 'C:\Users\isaqu\OneDrive\Área de Trabalho\upvia-agentes\index.html'
$c = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$orig = $c.Length

# ── 1. plan-btn Essencial (light) ─────────────────────────────────────────────
$c = $c.Replace(
    'onclick="irParaCheckout(&#39;light&#39;)">Começar meu teste gratuito →</button>',
    'onclick="window.location.href=''conectar-whatsapp.html?plano=essencial''">Começar meu teste gratuito →</button>'
)

# ── 2. plan-btn Pro ───────────────────────────────────────────────────────────
$c = $c.Replace(
    'onclick="irParaCheckout(&#39;pro&#39;)">Quero testar sem compromisso →</button>',
    'onclick="window.location.href=''conectar-whatsapp.html?plano=pro''">Quero testar sem compromisso →</button>'
)

# ── 3. plan-btn Premium ───────────────────────────────────────────────────────
$c = $c.Replace(
    'onclick="irParaCheckout(&#39;premium&#39;)">Começar meu teste gratuito →</button>',
    'onclick="window.location.href=''conectar-whatsapp.html?plano=premium''">Começar meu teste gratuito →</button>'
)

# ── 4. co-btn Essencial (contexto único: "Relatório diário") ──────────────────
$c = [regex]::Replace($c,
    '(<li>Relatório diário</li>\s*</ul>\s*)<button class="co-btn">',
    '$1<button class="co-btn" onclick="window.location.href=''conectar-whatsapp.html?plano=essencial''">')

# ── 5. co-btn Pro (contexto único: "Disparo de promoções") ───────────────────
$c = [regex]::Replace($c,
    '(<li>Disparo de promoções</li>\s*</ul>\s*)<button class="co-btn">',
    '$1<button class="co-btn" onclick="window.location.href=''conectar-whatsapp.html?plano=pro''">')

# ── 6. co-btn Premium (contexto único: "Upsell automático") ──────────────────
$c = [regex]::Replace($c,
    '(<li>Upsell automático</li>\s*</ul>\s*)<button class="co-btn">',
    '$1<button class="co-btn" onclick="window.location.href=''conectar-whatsapp.html?plano=premium''">')

# ── 7. Remover botão "Cadastro do vendedor" ───────────────────────────────────
$c = $c.Replace(
    '<button class="seller-link" style="margin-top:12px" onclick="irParaCadastro(&#39;vendedor&#39;)">Cadastro do vendedor</button>',
    ''
)

[System.IO.File]::WriteAllText($path, $c, [System.Text.Encoding]::UTF8)
"Alterações aplicadas. Tamanho original: $orig | Novo: $($c.Length) | Diff: $($c.Length - $orig)"
