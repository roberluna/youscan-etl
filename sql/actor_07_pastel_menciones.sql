-- =====================================================
-- Dashboard por Actor - Query 7
-- GRÁFICA DE PASTEL: Menciones por Sentimiento (%)
-- Visualización: Pie Chart
-- =====================================================

SELECT
  m.sentiment,
  COUNT(*) AS total_menciones,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS porcentaje
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  [[AND t.tag_name = {{actor}}]]
  [[AND {{fecha}}]]
  [[AND {{source_name}}]]
GROUP BY m.sentiment
ORDER BY total_menciones DESC;

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
--   Tipo: Pie Chart
--   Dimension: sentiment
--   Metric: total_menciones (o porcentaje si prefieres mostrar %)
--   Título: "Distribución de Menciones por Sentimiento"
--
-- Configuración de Colores:
--   - Positivo: #10b981 (verde esmeralda)
--   - Negativo: #ef4444 (rojo coral)
--   - Neutral:  #9ca3af (gris medio)
--
-- Configuración de Display:
--   - Show labels: Yes
--   - Show percentages: Yes
--   - Show values: Optional (puede mostrar total_menciones)
--
-- Uso en Dashboard:
--   - Colocar en sección de resumen de sentimiento
--   - Conectar a filtros globales: actor, fecha, source_name
--   - Permite ver rápidamente la distribución de sentimientos
--   - Complementa las series temporales de menciones
-- =====================================================
