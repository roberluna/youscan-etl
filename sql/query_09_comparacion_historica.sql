-- =====================================================
-- Query 9: Comparación vs. Periodo Anterior
-- Propósito: Detectar cambios significativos entre periodos
-- Análisis: Week-over-week o month-over-month
-- =====================================================

WITH periodo_actual AS (
  -- Obtener el periodo más reciente por tipo
  SELECT
    actor,
    periodo_inicio,
    periodo_fin,
    tipo_periodo,
    score_global,
    balance_ponderado,
    indice_impacto_ponderado,
    indice_eficiencia,
    menciones_total,
    engagement_total
  FROM indices_historico
  WHERE tipo_periodo = '{{tipo_periodo}}'  -- 'semanal' o 'mensual'
    AND (actor = '{{actor}}' OR '{{actor}}' = 'Todos')
    AND periodo_inicio = (
      SELECT MAX(periodo_inicio)
      FROM indices_historico
      WHERE tipo_periodo = '{{tipo_periodo}}'
    )
),
periodo_anterior AS (
  -- Obtener el periodo inmediatamente anterior
  SELECT
    actor,
    periodo_inicio,
    periodo_fin,
    score_global,
    balance_ponderado,
    indice_impacto_ponderado,
    indice_eficiencia,
    menciones_total,
    engagement_total
  FROM indices_historico
  WHERE tipo_periodo = '{{tipo_periodo}}'
    AND (actor = '{{actor}}' OR '{{actor}}' = 'Todos')
    AND periodo_inicio = (
      SELECT MAX(periodo_inicio)
      FROM indices_historico
      WHERE tipo_periodo = '{{tipo_periodo}}'
        AND periodo_inicio < (
          SELECT MAX(periodo_inicio)
          FROM indices_historico
          WHERE tipo_periodo = '{{tipo_periodo}}'
        )
    )
)
SELECT
  pa.actor,

  -- Periodos
  pa.periodo_inicio AS periodo_actual_inicio,
  pa.periodo_fin AS periodo_actual_fin,
  pp.periodo_inicio AS periodo_anterior_inicio,
  pp.periodo_fin AS periodo_anterior_fin,

  -- Score Global
  pa.score_global AS score_actual,
  COALESCE(pp.score_global, 0) AS score_anterior,
  ROUND(pa.score_global - COALESCE(pp.score_global, 0), 1) AS variacion_score,
  ROUND(
    100.0 * (pa.score_global - COALESCE(pp.score_global, 0)) / NULLIF(pp.score_global, 1),
    1
  ) AS pct_cambio_score,

  -- Tendencia del Score Global
  CASE
    WHEN (pa.score_global - COALESCE(pp.score_global, 0)) > 5 THEN '📈 Mejora significativa'
    WHEN (pa.score_global - COALESCE(pp.score_global, 0)) > 0 THEN '↗️ Mejora'
    WHEN (pa.score_global - COALESCE(pp.score_global, 0)) = 0 THEN '➡️ Sin cambio'
    WHEN (pa.score_global - COALESCE(pp.score_global, 0)) > -5 THEN '↘️ Deterioro'
    ELSE '📉 Deterioro significativo'
  END AS tendencia_score,

  -- Balance Ponderado
  pa.balance_ponderado AS bp_actual,
  COALESCE(pp.balance_ponderado, 0) AS bp_anterior,
  ROUND(pa.balance_ponderado - COALESCE(pp.balance_ponderado, 0), 1) AS variacion_bp,

  -- Índice de Impacto
  pa.indice_impacto_ponderado AS iip_actual,
  COALESCE(pp.indice_impacto_ponderado, 0) AS iip_anterior,
  ROUND(pa.indice_impacto_ponderado - COALESCE(pp.indice_impacto_ponderado, 0), 1) AS variacion_iip,

  -- Índice de Eficiencia
  pa.indice_eficiencia AS ie_actual,
  COALESCE(pp.indice_eficiencia, 0) AS ie_anterior,
  ROUND(pa.indice_eficiencia - COALESCE(pp.indice_eficiencia, 0), 1) AS variacion_ie,

  -- Métricas base
  pa.menciones_total AS menciones_actuales,
  COALESCE(pp.menciones_total, 0) AS menciones_anteriores,
  ROUND(pa.engagement_total, 0) AS engagement_actual,
  ROUND(COALESCE(pp.engagement_total, 0), 0) AS engagement_anterior

FROM periodo_actual pa
LEFT JOIN periodo_anterior pp ON pp.actor = pa.actor

ORDER BY variacion_score DESC;

-- =====================================================
-- Notas de uso para Metabase:
-- =====================================================
-- Variables requeridas:
--   {{actor}}          = Nombre del actor o "Todos" para todos
--   {{tipo_periodo}}   = 'semanal' o 'mensual'
--
-- Ejemplo de valores:
--   actor: "Claudia Sheinbaum" o "Todos"
--   tipo_periodo: "semanal"
--
-- Interpretación de tendencias:
--   📈 Mejora significativa:    Variación > +5 puntos
--   ↗️ Mejora:                  Variación entre 0 y +5
--   ➡️ Sin cambio:              Variación = 0
--   ↘️ Deterioro:               Variación entre 0 y -5
--   📉 Deterioro significativo: Variación < -5 puntos
--
-- Casos de uso:
--   - Detectar crisis de reputación (deterioro significativo)
--   - Identificar momentum positivo (mejora significativa)
--   - Comparar desempeño week-over-week
--   - Analizar efectividad de campañas
--
-- Visualización recomendada: Tabla con formato condicional
-- =====================================================
