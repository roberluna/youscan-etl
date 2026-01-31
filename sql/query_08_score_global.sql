-- =====================================================
-- Query 8: Score Global (SG)
-- Propósito: Índice compuesto que combina BP + IIP + IE
-- Fórmula: BP(40%) + IIP(40%) + IE(20%)
-- Resultado: 0-100 (mayor = mejor desempeño integral)
-- =====================================================

WITH base_metrics AS (
  SELECT
    t.tag_name AS actor,
    COUNT(*) AS menciones_total,

    -- Para Balance Ponderado (BP)
    SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS menciones_positivas,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS menciones_negativas,
    SUM(CASE WHEN m.sentiment = 'Neutral' THEN 1 ELSE 0 END) AS menciones_neutrales,

    -- Para Índice de Impacto (IIP)
    SUM(CASE WHEN m.sentiment = 'Positivo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_positivo,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_negativo,
    SUM(COALESCE(me.engagement, 0)) AS engagement_total,

    -- Para Índice de Eficiencia (IE)
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
-- =====================================
-- CÁLCULO DEL BALANCE PONDERADO (BP)
-- =====================================
balance_ponderado AS (
  SELECT
    actor,
    menciones_total,
    menciones_positivas,
    menciones_negativas,
    (menciones_positivas + menciones_negativas) AS menciones_polarizadas,

    -- Balance de sentimiento
    CASE
      WHEN (menciones_positivas + menciones_negativas) > 0 THEN
        ROUND(100.0 * menciones_positivas / (menciones_positivas + menciones_negativas), 1)
      ELSE 0
    END AS balance_sentimiento

  FROM base_metrics
),
bp_normalizado AS (
  SELECT
    bp.actor,
    bp.menciones_polarizadas,
    bp.balance_sentimiento,

    -- Balance Ponderado (Query 3)
    ROUND(
      bp.balance_sentimiento * (bp.menciones_polarizadas::NUMERIC / NULLIF(MAX(bp.menciones_polarizadas) OVER (), 0)),
      1
    ) AS balance_ponderado

  FROM balance_ponderado bp
  WHERE bp.menciones_polarizadas > 0
),
-- =====================================
-- CÁLCULO DEL ÍNDICE DE IMPACTO (IIP)
-- =====================================
indice_impacto AS (
  SELECT
    bm.actor,
    (bm.engagement_positivo + bm.engagement_negativo) AS engagement_polarizado,

    -- Balance de engagement
    CASE
      WHEN (bm.engagement_positivo + bm.engagement_negativo) > 0 THEN
        ROUND(100.0 * bm.engagement_positivo / (bm.engagement_positivo + bm.engagement_negativo), 1)
      ELSE 0
    END AS balance_engagement,

    -- Índice de Impacto Ponderado (Query 6)
    ROUND(
      CASE
        WHEN (bm.engagement_positivo + bm.engagement_negativo) > 0 THEN
          (100.0 * bm.engagement_positivo / (bm.engagement_positivo + bm.engagement_negativo)) *
          ((bm.engagement_positivo + bm.engagement_negativo)::NUMERIC / NULLIF(MAX(bm.engagement_positivo + bm.engagement_negativo) OVER (), 0))
        ELSE 0
      END,
      1
    ) AS indice_impacto_ponderado

  FROM base_metrics bm
  WHERE (bm.engagement_positivo + bm.engagement_negativo) > 0
),
-- =====================================
-- CÁLCULO DEL ÍNDICE DE EFICIENCIA (IE)
-- =====================================
indice_eficiencia AS (
  SELECT
    bm.actor,
    bm.engagement_total,
    bm.menciones_con_engagement,

    -- Engagement promedio
    CASE
      WHEN bm.menciones_total > 0 THEN
        bm.engagement_total::NUMERIC / bm.menciones_total
      ELSE 0
    END AS engagement_promedio,

    -- Factor de calidad
    CASE
      WHEN bm.menciones_total > 0 THEN
        bm.menciones_con_engagement::NUMERIC / bm.menciones_total
      ELSE 0
    END AS factor_calidad,

    -- Índice de Eficiencia (Query 7)
    ROUND(
      CASE
        WHEN bm.menciones_total > 0 THEN
          ((bm.engagement_total::NUMERIC / bm.menciones_total) / NULLIF(MAX(bm.engagement_total::NUMERIC / bm.menciones_total) OVER (), 0)) *
          (bm.menciones_con_engagement::NUMERIC / bm.menciones_total) * 100
        ELSE 0
      END,
      1
    ) AS indice_eficiencia

  FROM base_metrics bm
  WHERE bm.menciones_total > 0
)
-- =====================================
-- SCORE GLOBAL: COMBINACIÓN DE ÍNDICES
-- =====================================
SELECT
  bp.actor,

  -- Métricas base
  bp.menciones_total,
  iip.engagement_total,

  -- Índices individuales
  bp.balance_ponderado,
  iip.indice_impacto_ponderado,
  ie.indice_eficiencia,

  -- Score Global (SG)
  -- Fórmula: BP(40%) + IIP(40%) + IE(20%)
  ROUND(
    COALESCE(bp.balance_ponderado, 0) * 0.40 +
    COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
    COALESCE(ie.indice_eficiencia, 0) * 0.20,
    1
  ) AS score_global,

  -- Componentes del score (para análisis)
  ROUND(COALESCE(bp.balance_ponderado, 0) * 0.40, 1) AS componente_bp,
  ROUND(COALESCE(iip.indice_impacto_ponderado, 0) * 0.40, 1) AS componente_iip,
  ROUND(COALESCE(ie.indice_eficiencia, 0) * 0.20, 1) AS componente_ie,

  -- Clasificación
  CASE
    WHEN ROUND(
      COALESCE(bp.balance_ponderado, 0) * 0.40 +
      COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
      COALESCE(ie.indice_eficiencia, 0) * 0.20,
      1
    ) >= 70 THEN 'Excelente'
    WHEN ROUND(
      COALESCE(bp.balance_ponderado, 0) * 0.40 +
      COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
      COALESCE(ie.indice_eficiencia, 0) * 0.20,
      1
    ) >= 55 THEN 'Bueno'
    WHEN ROUND(
      COALESCE(bp.balance_ponderado, 0) * 0.40 +
      COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
      COALESCE(ie.indice_eficiencia, 0) * 0.20,
      1
    ) >= 40 THEN 'Regular'
    ELSE 'Bajo'
  END AS clasificacion

FROM bp_normalizado bp
LEFT JOIN indice_impacto iip ON iip.actor = bp.actor
LEFT JOIN indice_eficiencia ie ON ie.actor = bp.actor

ORDER BY score_global DESC NULLS LAST;

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
-- Fórmula del Score Global:
--   SG = BP × 40% + IIP × 40% + IE × 20%
--
-- Justificación de pesos:
--   - BP (40%): Percepción pública es fundamental
--   - IIP (40%): Impacto digital es igualmente crítico
--   - IE (20%): Eficiencia es deseable pero menos prioritaria
--
-- Clasificación:
--   70-100: Excelente desempeño integral
--   55-69:  Buen desempeño
--   40-54:  Desempeño regular
--   0-39:   Bajo desempeño, requiere atención
--
-- Visualización recomendada: Tabla o Gráfico de barras
-- =====================================================
