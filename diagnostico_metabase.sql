-- DIAGNÓSTICO: Query para identificar diferencia en Metabase
-- Ejecuta esto directamente en Metabase (sin variables/filtros)

-- 1. CONTEO BÁSICO
SELECT
  'Conteo básico (5-11 ene)' as prueba,
  COUNT(*) AS resultado
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_name = 'Andrea Chávez'
  AND m.published_at::DATE BETWEEN '2026-01-05' AND '2026-01-11'

UNION ALL

-- 2. CON FILTRO DE TAG_TYPE (como Query 1)
SELECT
  'Con filtro tag_type=actor' as prueba,
  COUNT(*) AS resultado
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  AND t.tag_name = 'Andrea Chávez'
  AND m.published_at::DATE BETWEEN '2026-01-05' AND '2026-01-11'

UNION ALL

-- 3. VERIFICAR SI HAY DUPLICADOS EN MENTION_TAGS
SELECT
  'Ocurrencias con JOIN duplicado' as prueba,
  COUNT(*) AS resultado
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_name = 'Andrea Chávez'
  AND m.published_at BETWEEN '2026-01-05 00:00:00' AND '2026-01-11 23:59:59'

UNION ALL

-- 4. SIN MENTION_OCCURRENCES (solo mentions)
SELECT
  'Sin mention_occurrences' as prueba,
  COUNT(*) AS resultado
FROM mentions m
JOIN mention_tags mt ON mt.mention_id = m.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_name = 'Andrea Chávez'
  AND m.published_at::DATE BETWEEN '2026-01-05' AND '2026-01-11'

UNION ALL

-- 5. MENCIONES ÚNICAS (DISTINCT)
SELECT
  'Menciones ÚNICAS (DISTINCT)' as prueba,
  COUNT(DISTINCT m.mention_id) AS resultado
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_name = 'Andrea Chávez'
  AND m.published_at::DATE BETWEEN '2026-01-05' AND '2026-01-11'

ORDER BY prueba;
