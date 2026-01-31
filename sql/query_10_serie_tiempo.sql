-- =====================================================
-- Query 10: Serie de Tiempo (últimas 12 semanas)
-- Propósito: Analizar tendencias temporales con medias móviles
-- Análisis: Últimos N periodos con estadísticas avanzadas
-- =====================================================

WITH datos_historicos AS (
  -- Obtener datos históricos del actor y tipo de periodo especificado
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
    -- Número de semana (1 = más antigua, N = más reciente)
    ROW_NUMBER() OVER (PARTITION BY actor ORDER BY periodo_inicio ASC) AS semana_num,
    -- Total de periodos disponibles para este actor
    COUNT(*) OVER (PARTITION BY actor) AS total_periodos
  FROM indices_historico
  WHERE tipo_periodo = '{{tipo_periodo}}'  -- 'semanal' o 'mensual'
    AND (actor = '{{actor}}' OR '{{actor}}' = 'Todos')
    -- Limitar a últimas N semanas/meses (ajustar según disponibilidad)
    AND periodo_inicio >= CURRENT_DATE - INTERVAL '{{semanas}} weeks'
)
SELECT
  actor,
  periodo_inicio,
  periodo_fin,
  semana_num,

  -- Score Global actual
  score_global,

  -- Media móvil de 4 periodos (suaviza fluctuaciones)
  ROUND(
    AVG(score_global) OVER (
      PARTITION BY actor
      ORDER BY periodo_inicio
      ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ),
    1
  ) AS media_movil_4per,

  -- Tendencia (pendiente de regresión lineal)
  -- Valor positivo = tendencia ascendente, negativo = descendente
  ROUND(
    CAST(
      REGR_SLOPE(
        score_global,
        semana_num
      ) OVER (
        PARTITION BY actor
        ORDER BY periodo_inicio
        ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
      ) AS NUMERIC
    ),
    2
  ) AS tendencia_pendiente,

  -- Volatilidad (desviación estándar de últimos 4 periodos)
  ROUND(
    STDDEV(score_global) OVER (
      PARTITION BY actor
      ORDER BY periodo_inicio
      ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ),
    1
  ) AS volatilidad,

  -- Interpretación de tendencia
  CASE
    WHEN REGR_SLOPE(score_global, semana_num) OVER (
      PARTITION BY actor
      ORDER BY periodo_inicio
      ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ) > 1 THEN '↗️ Tendencia ascendente fuerte'
    WHEN REGR_SLOPE(score_global, semana_num) OVER (
      PARTITION BY actor
      ORDER BY periodo_inicio
      ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ) > 0 THEN '↗️ Tendencia ascendente'
    WHEN REGR_SLOPE(score_global, semana_num) OVER (
      PARTITION BY actor
      ORDER BY periodo_inicio
      ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ) = 0 THEN '➡️ Estable'
    WHEN REGR_SLOPE(score_global, semana_num) OVER (
      PARTITION BY actor
      ORDER BY periodo_inicio
      ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ) > -1 THEN '↘️ Tendencia descendente'
    ELSE '↘️ Tendencia descendente fuerte'
  END AS interpretacion_tendencia,

  -- Clasificación de volatilidad
  CASE
    WHEN STDDEV(score_global) OVER (
      PARTITION BY actor
      ORDER BY periodo_inicio
      ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ) < 3 THEN 'Baja (predecible)'
    WHEN STDDEV(score_global) OVER (
      PARTITION BY actor
      ORDER BY periodo_inicio
      ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ) < 7 THEN 'Media'
    ELSE 'Alta (impredecible)'
  END AS nivel_volatilidad,

  -- Índices individuales (para análisis detallado)
  balance_ponderado,
  indice_impacto_ponderado,
  indice_eficiencia,

  -- Métricas base
  menciones_total,
  ROUND(engagement_total, 0) AS engagement_total

FROM datos_historicos

ORDER BY actor, periodo_inicio DESC;

-- =====================================================
-- Notas de uso para Metabase:
-- =====================================================
-- Variables requeridas:
--   {{actor}}          = Nombre del actor o "Todos" para todos
--   {{tipo_periodo}}   = 'semanal' o 'mensual'
--   {{semanas}}        = Número de semanas a analizar (ej: 12)
--
-- Ejemplo de valores:
--   actor: "Claudia Sheinbaum" o "Todos"
--   tipo_periodo: "semanal"
--   semanas: 12
--
-- Métricas clave:
--   - score_global: Valor actual del periodo
--   - media_movil_4per: Promedio de últimos 4 periodos (suaviza picos)
--   - tendencia_pendiente: Cuánto sube/baja por periodo
--   - volatilidad: Qué tan predecible es el comportamiento
--
-- Interpretación de tendencia_pendiente:
--   > +1.0:  Mejora fuerte y sostenida
--   0 a +1:  Mejora moderada
--   0:       Estabilidad
--   -1 a 0:  Deterioro moderado
--   < -1.0:  Deterioro fuerte y sostenido
--
-- Interpretación de volatilidad:
--   < 3:  Baja - Comportamiento predecible
--   3-7:  Media - Algunas fluctuaciones
--   > 7:  Alta - Comportamiento errático
--
-- Casos de uso:
--   - Identificar patrones de largo plazo
--   - Detectar si mejoras/deterioros son temporales o tendencias
--   - Evaluar estabilidad del desempeño
--   - Validar efectividad de campañas sostenidas
--
-- Visualización recomendada: Gráfico de líneas con media móvil
-- =====================================================
