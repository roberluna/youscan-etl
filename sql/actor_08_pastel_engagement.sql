-- =====================================================
-- Dashboard por Actor - Query 8
-- GRÁFICA DE PASTEL: Engagement por Sentimiento (%)
-- Visualización: Pie Chart
-- =====================================================

SELECT
  m.sentiment,
  SUM(COALESCE(me.engagement, 0)) AS total_engagement,
  ROUND(SUM(COALESCE(me.engagement, 0)) * 100.0 / SUM(SUM(COALESCE(me.engagement, 0))) OVER (), 2) AS porcentaje
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
LEFT JOIN metrics me ON me.mention_id = o.mention_id
WHERE t.tag_type = 'actor'
  [[AND t.tag_name = {{actor}}]]
  [[AND {{fecha}}]]
  [[AND {{source_name}}]]
GROUP BY m.sentiment
ORDER BY total_engagement DESC;

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
--   Tipo: Pie Chart
--   Dimension: sentiment
--   Metric: total_engagement (o porcentaje si prefieres mostrar %)
--   Título: "Distribución de Engagement por Sentimiento"
--
-- Configuración de Colores:
--   - Positivo: #10b981 (verde esmeralda)
--   - Negativo: #ef4444 (rojo coral)
--   - Neutral:  #9ca3af (gris medio)
--
-- Configuración de Display:
--   - Show labels: Yes
--   - Show percentages: Yes
--   - Show values: Optional (puede mostrar total_engagement)
--
-- Uso en Dashboard:
--   - Colocar junto a la gráfica de pastel de menciones
--   - Conectar a filtros globales: actor, fecha, source_name
--   - Permite ver rápidamente la distribución de engagement por sentimiento
--   - Complementa las series temporales de engagement
--   - Útil para comparar si el engagement está más concentrado en un sentimiento
-- =====================================================
