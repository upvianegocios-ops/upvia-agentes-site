-- =====================================================================
-- Ludilê — Seed: Mundo 1 "Vila das Letras" (MVP, seção 21)
-- 10 letras · 20 atividades · 3 tipos de jogo · idempotente (ON CONFLICT)
-- =====================================================================

-- Skills trabalhadas no Mundo 1
insert into public.skills (code, name, category, order_index) values
  ('reconhecimento_letra', 'Reconhecimento de letras', 'fase_1_letras', 1),
  ('grafema_fonema', 'Associação letra-som', 'fase_2_letra_som', 2)
on conflict (code) do nothing;

-- Mundo 1
insert into public.worlds (code, name, description, icon, order_index, is_active) values
  ('vila_das_letras', 'Vila das Letras', 'Conhecendo as letras do alfabeto de um jeito divertido.', 'village', 1, true)
on conflict (code) do nothing;

-- Missões do Mundo 1 (uma por letra, 10 no total)
insert into public.missions (world_id, code, name, description, order_index, unlock_requirement, is_active)
select w.id, m.code, m.name, m.description, m.order_index, m.unlock_requirement::jsonb, true
from public.worlds w,
  (values
    ('missao_letra_a', 'A letra A', 'Vamos conhecer a letra A!', 1, '{}'),
    ('missao_letra_e', 'A letra E', 'Vamos conhecer a letra E!', 2, '{"previous": "missao_letra_a"}'),
    ('missao_letra_i', 'A letra I', 'Vamos conhecer a letra I!', 3, '{"previous": "missao_letra_e"}'),
    ('missao_letra_o', 'A letra O', 'Vamos conhecer a letra O!', 4, '{"previous": "missao_letra_i"}'),
    ('missao_letra_u', 'A letra U', 'Vamos conhecer a letra U!', 5, '{"previous": "missao_letra_o"}'),
    ('missao_letra_m', 'A letra M', 'Vamos conhecer a letra M!', 6, '{"previous": "missao_letra_u"}'),
    ('missao_letra_p', 'A letra P', 'Vamos conhecer a letra P!', 7, '{"previous": "missao_letra_m"}'),
    ('missao_letra_t', 'A letra T', 'Vamos conhecer a letra T!', 8, '{"previous": "missao_letra_p"}'),
    ('missao_letra_b', 'A letra B', 'Vamos conhecer a letra B!', 9, '{"previous": "missao_letra_t"}'),
    ('missao_letra_l', 'A letra L', 'Vamos conhecer a letra L!', 10, '{"previous": "missao_letra_b"}')
  ) as m(code, name, description, order_index, unlock_requirement)
where w.code = 'vila_das_letras'
on conflict (code) do nothing;

-- 20 atividades: 2 por letra (10 letras x 2), alternando entre os 3 tipos de jogo do MVP
-- (caca_letra, memoria, qual_e_o_som), dificuldade cresce levemente ao longo do mundo.
insert into public.activities (
  mission_id, skill_id, activity_type, difficulty, instruction, audio_url,
  question, options, correct_answer, hint, reward, order_index, is_active
)
select
  mis.id,
  (select id from public.skills where code = a.skill_code),
  a.activity_type,
  a.difficulty,
  a.instruction,
  a.audio_url,
  a.question::jsonb,
  a.options::jsonb,
  a.correct_answer::jsonb,
  a.hint,
  a.reward::jsonb,
  a.order_index,
  true
from (values
  -- Letra A
  ('missao_letra_a', 'reconhecimento_letra', 'caca_letra', 1, 'Encontre a letra A', '/audio/instructions/encontre_a_letra.mp3',
    '{"letter": "A"}', '["A","B","O","A","M","A"]', '{"positions": [0,3,5]}', 'Procure a letrinha redondinha com um risquinho no meio.', '{"xp":10,"coins":2}', 1),
  ('missao_letra_a', 'grafema_fonema', 'qual_e_o_som', 1, 'Ouça o som. Qual letra faz esse som?', '/audio/letters/a.mp3',
    '{"sound": "a"}', '["A","E","I"]', '{"answer": "A"}', 'Esse som é bem abert-a, como em "abacaxi".', '{"xp":10,"coins":2}', 2),
  -- Letra E
  ('missao_letra_e', 'reconhecimento_letra', 'caca_letra', 1, 'Encontre a letra E', '/audio/instructions/encontre_a_letra.mp3',
    '{"letter": "E"}', '["E","F","O","E","L","E"]', '{"positions": [0,3,5]}', 'Ela tem três tracinhos, como um pente.', '{"xp":10,"coins":2}', 1),
  ('missao_letra_e', 'grafema_fonema', 'qual_e_o_som', 1, 'Ouça o som. Qual letra faz esse som?', '/audio/letters/e.mp3',
    '{"sound": "e"}', '["A","E","I"]', '{"answer": "E"}', 'Pense na palavra "elefante".', '{"xp":10,"coins":2}', 2),
  -- Letra I
  ('missao_letra_i', 'reconhecimento_letra', 'memoria', 2, 'Encontre os pares da letra I', null,
    '{"letter": "I"}', '["I","I","O","O","U","U"]', '{"pairs": [["I","I"],["O","O"],["U","U"]]}', 'Procure duas cartas iguais de cada vez.', '{"xp":12,"coins":3}', 1),
  ('missao_letra_i', 'grafema_fonema', 'qual_e_o_som', 1, 'Ouça o som. Qual letra faz esse som?', '/audio/letters/i.mp3',
    '{"sound": "i"}', '["I","U","E"]', '{"answer": "I"}', 'Pense na palavra "igreja".', '{"xp":10,"coins":2}', 2),
  -- Letra O
  ('missao_letra_o', 'reconhecimento_letra', 'caca_letra', 1, 'Encontre a letra O', '/audio/instructions/encontre_a_letra.mp3',
    '{"letter": "O"}', '["O","Q","C","O","D","O"]', '{"positions": [0,3,5]}', 'Ela é bem redondinha, como uma bola.', '{"xp":10,"coins":2}', 1),
  ('missao_letra_o', 'grafema_fonema', 'qual_e_o_som', 1, 'Ouça o som. Qual letra faz esse som?', '/audio/letters/o.mp3',
    '{"sound": "o"}', '["O","U","A"]', '{"answer": "O"}', 'Pense na palavra "ovo".', '{"xp":10,"coins":2}', 2),
  -- Letra U
  ('missao_letra_u', 'reconhecimento_letra', 'memoria', 2, 'Encontre os pares da letra U', null,
    '{"letter": "U"}', '["U","U","A","A","E","E"]', '{"pairs": [["U","U"],["A","A"],["E","E"]]}', 'Procure duas cartas iguais de cada vez.', '{"xp":12,"coins":3}', 1),
  ('missao_letra_u', 'grafema_fonema', 'qual_e_o_som', 1, 'Ouça o som. Qual letra faz esse som?', '/audio/letters/u.mp3',
    '{"sound": "u"}', '["U","O","I"]', '{"answer": "U"}', 'Pense na palavra "uva".', '{"xp":10,"coins":2}', 2),
  -- Letra M
  ('missao_letra_m', 'reconhecimento_letra', 'caca_letra', 2, 'Encontre a letra M', '/audio/instructions/encontre_a_letra.mp3',
    '{"letter": "M"}', '["M","N","W","M","H","M"]', '{"positions": [0,3,5]}', 'Ela tem três perninhas, como montanhas.', '{"xp":12,"coins":3}', 1),
  ('missao_letra_m', 'grafema_fonema', 'qual_e_o_som', 2, 'Ouça o som. Qual letra faz esse som?', '/audio/letters/m.mp3',
    '{"sound": "m"}', '["M","N","P"]', '{"answer": "M"}', 'Pense na palavra "macaco".', '{"xp":12,"coins":3}', 2),
  -- Letra P
  ('missao_letra_p', 'reconhecimento_letra', 'caca_letra', 2, 'Encontre a letra P', '/audio/instructions/encontre_a_letra.mp3',
    '{"letter": "P"}', '["P","R","B","P","F","P"]', '{"positions": [0,3,5]}', 'Ela tem uma barriguinha só em cima.', '{"xp":12,"coins":3}', 1),
  ('missao_letra_p', 'grafema_fonema', 'qual_e_o_som', 2, 'Ouça o som. Qual letra faz esse som?', '/audio/letters/p.mp3',
    '{"sound": "p"}', '["P","B","T"]', '{"answer": "P"}', 'Pense na palavra "pato".', '{"xp":12,"coins":3}', 2),
  -- Letra T
  ('missao_letra_t', 'reconhecimento_letra', 'memoria', 2, 'Encontre os pares da letra T', null,
    '{"letter": "T"}', '["T","T","M","M","P","P"]', '{"pairs": [["T","T"],["M","M"],["P","P"]]}', 'Procure duas cartas iguais de cada vez.', '{"xp":13,"coins":3}', 1),
  ('missao_letra_t', 'grafema_fonema', 'qual_e_o_som', 2, 'Ouça o som. Qual letra faz esse som?', '/audio/letters/t.mp3',
    '{"sound": "t"}', '["T","D","P"]', '{"answer": "T"}', 'Pense na palavra "tato".', '{"xp":12,"coins":3}', 2),
  -- Letra B
  ('missao_letra_b', 'reconhecimento_letra', 'caca_letra', 3, 'Encontre a letra B', '/audio/instructions/encontre_a_letra.mp3',
    '{"letter": "B"}', '["B","D","R","B","P","B"]', '{"positions": [0,3,5]}', 'Ela tem duas barriguinhas.', '{"xp":14,"coins":3}', 1),
  ('missao_letra_b', 'grafema_fonema', 'qual_e_o_som', 3, 'Ouça o som. Qual letra faz esse som?', '/audio/letters/b.mp3',
    '{"sound": "b"}', '["B","P","D"]', '{"answer": "B"}', 'Pense na palavra "bola".', '{"xp":14,"coins":3}', 2),
  -- Letra L
  ('missao_letra_l', 'reconhecimento_letra', 'memoria', 3, 'Encontre os pares da letra L', null,
    '{"letter": "L"}', '["L","L","B","B","T","T"]', '{"pairs": [["L","L"],["B","B"],["T","T"]]}', 'Procure duas cartas iguais de cada vez.', '{"xp":15,"coins":4}', 1),
  ('missao_letra_l', 'grafema_fonema', 'qual_e_o_som', 3, 'Ouça o som. Qual letra faz esse som?', '/audio/letters/l.mp3',
    '{"sound": "l"}', '["L","T","N"]', '{"answer": "L"}', 'Pense na palavra "lua".', '{"xp":14,"coins":3}', 2)
) as a(mission_code, skill_code, activity_type, difficulty, instruction, audio_url, question, options, correct_answer, hint, reward, order_index)
join public.missions mis on mis.code = a.mission_code
on conflict do nothing;

-- Badge de conclusão do Mundo 1
insert into public.badges (code, name, description, icon_url, criteria) values
  ('vila_das_letras_completa', 'Explorador da Vila das Letras', 'Completou todas as missões da Vila das Letras!', '/icons/badge-vila-letras.svg',
   '{"world_code": "vila_das_letras", "all_missions_completed": true}')
on conflict (code) do nothing;

-- Recompensa cosmética inicial (chapéu do explorador)
insert into public.rewards (code, name, type, image_url, unlock_criteria) values
  ('chapeu_explorador', 'Chapéu do Explorador', 'avatar_item', '/icons/reward-chapeu.svg',
   '{"badge_code": "vila_das_letras_completa"}')
on conflict (code) do nothing;
