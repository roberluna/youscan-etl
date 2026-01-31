-- =====================================================
-- Dashboard por Actor - Query 6
-- SERIE TEMPORAL: Engagement por Sentimiento por Tiempo
-- Visualización: Gráfica de línea/área apilada temporal
-- =====================================================

SELECT
  DATE_TRUNC('day', m.published_at) AS fecha,
  m.sentiment,
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
GROUP BY DATE_TRUNC('day', m.published_at), m.sentiment
ORDER BY fecha, m.sentiment;

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
--   Tipo: Line Chart (con múltiples series) o Area Chart (stacked)
--   X-Axis: fecha (Date)
--   Y-Axis: total_engagement (Number)
--   Series: sentiment (Dimension)
--   Título: "Evolución de Engagement por Sentimiento"
--
-- Configuración de Series:
--   - Split by: sentiment
--   - Colores:
--     * Positivo: #10b981 (verde esmeralda)
--     * Negativo: #ef4444 (rojo coral)
--     * Neutral:  #9ca3af (gris medio)
--
-- Configuración de Eje X:
--   - Date Style: Por día (daily)
--   - Si el rango es > 30 días, considerar agrupar por semana:
--     Cambiar DATE_TRUNC('day', ...) a DATE_TRUNC('week', ...)
--
-- Uso en Dashboard:
--   - Colocar debajo de la serie temporal de engagement total
--   - Conectar a filtros globales: actor, fecha, source_name
--   - Permite comparar tendencias de engagement por sentimiento a lo largo del tiempo
-- =====================================================
