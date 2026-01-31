-- =====================================================
-- Script: Poblar indices_historico con datos históricos
-- Propósito: Calcular índices semanales y almacenarlos
-- =====================================================

-- Primero, verificar rango de fechas disponibles
DO $$
DECLARE
  fecha_min DATE;
  fecha_max DATE;
BEGIN
  SELECT MIN(published_at::DATE), MAX(published_at::DATE)
  INTO fecha_min, fecha_max
  FROM mentions;

  RAISE NOTICE 'Datos disponibles desde % hasta %', fecha_min, fecha_max;
END $$;

-- =====================================================
-- Insertar datos semanales
-- =====================================================

-- Semana 1: 2025-12-22 a 2025-12-28
INSERT INTO indices_historico (
  actor,
  periodo_inicio,
  periodo_fin,
  tipo_periodo,
  menciones_total,
  menciones_positivas,
  menciones_negativas,
  menciones_neutrales,
  engagement_total,
  engagement_positivo,
  engagement_negativo,
  balance_ponderado,
  indice_impacto_ponderado,
  indice_eficiencia,
  score_global
)
WITH base_metrics AS (
  SELECT
    t.tag_name AS actor,
    COUNT(*) AS menciones_total,
    SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS menciones_positivas,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS menciones_negativas,
    SUM(CASE WHEN m.sentiment = 'Neutral' THEN 1 ELSE 0 END) AS menciones_neutrales,
    SUM(CASE WHEN m.sentiment = 'Positivo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_positivo,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_negativo,
    SUM(COALESCE(me.engagement, 0)) AS engagement_total,
    SUM(CASE WHEN COALESCE(me.engagement, 0) > 0 THEN 1 ELSE 0 END) AS menciones_con_engagement
  FROM mention_occurrences o
  JOIN mentions m ON m.mention_id = o.mention_id
  LEFT JOIN metrics me ON me.mention_id = m.mention_id
  JOIN mention_tags mt ON mt.mention_id = o.mention_id
  JOIN tags t ON t.tag_id = mt.tag_id
  WHERE t.tag_type = 'actor'
    AND m.published_at::DATE BETWEEN '2025-12-22' AND '2025-12-28'
  GROUP BY t.tag_name
),
balance_ponderado AS (
  SELECT
    actor,
    menciones_total,
    menciones_positivas,
    menciones_negativas,
    menciones_neutrales,
    engagement_total,
    engagement_positivo,
    engagement_negativo,
    (menciones_positivas + menciones_negativas) AS menciones_polarizadas,
    CASE
      WHEN (menciones_positivas + menciones_negativas) > 0 THEN
        100.0 * menciones_positivas / (menciones_positivas + menciones_negativas)
      ELSE 0
    END AS balance_sentimiento
  FROM base_metrics
),
bp_normalizado AS (
  SELECT
    bp.*,
    ROUND(
      bp.balance_sentimiento * (bp.menciones_polarizadas::NUMERIC / NULLIF(MAX(bp.menciones_polarizadas) OVER (), 0)),
      1
    ) AS balance_ponderado
  FROM balance_ponderado bp
),
indice_impacto AS (
  SELECT
    bm.actor,
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
),
indice_eficiencia AS (
  SELECT
    bm.actor,
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
)
SELECT
  bp.actor,
  '2025-12-22'::DATE AS periodo_inicio,
  '2025-12-28'::DATE AS periodo_fin,
  'semanal' AS tipo_periodo,
  bp.menciones_total,
  bp.menciones_positivas,
  bp.menciones_negativas,
  bp.menciones_neutrales,
  bp.engagement_total,
  bp.engagement_positivo,
  bp.engagement_negativo,
  bp.balance_ponderado,
  iip.indice_impacto_ponderado,
  ie.indice_eficiencia,
  ROUND(
    COALESCE(bp.balance_ponderado, 0) * 0.40 +
    COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
    COALESCE(ie.indice_eficiencia, 0) * 0.20,
    1
  ) AS score_global
FROM bp_normalizado bp
LEFT JOIN indice_impacto iip ON iip.actor = bp.actor
LEFT JOIN indice_eficiencia ie ON ie.actor = bp.actor
ON CONFLICT (actor, periodo_inicio, periodo_fin, tipo_periodo) DO NOTHING;

-- Semana 2: 2025-12-29 a 2026-01-04
INSERT INTO indices_historico (
  actor,
  periodo_inicio,
  periodo_fin,
  tipo_periodo,
  menciones_total,
  menciones_positivas,
  menciones_negativas,
  menciones_neutrales,
  engagement_total,
  engagement_positivo,
  engagement_negativo,
  balance_ponderado,
  indice_impacto_ponderado,
  indice_eficiencia,
  score_global
)
WITH base_metrics AS (
  SELECT
    t.tag_name AS actor,
    COUNT(*) AS menciones_total,
    SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS menciones_positivas,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS menciones_negativas,
    SUM(CASE WHEN m.sentiment = 'Neutral' THEN 1 ELSE 0 END) AS menciones_neutrales,
    SUM(CASE WHEN m.sentiment = 'Positivo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_positivo,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_negativo,
    SUM(COALESCE(me.engagement, 0)) AS engagement_total,
    SUM(CASE WHEN COALESCE(me.engagement, 0) > 0 THEN 1 ELSE 0 END) AS menciones_con_engagement
  FROM mention_occurrences o
  JOIN mentions m ON m.mention_id = o.mention_id
  LEFT JOIN metrics me ON me.mention_id = m.mention_id
  JOIN mention_tags mt ON mt.mention_id = o.mention_id
  JOIN tags t ON t.tag_id = mt.tag_id
  WHERE t.tag_type = 'actor'
    AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
  GROUP BY t.tag_name
),
balance_ponderado AS (
  SELECT
    actor,
    menciones_total,
    menciones_positivas,
    menciones_negativas,
    menciones_neutrales,
    engagement_total,
    engagement_positivo,
    engagement_negativo,
    (menciones_positivas + menciones_negativas) AS menciones_polarizadas,
    CASE
      WHEN (menciones_positivas + menciones_negativas) > 0 THEN
        100.0 * menciones_positivas / (menciones_positivas + menciones_negativas)
      ELSE 0
    END AS balance_sentimiento
  FROM base_metrics
),
bp_normalizado AS (
  SELECT
    bp.*,
    ROUND(
      bp.balance_sentimiento * (bp.menciones_polarizadas::NUMERIC / NULLIF(MAX(bp.menciones_polarizadas) OVER (), 0)),
      1
    ) AS balance_ponderado
  FROM balance_ponderado bp
),
indice_impacto AS (
  SELECT
    bm.actor,
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
),
indice_eficiencia AS (
  SELECT
    bm.actor,
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
)
SELECT
  bp.actor,
  '2025-12-29'::DATE AS periodo_inicio,
  '2026-01-04'::DATE AS periodo_fin,
  'semanal' AS tipo_periodo,
  bp.menciones_total,
  bp.menciones_positivas,
  bp.menciones_negativas,
  bp.menciones_neutrales,
  bp.engagement_total,
  bp.engagement_positivo,
  bp.engagement_negativo,
  bp.balance_ponderado,
  iip.indice_impacto_ponderado,
  ie.indice_eficiencia,
  ROUND(
    COALESCE(bp.balance_ponderado, 0) * 0.40 +
    COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
    COALESCE(ie.indice_eficiencia, 0) * 0.20,
    1
  ) AS score_global
FROM bp_normalizado bp
LEFT JOIN indice_impacto iip ON iip.actor = bp.actor
LEFT JOIN indice_eficiencia ie ON ie.actor = bp.actor
ON CONFLICT (actor, periodo_inicio, periodo_fin, tipo_periodo) DO NOTHING;

-- Verificar datos insertados
SELECT
  'Datos insertados correctamente' AS status,
  COUNT(*) AS registros_totales,
  COUNT(DISTINCT actor) AS actores_unicos,
  COUNT(DISTINCT periodo_inicio) AS semanas_cargadas
FROM indices_historico;

-- Mostrar muestra de datos
SELECT
  actor,
  periodo_inicio,
  periodo_fin,
  score_global,
  balance_ponderado,
  indice_impacto_ponderado,
  indice_eficiencia
FROM indices_historico
ORDER BY periodo_inicio DESC, score_global DESC
LIMIT 15;
