-- =====================================================
-- Dashboard por Actor - Query 5
-- SERIE TEMPORAL: Engagement Total por Tiempo
-- Visualización: Gráfica de línea/barras temporal
-- =====================================================

SELECT
  DATE_TRUNC('day', m.published_at) AS fecha,
  SUM(COALESCE(me.engagement, 0)) AS total_engagement
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
LEFT JOIN metrics me ON me.mention_id = o.mention_id
WHERE t.tag_type = 'actor'
  [[AND t.tag_name = {{actor}}]]
  [[AND {{fecha}}]]
  [[AND {{source_name}}]]
GROUP BY DATE_TRUNC('day', m.published_at)
ORDER BY fecha;

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
--   Tipo: Line Chart o Bar Chart
--   X-Axis: fecha (Date)
--   Y-Axis: total_engagement (Number)
--   Título: "Evolución de Engagement"
--
-- Configuración de Eje X:
--   - Date Style: Por día (daily)
--   - Si el rango es > 30 días, considerar agrupar por semana:
--     Cambiar DATE_TRUNC('day', ...) a DATE_TRUNC('week', ...)
--
-- Uso en Dashboard:
--   - Colocar en sección de series temporales (engagement)
--   - Conectar a filtros globales: actor, fecha, source_name
--   - Permite ver tendencias de engagement a lo largo del tiempo
-- =====================================================
