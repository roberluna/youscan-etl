-- =====================================================
-- MVP Dashboard - Gráfica 4
-- Engagement DESGLOSADO por Sentimiento por Actor
-- Visualización: Gráfico de barras apiladas
-- =====================================================

SELECT
  t.tag_name AS actor,
  SUM(CASE WHEN m.sentiment = 'Positivo' THEN COALESCE(me.engagement, 0) END) AS positivas,
  SUM(CASE WHEN m.sentiment = 'Negativo' THEN COALESCE(me.engagement, 0) END) AS negativas,
  SUM(CASE WHEN m.sentiment = 'Neutral' THEN COALESCE(me.engagement, 0) END) AS neutrales,
  SUM(COALESCE(me.engagement, 0)) AS total
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
LEFT JOIN metrics me ON me.mention_id = m.mention_id  -- LEFT JOIN crítico!
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  [[AND {{fecha}}]]
  [[AND {{source_name}}]]
GROUP BY t.tag_name
ORDER BY total DESC;

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
--   Tipo: Tabla o Barra apilada horizontal
--   Columnas: actor, positivas, negativas, neutrales, total
--   Orden: Descendente por total
--
--   Si usas tabla:
--     - Mostrar todas las columnas
--     - Formato: Número con separador de miles (ej: 274,001)
--
--   Si usas barra apilada:
--     - X-axis: actor
--     - Series: positivas, negativas, neutrales
--     - Colores sugeridos:
--       - positivas: Verde (#10b981)
--       - negativas: Rojo (#ef4444)
--       - neutrales: Gris (#6b7280)
--
-- Título sugerido: "Engagement por Actor - Desglose por Sentimiento"
--
-- Nota: LEFT JOIN con metrics es CRÍTICO para incluir
--       menciones sin engagement (tratadas como 0)
-- =====================================================
