-- =====================================================
-- Query 7: Índice de Eficiencia (IE)
-- Propósito: Medir efectividad comunicacional (ROI de engagement)
-- Fórmula: eficiencia_bruta × factor_calidad
-- Resultado: 0-100 (mayor = comunicación más eficiente)
-- =====================================================

WITH base_metrics AS (
  SELECT
    t.tag_name AS actor,
    COUNT(*) AS menciones_total,

    -- Contadores de menciones
    SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS menciones_positivas,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS menciones_negativas,

    -- Engagement total y por sentimiento
    SUM(COALESCE(me.engagement, 0)) AS engagement_total,

    -- Menciones con engagement (calidad)
    SUM(CASE WHEN COALESCE(me.engagement, 0) > 0 THEN 1 ELSE 0 END) AS menciones_con_engagement

  FROM mention_occurrences o
  JOIN mentions m ON m.mention_id = o.mention_id
  LEFT JOIN metrics me ON me.mention_id = m.mention_id
  JOIN mention_tags mt ON mt.mention_id = o.mention_id
  JOIN tags t ON t.tag_id = mt.tag_id

  WHERE t.tag_type = 'actor'
    AND m.published_at::DATE BETWEEN '{{fecha_inicio}}' AND '{{fecha_fin}}'
    AND (t.tag_name = '{{actor}}' OR '{{actor}}' = 'Todos')

  GROUP BY t.tag_name
),
metricas_eficiencia AS (
  SELECT
    actor,
    menciones_total,
    menciones_positivas,
    menciones_negativas,
    engagement_total,
    menciones_con_engagement,

    -- Eficiencia bruta: engagement promedio por mención
    CASE
      WHEN menciones_total > 0 THEN
        engagement_total::NUMERIC / menciones_total
      ELSE 0
    END AS engagement_promedio,

    -- Factor de calidad: % de menciones que generan engagement
    CASE
      WHEN menciones_total > 0 THEN
        menciones_con_engagement::NUMERIC / menciones_total
      ELSE 0
    END AS factor_calidad

  FROM base_metrics
  WHERE menciones_total > 0
),
normalizacion AS (
  -- Normalizar el engagement promedio al rango 0-1
  SELECT
    MAX(engagement_promedio) AS max_engagement_promedio
  FROM metricas_eficiencia
)
SELECT
  m.actor,
  m.menciones_total,
  m.engagement_total,
  m.menciones_con_engagement,
  ROUND(m.engagement_promedio, 2) AS engagement_promedio,
  ROUND(m.factor_calidad, 3) AS factor_calidad,

  -- Índice de Eficiencia (IE)
  -- Fórmula: (engagement_promedio_normalizado × factor_calidad) × 100
  -- Normalización: engagement_promedio / max_engagement_promedio
  ROUND(
    (m.engagement_promedio / NULLIF(n.max_engagement_promedio, 0)) * m.factor_calidad * 100,
    1
  ) AS indice_eficiencia

FROM metricas_eficiencia m
CROSS JOIN normalizacion n

ORDER BY indice_eficiencia DESC NULLS LAST;

-- =====================================================
-- Notas de uso para Metabase:
-- =====================================================
-- Variables requeridas:
--   {{actor}}         = Nombre del actor o "Todos" para todos
--   {{fecha_inicio}}  = Fecha inicio (YYYY-MM-DD)
--   {{fecha_fin}}     = Fecha fin (YYYY-MM-DD)
--
-- Ejemplo de valores:
--   actor: "Claudia Sheinbaum" o "Todos"
--   fecha_inicio: "2025-12-29"
--   fecha_fin: "2026-01-04"
--
-- Interpretación:
--   IE > 80  = Comunicación muy eficiente
--   IE 60-80 = Comunicación eficiente
--   IE 40-60 = Comunicación moderada
--   IE < 40  = Baja eficiencia, revisar estrategia
--
-- Visualización recomendada: Tabla o Gráfico de barras
-- =====================================================
