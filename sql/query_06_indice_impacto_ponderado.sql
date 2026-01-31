-- =====================================================
-- Query 6: Índice de Impacto Ponderado (IIP)
-- Propósito: Medir resonancia digital basada en engagement
-- Análogo a Query 3 pero usando engagement en vez de menciones
-- Resultado: 0-100 (mayor = mayor impacto digital)
-- =====================================================

WITH base_metrics AS (
  SELECT
    t.tag_name AS actor,
    COUNT(*) AS menciones_total,

    -- Engagement por sentimiento
    SUM(CASE WHEN m.sentiment = 'Positivo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_positivo,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_negativo,
    SUM(CASE WHEN m.sentiment = 'Neutral' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_neutral,
    SUM(COALESCE(me.engagement, 0)) AS engagement_total

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
indices_base AS (
  SELECT
    actor,
    menciones_total,
    engagement_total,
    engagement_positivo,
    engagement_negativo,
    (engagement_positivo + engagement_negativo) AS engagement_polarizado,

    -- Balance de engagement (similar a balance de sentimiento pero con engagement)
    CASE
      WHEN (engagement_positivo + engagement_negativo) > 0 THEN
        ROUND(100.0 * engagement_positivo / (engagement_positivo + engagement_negativo), 1)
      ELSE 0
    END AS balance_engagement

  FROM base_metrics
  WHERE (engagement_positivo + engagement_negativo) > 0  -- Solo actores con engagement polarizado
),
normalizacion AS (
  SELECT MAX(engagement_polarizado) AS max_engagement_polarizado
  FROM indices_base
)
SELECT
  i.actor,
  i.menciones_total,
  i.engagement_total,
  i.engagement_positivo,
  i.engagement_negativo,
  i.engagement_polarizado,
  i.balance_engagement,

  -- Índice de Impacto Ponderado (IIP)
  -- Fórmula: balance_engagement × factor_impacto
  -- factor_impacto = engagement_polarizado / max_engagement_polarizado
  ROUND(
    i.balance_engagement * (i.engagement_polarizado::NUMERIC / NULLIF(n.max_engagement_polarizado, 0)),
    1
  ) AS indice_impacto_ponderado,

  -- Factor de impacto normalizado (0-1)
  ROUND(i.engagement_polarizado::NUMERIC / NULLIF(n.max_engagement_polarizado, 0), 3) AS factor_impacto

FROM indices_base i
CROSS JOIN normalizacion n

ORDER BY indice_impacto_ponderado DESC NULLS LAST;

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
-- Visualización recomendada: Tabla o Gráfico de barras
-- =====================================================
