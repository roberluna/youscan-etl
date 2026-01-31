-- Query para revisar TODAS las menciones positivas de Daniela Álvarez
-- Periodo: 5-11 enero 2026

SELECT
  o.occurrence_id,
  m.mention_id,
  m.published_at,
  m.sentiment,
  m.source_name,
  m.title,
  LEFT(m.body_text, 150) as body_preview,
  m.url
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  AND t.tag_name = 'Daniela Álvarez'
  AND m.published_at::DATE >= '2026-01-05'
  AND m.published_at::DATE <= '2026-01-11'
  AND m.sentiment = 'Positivo'
ORDER BY m.published_at;

-- RESUMEN: Conteo de menciones positivas
-- Total esperado: 231 ocurrencias (181 menciones únicas)
