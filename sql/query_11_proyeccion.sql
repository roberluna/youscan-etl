-- =====================================================
-- Query 11: Proyección Simple (próximo periodo)
-- Propósito: Estimar score del próximo periodo
-- Método: Media móvil ponderada + tendencia lineal
-- =====================================================

WITH ultimas_semanas AS (
  -- Obtener últimos N periodos para el actor
  SELECT
    actor,
    periodo_inicio,
    periodo_fin,
    score_global,
    balance_ponderado,
    indice_impacto_ponderado,
    indice_eficiencia,
    menciones_total,
    engagement_total,
    -- Número de periodo (1 = más antiguo, N = más reciente)
    ROW_NUMBER() OVER (PARTITION BY actor ORDER BY periodo_inicio DESC) AS periodo_num
  FROM indices_historico
  WHERE tipo_periodo = '{{tipo_periodo}}'  -- 'semanal' o 'mensual'
    AND (actor = '{{actor}}' OR '{{actor}}' = 'Todos')
    AND periodo_inicio >= CURRENT_DATE - INTERVAL '{{periodos_analisis}} weeks'
),
tendencia_actor AS (
  -- Calcular tendencia y estadísticas por actor
  SELECT
    actor,

    -- Score actual (periodo más reciente)
    MAX(CASE WHEN periodo_num = 1 THEN score_global END) AS score_actual,
    MAX(CASE WHEN periodo_num = 1 THEN periodo_inicio END) AS ultimo_periodo_inicio,
    MAX(CASE WHEN periodo_num = 1 THEN periodo_fin END) AS ultimo_periodo_fin,

    -- Media móvil ponderada (da más peso a periodos recientes)
    -- Ponderación: periodo_1 × 5, periodo_2 × 4, periodo_3 × 3, etc.
    ROUND(
      SUM(score_global * (9 - periodo_num)) / NULLIF(SUM(9 - periodo_num), 0),
      1
    ) AS score_promedio_ponderado,

    -- Tendencia (pendiente de regresión lineal)
    -- Negativo porque periodo_num está invertido (1 = más reciente)
    ROUND(
      CAST(REGR_SLOPE(score_global, periodo_num) AS NUMERIC),
      2
    ) AS pendiente,

    -- Volatilidad (desviación estándar)
    ROUND(STDDEV(score_global), 1) AS volatilidad,

    -- Número de periodos disponibles
    COUNT(*) AS periodos_disponibles

  FROM ultimas_semanas
  WHERE periodo_num <= 8  -- Usar máximo 8 periodos para la proyección
  GROUP BY actor
),
proyeccion AS (
  SELECT
    actor,
    score_actual,
    ultimo_periodo_inicio,
    ultimo_periodo_fin,
    score_promedio_ponderado,
    pendiente,
    volatilidad,
    periodos_disponibles,

    -- Proyección del próximo periodo
    -- Fórmula: promedio_ponderado + (pendiente × -1)
    -- El -1 invierte la pendiente porque periodo_num está descendente
    ROUND(
      score_promedio_ponderado + (pendiente * -1),
      1
    ) AS proyeccion_proximo_periodo,

    -- Rango de confianza (± 1 desviación estándar)
    ROUND(score_promedio_ponderado + (pendiente * -1) - volatilidad, 1) AS proyeccion_min,
    ROUND(score_promedio_ponderado + (pendiente * -1) + volatilidad, 1) AS proyeccion_max,

    -- Nivel de confianza basado en volatilidad y pendiente
    CASE
      WHEN ABS(pendiente) < 0.5 AND volatilidad < 3 THEN 'Alta (tendencia estable, baja volatilidad)'
      WHEN ABS(pendiente) < 2 AND volatilidad < 7 THEN 'Media (tendencia moderada)'
      WHEN volatilidad >= 10 THEN 'Baja (alta volatilidad - comportamiento impredecible)'
      WHEN ABS(pendiente) >= 5 THEN 'Baja (tendencia muy fuerte - posible sobrecorrección)'
      ELSE 'Media'
    END AS confianza_proyeccion,

    -- Interpretación de la proyección
    CASE
      WHEN (score_promedio_ponderado + (pendiente * -1)) - score_actual > 5 THEN '📈 Se proyecta mejora significativa'
      WHEN (score_promedio_ponderado + (pendiente * -1)) - score_actual > 0 THEN '↗️ Se proyecta mejora'
      WHEN (score_promedio_ponderado + (pendiente * -1)) - score_actual = 0 THEN '➡️ Se proyecta estabilidad'
      WHEN (score_promedio_ponderado + (pendiente * -1)) - score_actual > -5 THEN '↘️ Se proyecta deterioro'
      ELSE '📉 Se proyecta deterioro significativo'
    END AS interpretacion

  FROM tendencia_actor
  WHERE periodos_disponibles >= 2  -- Mínimo 2 periodos para proyectar
)
SELECT
  actor,

  -- Periodo actual
  ultimo_periodo_inicio AS periodo_actual_inicio,
  ultimo_periodo_fin AS periodo_actual_fin,

  -- Score actual vs proyectado
  score_actual,
  proyeccion_proximo_periodo,
  ROUND(proyeccion_proximo_periodo - score_actual, 1) AS cambio_esperado,

  -- Rango de confianza
  proyeccion_min,
  proyeccion_max,
  ROUND(proyeccion_max - proyeccion_min, 1) AS amplitud_rango,

  -- Métricas de análisis
  score_promedio_ponderado,
  pendiente AS tendencia_por_periodo,
  volatilidad,

  -- Interpretación
  confianza_proyeccion,
  interpretacion,

  -- Metadata
  periodos_disponibles

FROM proyeccion

ORDER BY proyeccion_proximo_periodo DESC;

-- =====================================================
-- Notas de uso para Metabase:
-- =====================================================
-- Variables requeridas:
--   {{actor}}               = Nombre del actor o "Todos" para todos
--   {{tipo_periodo}}        = 'semanal' o 'mensual'
--   {{periodos_analisis}}   = Número de periodos a considerar (ej: 8)
--
-- Ejemplo de valores:
--   actor: "Claudia Sheinbaum" o "Todos"
--   tipo_periodo: "semanal"
--   periodos_analisis: 8
--
-- Método de proyección:
--   1. Calcula media móvil ponderada (más peso a periodos recientes)
--   2. Calcula tendencia lineal (pendiente de regresión)
--   3. Proyección = promedio_ponderado + tendencia
--   4. Rango = proyección ± volatilidad
--
-- Interpretación de confianza:
--   - Alta:  Tendencia estable, baja volatilidad → Proyección confiable
--   - Media: Tendencia moderada o volatilidad media → Usar con precaución
--   - Baja:  Alta volatilidad o tendencia extrema → Proyección poco confiable
--
-- Limitaciones:
--   - Proyección simple lineal (no considera estacionalidad)
--   - Asume que tendencia actual continuará
--   - No considera eventos externos (campañas, crisis, etc.)
--   - Para pronósticos avanzados, considerar Facebook Prophet
--
-- Casos de uso:
--   - Planificación de corto plazo
--   - Detección temprana de deterioro
--   - Identificación de momentum positivo
--   - Priorización de actores que requieren atención
--
-- Visualización recomendada: Tabla con formato condicional
-- =====================================================
