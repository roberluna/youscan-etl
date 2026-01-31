-- =====================================================
-- MVP Dashboard - Gráfica 3
-- Engagement TOTAL por Actor
-- Visualización: Gráfico de barras horizontal
-- =====================================================

SELECT
  t.tag_name AS actor,
  SUM(COALESCE(me.engagement, 0)) AS total_engagement
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
LEFT JOIN metrics me ON me.mention_id = m.mention_id  -- LEFT JOIN crítico!
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  [[AND {{fecha}}]]
  [[AND {{source_name}}]]
GROUP BY t.tag_name
ORDER BY total_engagement DESC;

-- =====================================================
-- Configuración en Metabase:
-- =====================================================
-- Variables OPCIONALES (usar sintaxis [[ ]]):
--   {{fecha}}         = Field Filter → mentions.published_at (Date Range)
--   {{source_name}}   = Field Filter → mentions.source_name (String)
--
-- IMPORTANTE: Ambos filtros son opcionales. Si no se selecciona valor,
--             se mostrarán todos los datos sin filtrar.
--
-- Visualización:
--   Tipo: Barra horizontal
--   Eje X: total_engagement
--   Eje Y: actor
--   Orden: Descendente por total_engagement
--   Formato: Número con separador de miles (ej: 274,001)
--
-- Título sugerido: "Total de Engagement por Actor"
--
-- Nota: LEFT JOIN con metrics es CRÍTICO para incluir
--       menciones sin engagement (tratadas como 0)
-- =====================================================
