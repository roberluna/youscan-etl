-- =====================================================
-- MVP Dashboard - Gráfica 1
-- Menciones TOTALES por Actor
-- Visualización: Gráfico de barras horizontal
-- =====================================================

SELECT
  t.tag_name AS actor,
  COUNT(*) AS total_menciones
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  [[AND {{fecha}}]]
  [[AND {{source_name}}]]
GROUP BY t.tag_name
ORDER BY total_menciones DESC;

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
--   Eje X: total_menciones
--   Eje Y: actor
--   Orden: Descendente por total_menciones
--
-- Título sugerido: "Total de Menciones por Actor"
-- =====================================================
