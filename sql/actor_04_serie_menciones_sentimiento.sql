-- =====================================================
-- Dashboard por Actor - Query 4
-- SERIE TEMPORAL: Menciones por Sentimiento por Tiempo
-- Visualización: Gráfica de línea/área apilada temporal
-- =====================================================

SELECT
  DATE_TRUNC('day', m.published_at) AS fecha,
  m.sentiment,
  COUNT(*) AS total_menciones
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
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
-- Visualización:
--   Tipo: Line Chart (con múltiples series) o Area Chart (stacked)
--   X-Axis: fecha (Date)
--   Y-Axis: total_menciones (Number)
--   Series: sentiment (Dimension)
--   Título: "Evolución de Menciones por Sentimiento"
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
--   - Colocar debajo de la serie temporal de menciones totales
--   - Conectar a filtros globales: actor, fecha, source_name
--   - Permite comparar tendencias de sentimiento a lo largo del tiempo
-- =====================================================
