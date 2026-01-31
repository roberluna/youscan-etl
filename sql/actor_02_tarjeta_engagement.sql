-- =====================================================
-- Dashboard por Actor - Query 2
-- TARJETA: Total de Engagement
-- Visualización: Número grande (tarjeta/métrica)
-- =====================================================

SELECT
  SUM(COALESCE(me.engagement, 0)) AS total_engagement
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
LEFT JOIN metrics me ON me.mention_id = o.mention_id
WHERE t.tag_type = 'actor'
  [[AND t.tag_name = {{actor}}]]
  [[AND {{fecha}}]]
  [[AND {{source_name}}]];

-- =====================================================
-- Configuración en Metabase:
-- =====================================================
-- Variables OPCIONALES (usar sintaxis [[ ]]):
--   {{actor}}         = Field Filter → tags.tag_name (String/Dropdown)
--   {{fecha}}         = Field Filter → mentions.published_at (Date Range)
--   {{source_name}}   = Field Filter → mentions.source_name (String)
--
-- IMPORTANTE: Los 3 filtros son opcionales. Si no se selecciona actor,
--             mostrará el total de todos los actores.
--
-- NOTA: Usa LEFT JOIN con metrics para incluir menciones sin engagement
--       (tratadas como 0).
--
-- Visualización:
--   Tipo: Número (Number/Scalar)
--   Display: Número grande con separador de miles
--   Título: "Total de Engagement"
--   Formato: 123,456
--
-- Uso en Dashboard:
--   - Colocar como tarjeta junto a "Total de Menciones"
--   - Conectar a filtros globales: actor, fecha, source_name
-- =====================================================
