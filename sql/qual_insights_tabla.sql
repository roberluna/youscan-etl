-- =====================================================
-- Dashboard por Actor - Tabla de Texto Cualitativo
-- Visualización: Tabla
-- =====================================================

SELECT
    insight_text AS "Texto",
    mentions_count AS "Menciones",
    ROUND(support_pct, 1) || '%' AS "Soporte"
FROM qual_insights
WHERE 1=1
  [[AND actor_name = {{actor}}]]
  [[AND {{fecha}}]]
ORDER BY
    mentions_count DESC;

-- =====================================================
-- Configuración en Metabase:
-- =====================================================
-- Variables OPCIONALES (usar sintaxis [[ ]]):
--   {{actor}}  = Field Filter → qual_insights.actor_name (String/Dropdown)
--   {{fecha}}  = Field Filter → qual_insights.period_start (Date Range)
--
-- IMPORTANTE: Conectar a los mismos filtros globales del dashboard por actor
--
-- Visualización:
--   Tipo: Tabla
--   Columnas:
--     - Texto: ancho amplio para mostrar el contenido completo
--     - Menciones: alineado a la derecha
--     - Soporte: alineado a la derecha
--
-- Uso en Dashboard:
--   - Colocar debajo de las gráficas
--   - Conectar a filtros globales: actor, fecha
-- =====================================================
