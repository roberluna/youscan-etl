# 📊 Fase 6: Sistema de Índices Avanzados - Plan de Implementación

**Fecha de creación:** 2026-01-07
**Estado:** Planificación
**Versión:** 1.0

---

## 📋 Índice

1. [Resumen ejecutivo](#resumen-ejecutivo)
2. [Arquitectura del sistema de índices](#arquitectura-del-sistema-de-índices)
3. [Consideraciones de análisis temporal](#consideraciones-de-análisis-temporal)
4. [Fase 1: Query 6 - Índice de Impacto Ponderado](#fase-1-query-6---índice-de-impacto-ponderado)
5. [Fase 2: Query 7 - Índice de Eficiencia](#fase-2-query-7---índice-de-eficiencia)
6. [Fase 3: Query 8 - Score Global](#fase-3-query-8---score-global)
7. [Fase 4: Queries de Análisis Temporal](#fase-4-queries-de-análisis-temporal)
8. [Fase 5: Validación y pruebas](#fase-5-validación-y-pruebas)
9. [Fase 6: Documentación y deployment](#fase-6-documentación-y-deployment)
10. [Checklist de implementación](#checklist-de-implementación)

---

## 🎯 Resumen Ejecutivo

### Objetivo

Expandir el sistema de análisis político con **3 nuevos índices** que complementen el Query 3 existente (Balance Ponderado), proporcionando una visión 360° del desempeño de actores políticos.

### Índices a Implementar

| Query | Nombre | Qué mide | Prioridad |
|-------|--------|----------|-----------|
| Query 3 | Balance Ponderado (BP) | Percepción pública | ✅ Existente |
| Query 6 | Índice de Impacto Ponderado (IIP) | Resonancia digital | 🔴 Alta |
| Query 7 | Índice de Eficiencia (IE) | Efectividad comunicacional | 🟡 Media |
| Query 8 | Score Global (SG) | Índice compuesto | 🟢 Baja |

### Tiempo Estimado

- **Fase 1 (Query 6):** 2-3 horas
- **Fase 2 (Query 7):** 2-3 horas
- **Fase 3 (Query 8):** 1-2 horas
- **Fase 4 (Validación):** 2-3 horas
- **Fase 5 (Documentación):** 1-2 horas

**Total:** 8-13 horas

---

## 🏗️ Arquitectura del Sistema de Índices

### Diagrama de Relaciones

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SISTEMA DE ÍNDICES AVANZADOS                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  📊 ÍNDICES BASE (Inputs)                                           │
│  ├─ Query 1: Menciones por actor (volumen + sentimiento)           │
│  └─ Query 2: Engagement por actor (engagement + sentimiento)       │
│                                                                      │
│  ▼                                                                   │
│                                                                      │
│  🎯 ÍNDICES ESPECIALIZADOS (Procesamiento)                          │
│  ├─ Query 3: Balance Ponderado (BP) ✅ Existente                   │
│  │   └─ Fórmula: sentimiento × volumen_menciones                   │
│  │   └─ Mide: Percepción pública                                   │
│  │                                                                   │
│  ├─ Query 6: Índice de Impacto (IIP) ✨ Nuevo                      │
│  │   └─ Fórmula: balance_engagement × engagement_normalizado       │
│  │   └─ Mide: Resonancia digital real                              │
│  │                                                                   │
│  └─ Query 7: Índice de Eficiencia (IE) ✨ Nuevo                    │
│      └─ Fórmula: engagement_promedio × calidad_menciones           │
│      └─ Mide: Efectividad comunicacional                            │
│                                                                      │
│  ▼                                                                   │
│                                                                      │
│  🏆 ÍNDICE COMPUESTO (Output)                                       │
│  └─ Query 8: Score Global (SG) ✨ Nuevo                            │
│      └─ Fórmula: BP(40%) + IIP(40%) + IE(20%)                      │
│      └─ Mide: Desempeño general integral                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Comparación de Índices

| Índice | Input principal | Ponderación | Ideal para medir |
|--------|----------------|-------------|------------------|
| **BP** (Query 3) | Volumen de menciones | Sentimiento × Muestra | Popularidad y percepción |
| **IIP** (Query 6) | Engagement total | Sentimiento × Engagement | Impacto y viralidad |
| **IE** (Query 7) | Engagement promedio | Eficiencia × Calidad | ROI comunicacional |
| **SG** (Query 8) | BP + IIP + IE | 40% + 40% + 20% | Ranking integral |

---

## ⏱️ Consideraciones de Análisis Temporal

### Contexto del Requerimiento

**Necesidad crítica:** Los índices se presentarán **semanalmente** y **mensualmente**, requiriendo:

1. **Agregación flexible** (semanal vs mensual)
2. **Comparación histórica** (variación vs. periodo anterior)
3. **Series de tiempo** (tendencias y proyecciones futuras)

### Implicaciones en el Diseño

#### 1. Estructura de Datos Temporal

Para soportar análisis histórico y series de tiempo, es **recomendable** crear una **tabla de historial de índices**:

```sql
CREATE TABLE IF NOT EXISTS indices_historico (
  historico_id SERIAL PRIMARY KEY,
  actor TEXT NOT NULL,
  periodo_inicio DATE NOT NULL,
  periodo_fin DATE NOT NULL,
  tipo_periodo TEXT NOT NULL,  -- 'semanal', 'mensual'

  -- Métricas base
  menciones_total INT,
  engagement_total NUMERIC,

  -- Índices calculados
  balance_ponderado NUMERIC,
  indice_impacto_ponderado NUMERIC,
  indice_eficiencia NUMERIC,
  score_global NUMERIC,

  -- Metadata
  calculado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fuente_sistema TEXT,

  -- Constraint para evitar duplicados
  UNIQUE(actor, periodo_inicio, periodo_fin, tipo_periodo)
);

-- Índices para consultas eficientes
CREATE INDEX IF NOT EXISTS ix_historico_actor_periodo
ON indices_historico (actor, tipo_periodo, periodo_inicio DESC);

CREATE INDEX IF NOT EXISTS ix_historico_periodo
ON indices_historico (tipo_periodo, periodo_inicio DESC);
```

**Ventajas:**
- ✅ Comparación histórica rápida (sin recalcular)
- ✅ Series de tiempo eficientes
- ✅ Análisis de tendencias y pronósticos
- ✅ Auditoría completa de cambios

#### 2. Granularidad Temporal

**Semanas:**
- Inicio: Lunes
- Fin: Domingo
- Función SQL: `DATE_TRUNC('week', fecha)`

**Meses:**
- Inicio: Día 1
- Fin: Último día del mes
- Función SQL: `DATE_TRUNC('month', fecha)`

#### 3. Estrategia de Implementación

**Opción A: Vista Materializada por Periodo** (Recomendado)

Crear vista materializada que se refresca semanalmente:

```sql
CREATE MATERIALIZED VIEW mv_indices_semanales AS
SELECT
  actor,
  DATE_TRUNC('week', periodo)::DATE AS semana_inicio,
  (DATE_TRUNC('week', periodo) + INTERVAL '6 days')::DATE AS semana_fin,
  'semanal' AS tipo_periodo,
  balance_ponderado,
  indice_impacto_ponderado,
  indice_eficiencia,
  score_global,
  menciones_total,
  engagement_total
FROM (
  -- Subquery con cálculo de índices por semana
  -- [Similar a Query 8 pero agrupando por semana]
) indices_calculados;

-- Refrescar automáticamente cada lunes
CREATE OR REPLACE FUNCTION refresh_indices_semanales()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW mv_indices_semanales;

  -- Insertar en histórico
  INSERT INTO indices_historico
  SELECT
    nextval('indices_historico_historico_id_seq'),
    actor, semana_inicio, semana_fin, tipo_periodo,
    menciones_total, engagement_total,
    balance_ponderado, indice_impacto_ponderado, indice_eficiencia, score_global,
    NOW(), 'etl_automatico'
  FROM mv_indices_semanales
  ON CONFLICT (actor, periodo_inicio, periodo_fin, tipo_periodo)
  DO UPDATE SET
    menciones_total = EXCLUDED.menciones_total,
    engagement_total = EXCLUDED.engagement_total,
    balance_ponderado = EXCLUDED.balance_ponderado,
    indice_impacto_ponderado = EXCLUDED.indice_impacto_ponderado,
    indice_eficiencia = EXCLUDED.indice_eficiencia,
    score_global = EXCLUDED.score_global,
    calculado_en = NOW();
END;
$$ LANGUAGE plpgsql;
```

**Opción B: Proceso ETL Dedicado** (Alternativa)

Script Python que calcula y guarda índices semanalmente:

```python
# etl_indices_historico.py
def calcular_indices_periodo(periodo_inicio, periodo_fin, tipo_periodo):
    """
    Calcula índices para un periodo específico y los guarda en histórico
    """
    # Ejecutar Query 8 con filtro de fechas
    # Guardar en indices_historico
    pass

def procesar_semana_actual():
    hoy = datetime.now()
    inicio_semana = hoy - timedelta(days=hoy.weekday())  # Lunes
    fin_semana = inicio_semana + timedelta(days=6)  # Domingo

    calcular_indices_periodo(inicio_semana, fin_semana, 'semanal')

def procesar_mes_actual():
    hoy = datetime.now()
    inicio_mes = hoy.replace(day=1)
    fin_mes = (inicio_mes + timedelta(days=32)).replace(day=1) - timedelta(days=1)

    calcular_indices_periodo(inicio_mes, fin_mes, 'mensual')
```

### Impacto en las Queries

#### Modificación Necesaria: Parámetro de Granularidad

Todas las queries de índices (6, 7, 8) deben soportar **agrupación temporal**:

```sql
-- Variable adicional: {{granularidad}}
-- Valores: 'dia', 'semana', 'mes'

-- Ejemplo en Query 8 modificado:
WITH periodo_calc AS (
  SELECT
    CASE {{granularidad}}
      WHEN 'dia' THEN DATE_TRUNC('day', m.published_at)::DATE
      WHEN 'semana' THEN DATE_TRUNC('week', m.published_at)::DATE
      WHEN 'mes' THEN DATE_TRUNC('month', m.published_at)::DATE
    END AS periodo,
    t.tag_name AS actor,
    -- ... resto de métricas
  FROM mentions m
  -- ... resto del query
  GROUP BY periodo, actor
)
SELECT
  periodo,
  actor,
  balance_ponderado,
  indice_impacto_ponderado,
  indice_eficiencia,
  score_global
FROM periodo_calc
ORDER BY periodo DESC, score_global DESC;
```

### Queries de Comparación Histórica

Estas queries serán **críticas** para mostrar variaciones semana a semana o mes a mes:

```sql
-- Query 9: Variación de Índices vs. Periodo Anterior
WITH periodo_actual AS (
  SELECT *
  FROM indices_historico
  WHERE tipo_periodo = 'semanal'
    AND periodo_inicio = (SELECT MAX(periodo_inicio)
                          FROM indices_historico
                          WHERE tipo_periodo = 'semanal')
),
periodo_anterior AS (
  SELECT *
  FROM indices_historico
  WHERE tipo_periodo = 'semanal'
    AND periodo_inicio = (SELECT MAX(periodo_inicio)
                          FROM indices_historico
                          WHERE tipo_periodo = 'semanal'
                            AND periodo_inicio < (SELECT MAX(periodo_inicio)
                                                  FROM indices_historico
                                                  WHERE tipo_periodo = 'semanal'))
)
SELECT
  pa.actor,

  -- Valores actuales
  pa.score_global AS score_actual,
  pa.balance_ponderado AS bp_actual,
  pa.indice_impacto_ponderado AS iip_actual,
  pa.indice_eficiencia AS ie_actual,

  -- Valores anteriores
  pp.score_global AS score_anterior,
  pp.balance_ponderado AS bp_anterior,
  pp.indice_impacto_ponderado AS iip_anterior,
  pp.indice_eficiencia AS ie_anterior,

  -- Variaciones absolutas
  (pa.score_global - pp.score_global) AS variacion_score,
  (pa.balance_ponderado - pp.balance_ponderado) AS variacion_bp,
  (pa.indice_impacto_ponderado - pp.indice_impacto_ponderado) AS variacion_iip,
  (pa.indice_eficiencia - pp.indice_eficiencia) AS variacion_ie,

  -- Variaciones porcentuales
  ROUND(100.0 * (pa.score_global - pp.score_global) / NULLIF(pp.score_global, 0), 1) AS pct_cambio_score,
  ROUND(100.0 * (pa.balance_ponderado - pp.balance_ponderado) / NULLIF(pp.balance_ponderado, 0), 1) AS pct_cambio_bp,

  -- Tendencia
  CASE
    WHEN (pa.score_global - pp.score_global) > 5 THEN '📈 Mejora significativa'
    WHEN (pa.score_global - pp.score_global) > 0 THEN '↗️ Mejora'
    WHEN (pa.score_global - pp.score_global) = 0 THEN '➡️ Sin cambio'
    WHEN (pa.score_global - pp.score_global) > -5 THEN '↘️ Deterioro'
    ELSE '📉 Deterioro significativo'
  END AS tendencia,

  -- Periodos comparados
  pp.periodo_inicio || ' a ' || pp.periodo_fin AS periodo_anterior_label,
  pa.periodo_inicio || ' a ' || pa.periodo_fin AS periodo_actual_label

FROM periodo_actual pa
LEFT JOIN periodo_anterior pp ON pp.actor = pa.actor
ORDER BY variacion_score DESC;
```

### Queries para Series de Tiempo y Pronósticos

```sql
-- Query 10: Serie de Tiempo de Índices (últimas 12 semanas)
SELECT
  periodo_inicio,
  actor,
  score_global,

  -- Media móvil de 4 semanas
  AVG(score_global) OVER (
    PARTITION BY actor
    ORDER BY periodo_inicio
    ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
  ) AS media_movil_4sem,

  -- Tendencia (regresión lineal simple)
  REGR_SLOPE(score_global,
             EXTRACT(EPOCH FROM periodo_inicio)) OVER (
    PARTITION BY actor
    ORDER BY periodo_inicio
    ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
  ) AS tendencia_pendiente,

  -- Volatilidad (desviación estándar de últimas 4 semanas)
  STDDEV(score_global) OVER (
    PARTITION BY actor
    ORDER BY periodo_inicio
    ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
  ) AS volatilidad

FROM indices_historico
WHERE tipo_periodo = 'semanal'
  AND periodo_inicio >= CURRENT_DATE - INTERVAL '12 weeks'
  [[AND {{actor}}]]
ORDER BY actor, periodo_inicio DESC;
```

```sql
-- Query 11: Proyección Simple (próxima semana)
-- Método: Media móvil ponderada + tendencia
WITH ultimas_semanas AS (
  SELECT
    actor,
    periodo_inicio,
    score_global,
    ROW_NUMBER() OVER (PARTITION BY actor ORDER BY periodo_inicio DESC) AS semana_num
  FROM indices_historico
  WHERE tipo_periodo = 'semanal'
    AND periodo_inicio >= CURRENT_DATE - INTERVAL '8 weeks'
),
tendencia AS (
  SELECT
    actor,
    -- Promedio ponderado (semanas más recientes pesan más)
    SUM(score_global * (9 - semana_num)) / SUM(9 - semana_num) AS score_promedio_ponderado,

    -- Tendencia lineal
    REGR_SLOPE(score_global, semana_num) AS pendiente
  FROM ultimas_semanas
  WHERE semana_num <= 8
  GROUP BY actor
)
SELECT
  actor,
  score_promedio_ponderado AS score_actual,

  -- Proyección para próxima semana
  ROUND(score_promedio_ponderado + (pendiente * -1), 1) AS proyeccion_proxima_semana,

  -- Confianza de la proyección (basada en volatilidad)
  CASE
    WHEN ABS(pendiente) < 0.5 THEN 'Alta confianza (estable)'
    WHEN ABS(pendiente) < 2 THEN 'Media confianza (tendencia moderada)'
    ELSE 'Baja confianza (alta volatilidad)'
  END AS confianza_proyeccion,

  -- Clasificación de tendencia
  CASE
    WHEN pendiente > 2 THEN '📈 Tendencia alcista fuerte'
    WHEN pendiente > 0.5 THEN '↗️ Tendencia alcista'
    WHEN pendiente > -0.5 THEN '➡️ Estable'
    WHEN pendiente > -2 THEN '↘️ Tendencia bajista'
    ELSE '📉 Tendencia bajista fuerte'
  END AS tipo_tendencia

FROM tendencia
ORDER BY proyeccion_proxima_semana DESC;
```

### Dashboard Temporal Recomendado en Metabase

```
┌────────────────────────────────────────────────────────────┐
│  Análisis Temporal de Índices                              │
├────────────────────────────────────────────────────────────┤
│  Filtros: [Periodo ▼] [Actor ▼] [Granularidad ▼]         │
├────────────────────────────────────────────────────────────┤
│  🔄 Query 9: Comparación vs. Periodo Anterior              │
│  ┌────────┬────────┬───────┬─────────┬──────────┐         │
│  │ Actor  │ Actual │ Anter.│ Variación│Tendencia │         │
│  ├────────┼────────┼───────┼─────────┼──────────┤         │
│  │ Actor1 │  75.2  │ 68.1  │  +7.1   │ 📈       │         │
│  └────────┴────────┴───────┴─────────┴──────────┘         │
├────────────────────────────────────────────────────────────┤
│  📈 Query 10: Serie de Tiempo (últimas 12 semanas)         │
│  [Gráfico de líneas con tendencia]                         │
├────────────────────────────────────────────────────────────┤
│  🔮 Query 11: Proyección Próxima Semana                    │
│  [Tabla con proyecciones y confianza]                      │
└────────────────────────────────────────────────────────────┘
```

### Consideraciones para Pronósticos

**Métodos Recomendados (en orden de complejidad):**

1. **Media Móvil Ponderada** ✅ Implementado arriba
   - Simple y rápido
   - Bueno para tendencias cortas
   - Funciona bien con SQL nativo

2. **Regresión Lineal** ✅ Implementado arriba
   - PostgreSQL soporta funciones REGR_*
   - Identifica tendencias claras

3. **ARIMA/Prophet** (requiere Python/R)
   - Más preciso
   - Requiere procesamiento externo
   - Recomendado para análisis profundo

**Implementación sugerida:**

```python
# etl_pronostico.py
from fbprophet import Prophet
import pandas as pd

def generar_pronostico_actor(actor, semanas_futuras=4):
    """
    Genera pronóstico usando Facebook Prophet
    """
    # Cargar histórico desde PostgreSQL
    df = pd.read_sql(f"""
        SELECT periodo_inicio as ds, score_global as y
        FROM indices_historico
        WHERE actor = '{actor}' AND tipo_periodo = 'semanal'
        ORDER BY periodo_inicio
    """, conn)

    # Entrenar modelo
    model = Prophet(weekly_seasonality=True)
    model.fit(df)

    # Generar pronóstico
    future = model.make_future_dataframe(periods=semanas_futuras, freq='W')
    forecast = model.predict(future)

    return forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']]
```

### Recomendaciones de Implementación

**Fase Inicial:**
1. Implementar tabla `indices_historico`
2. Crear Query 9 (Comparación vs. anterior)
3. Implementar proceso semanal de cálculo

**Fase Intermedia:**
4. Crear Query 10 (Series de tiempo)
5. Implementar agregación mensual
6. Dashboard temporal en Metabase

**Fase Avanzada:**
7. Implementar Query 11 (Proyección simple)
8. Integrar Prophet para pronósticos avanzados
9. Alertas automáticas de cambios significativos

---

## 🚀 Fase 1: Query 6 - Índice de Impacto Ponderado

### Objetivo

Crear un índice que mida la **resonancia digital real** de cada actor, similar al Balance Ponderado (Query 3) pero usando engagement en lugar de conteo de menciones.

### Concepto

**Analogía con Query 3:**
- Query 3 mide: "¿Qué tan bien percibido es el actor según el VOLUMEN de menciones?"
- Query 6 mide: "¿Qué tan bien percibido es el actor según el ENGAGEMENT generado?"

### SQL Completo

```sql
-- ============================================================================
-- Query 6: Índice de Impacto Ponderado (IIP)
-- ============================================================================
-- Mide la resonancia digital real usando engagement como métrica de impacto
-- Análogo al Query 3 (Balance Ponderado) pero con engagement en vez de conteo
-- ============================================================================

WITH base_metrics AS (
  -- Paso 1: Calcular métricas base por actor
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
    AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
    [[AND {{actor}}]]
    [[AND {{fecha}}]]
    [[AND {{source_system}}]]
    [[AND {{source_type}}]]
  GROUP BY t.tag_name
),
indices_base AS (
  -- Paso 2: Calcular balance de engagement (análogo a balance_opinion)
  SELECT
    actor,
    menciones_total,
    engagement_total,
    engagement_positivo,
    engagement_negativo,
    engagement_neutral,

    -- Balance de Engagement (0-100)
    -- Similar a balance_opinion pero usando engagement en vez de conteo
    ROUND(
      100.0 * engagement_positivo / NULLIF(engagement_positivo + engagement_negativo, 0),
      1
    ) AS balance_engagement,

    -- Engagement polarizado (sin neutrales) para ponderación
    (engagement_positivo + engagement_negativo) AS engagement_polarizado
  FROM base_metrics
),
normalizacion AS (
  -- Paso 3: Encontrar el engagement polarizado máximo para normalización
  SELECT MAX(engagement_polarizado) AS max_engagement_polarizado
  FROM indices_base
)
SELECT
  i.actor,
  i.menciones_total,
  i.engagement_total,
  i.engagement_positivo,
  i.engagement_negativo,
  i.engagement_neutral,
  i.balance_engagement,
  i.engagement_polarizado,

  -- ÍNDICE DE IMPACTO PONDERADO (IIP)
  -- Fórmula: balance_engagement × (engagement_polarizado / max_engagement_polarizado)
  -- Análogo exacto al balance_ponderado del Query 3
  ROUND(
    i.balance_engagement * (i.engagement_polarizado::NUMERIC / NULLIF(n.max_engagement_polarizado, 0)),
    1
  ) AS indice_impacto_ponderado,

  -- Nivel de confianza del índice (basado en tamaño de muestra de engagement)
  CASE
    WHEN i.engagement_polarizado < 1000 THEN 'Baja confianza'
    WHEN i.engagement_polarizado < 10000 THEN 'Media confianza'
    ELSE 'Alta confianza'
  END AS confianza_indice,

  -- Clasificación cualitativa del impacto
  CASE
    WHEN ROUND(i.balance_engagement * (i.engagement_polarizado::NUMERIC / NULLIF(n.max_engagement_polarizado, 0)), 1) >= 70
      THEN 'Muy positivo'
    WHEN ROUND(i.balance_engagement * (i.engagement_polarizado::NUMERIC / NULLIF(n.max_engagement_polarizado, 0)), 1) >= 55
      THEN 'Positivo'
    WHEN ROUND(i.balance_engagement * (i.engagement_polarizado::NUMERIC / NULLIF(n.max_engagement_polarizado, 0)), 1) >= 45
      THEN 'Neutral'
    WHEN ROUND(i.balance_engagement * (i.engagement_polarizado::NUMERIC / NULLIF(n.max_engagement_polarizado, 0)), 1) >= 30
      THEN 'Negativo'
    ELSE 'Muy negativo'
  END AS nivel_impacto,

  -- Porcentaje del engagement que es positivo (métrica auxiliar)
  ROUND(100.0 * i.engagement_positivo / NULLIF(i.engagement_total, 0), 1) AS pct_engagement_positivo

FROM indices_base i
CROSS JOIN normalizacion n
WHERE i.engagement_polarizado > 0  -- Excluir actores sin engagement polarizado
ORDER BY indice_impacto_ponderado DESC NULLS LAST;
```

### Interpretación de Resultados

| Columna | Rango | Interpretación |
|---------|-------|----------------|
| `balance_engagement` | 0-100 | % de engagement polarizado que es positivo (sin ponderar por volumen) |
| `indice_impacto_ponderado` | 0-100 | Balance ponderado por volumen de engagement (métrica principal) |
| `confianza_indice` | Categoría | Nivel de confianza estadística del índice |
| `nivel_impacto` | Categoría | Clasificación cualitativa del impacto |

**Umbrales de interpretación:**

- **70-100:** Impacto muy positivo (alto engagement positivo + alto volumen)
- **55-69:** Impacto positivo
- **45-54:** Impacto neutral/balanceado
- **30-44:** Impacto negativo
- **0-29:** Impacto muy negativo

### Pasos de Implementación

#### 1.1. Agregar a CLAUDE.md

```bash
# Abrir CLAUDE.md en el editor
code docs/CLAUDE.md
```

Agregar después del Query 5 (línea ~670):

```markdown
---

### Query 6: Índice de Impacto Ponderado

#### 🎯 Objetivo

Medir la **resonancia digital real** de cada actor político mediante un índice que combina engagement y sentimiento, análogo al Balance Ponderado (Query 3) pero usando engagement en lugar de volumen de menciones.

#### 🧠 Qué responde esta métrica

- ¿Qué actor genera mayor impacto digital real (no solo volumen)?
- ¿El engagement es mayormente positivo o negativo?
- ¿Qué actor tiene mejor combinación de engagement positivo y volumen?

#### 💡 Casos de uso

- Ranking de actores por impacto digital real
- Comparación objetiva considerando tanto calidad como cantidad de engagement
- Identificar actores con alto engagement pero percepción negativa
- Validar si el volumen de menciones (Query 3) se traduce en engagement real

#### 📊 SQL

[Copiar el SQL completo de arriba]

#### 📝 Notas técnicas

- **Analogía con Query 3:** Usa la misma metodología que balance_ponderado pero con engagement
- **LEFT JOIN metrics:** Incluye menciones sin engagement (tratadas como 0)
- **engagement_polarizado:** Solo engagement de menciones positivas/negativas (excluye neutrales)
- **Normalización:** El actor con mayor engagement_polarizado obtiene el IIP máximo
- **Confianza:** Basada en volumen de engagement polarizado, no en número de menciones

#### 🔄 Diferencia con Query 3 (Balance Ponderado)

| Aspecto | Query 3 (BP) | Query 6 (IIP) |
|---------|--------------|---------------|
| Métrica base | Conteo de menciones | Engagement total |
| Muestra | Menciones pos/neg | Engagement pos/neg |
| Mide | Percepción según volumen | Resonancia según engagement |
| Ideal para | Popularidad | Impacto viral real |
```

#### 1.2. Agregar a SQL_QUERIES_METABASE.md

Agregar después de Query 5:

```markdown
---

## 📊 Query 6: Índice de Impacto Ponderado

**Nombre sugerido:** "Índice de Impacto - Resonancia digital"

**Variables a configurar:** `{{actor}}`, `{{fecha}}`, `{{source_system}}`, `{{source_type}}`

**✨ NUEVA QUERY - Análoga a Query 3 pero con engagement**

**SQL:**

[Copiar SQL completo]

**Visualización recomendada:** Tabla ordenada por `indice_impacto_ponderado` DESC

**Interpretación:**
- Similar al Balance Ponderado (Query 3) pero mide impacto digital real
- Rango 0-100: mayor valor = mayor impacto positivo con engagement
- Confianza del índice basada en volumen de engagement

**Comparación con Query 3:**
- Query 3: ¿Qué tan bien es percibido según menciones?
- Query 6: ¿Qué tan bien es percibido según engagement?
```

#### 1.3. Probar en base de datos

```bash
# Conectar a PostgreSQL
docker-compose exec db psql -U youscan_admin -d youscan

# Pegar y ejecutar el SQL del Query 6
# Verificar que retorna resultados coherentes
```

#### 1.4. Crear en Metabase

1. Nueva pregunta → SQL nativo
2. Pegar SQL completo
3. Configurar 4 variables (actor, fecha, source_system, source_type)
4. Configurar visualización como Tabla
5. Guardar como "Índice de Impacto - Resonancia digital"

### Validación Fase 1

- [ ] SQL ejecuta sin errores
- [ ] Retorna datos para todos los actores con engagement > 0
- [ ] `balance_engagement` está entre 0-100
- [ ] `indice_impacto_ponderado` está entre 0-100
- [ ] Actores con más engagement positivo tienen IIP más alto
- [ ] Query agregada a CLAUDE.md
- [ ] Query agregada a SQL_QUERIES_METABASE.md
- [ ] Query creada en Metabase
- [ ] Variables funcionan correctamente

---

## 🎯 Fase 2: Query 7 - Índice de Eficiencia

### Objetivo

Crear un índice que mida la **efectividad comunicacional** de cada actor, respondiendo: "¿Qué tan efectivas son sus menciones para generar engagement?"

### Concepto

**Mide la relación engagement/mención:**
- Actor con pocas menciones pero alto engagement = Muy eficiente
- Actor con muchas menciones pero bajo engagement = Poco eficiente

### SQL Completo

```sql
-- ============================================================================
-- Query 7: Índice de Eficiencia (IE)
-- ============================================================================
-- Mide la efectividad comunicacional: engagement promedio + calidad menciones
-- Responde: ¿Qué tan efectivas son las menciones de cada actor?
-- ============================================================================

WITH base_metrics AS (
  -- Paso 1: Calcular métricas base por actor
  SELECT
    t.tag_name AS actor,
    COUNT(*) AS menciones_total,
    SUM(COALESCE(me.engagement, 0)) AS engagement_total,

    -- Menciones y engagement por sentimiento
    SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS menciones_positivas,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS menciones_negativas,
    SUM(CASE WHEN m.sentiment = 'Neutral' THEN 1 ELSE 0 END) AS menciones_neutrales,

    SUM(CASE WHEN m.sentiment = 'Positivo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_positivo,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_negativo

  FROM mention_occurrences o
  JOIN mentions m ON m.mention_id = o.mention_id
  LEFT JOIN metrics me ON me.mention_id = m.mention_id
  JOIN mention_tags mt ON mt.mention_id = o.mention_id
  JOIN tags t ON t.tag_id = mt.tag_id
  WHERE t.tag_type = 'actor'
    AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
    [[AND {{actor}}]]
    [[AND {{fecha}}]]
    [[AND {{source_system}}]]
    [[AND {{source_type}}]]
  GROUP BY t.tag_name
),
indices_base AS (
  -- Paso 2: Calcular índices de eficiencia
  SELECT
    actor,
    menciones_total,
    menciones_positivas,
    menciones_negativas,
    menciones_neutrales,
    engagement_total,
    engagement_positivo,
    engagement_negativo,

    -- Índice 1: Engagement promedio por mención
    ROUND(engagement_total::NUMERIC / NULLIF(menciones_total, 0), 1) AS engagement_promedio,

    -- Índice 2: % de menciones positivas (calidad de menciones)
    ROUND(100.0 * menciones_positivas / NULLIF(menciones_total, 0), 1) AS pct_menciones_positivas,

    -- Métrica auxiliar: Engagement promedio en menciones positivas
    ROUND(engagement_positivo::NUMERIC / NULLIF(menciones_positivas, 0), 1) AS engagement_promedio_positivo
  FROM base_metrics
  WHERE menciones_total >= 10  -- Filtrar actores con muy pocas menciones (outliers)
),
normalizacion AS (
  -- Paso 3: Encontrar valores máximos para normalización
  SELECT
    MAX(engagement_promedio) AS max_eng_promedio,
    MAX(pct_menciones_positivas) AS max_pct_positivas
  FROM indices_base
)
SELECT
  i.actor,
  i.menciones_total,
  i.engagement_total,
  i.engagement_promedio,
  i.pct_menciones_positivas,
  i.engagement_promedio_positivo,

  -- ÍNDICE DE EFICIENCIA (IE)
  -- Fórmula: engagement_promedio_normalizado(50%) + pct_menciones_positivas_normalizado(50%)
  ROUND(
    (
      -- Componente 1 (50%): Engagement promedio normalizado (0-100)
      (100.0 * i.engagement_promedio / NULLIF(n.max_eng_promedio, 0)) * 0.5 +

      -- Componente 2 (50%): % menciones positivas normalizado (0-100)
      (100.0 * i.pct_menciones_positivas / NULLIF(n.max_pct_positivas, 0)) * 0.5
    ),
    1
  ) AS indice_eficiencia,

  -- Clasificación cualitativa
  CASE
    WHEN ROUND((
      (100.0 * i.engagement_promedio / NULLIF(n.max_eng_promedio, 0)) * 0.5 +
      (100.0 * i.pct_menciones_positivas / NULLIF(n.max_pct_positivas, 0)) * 0.5
    ), 1) >= 75 THEN 'Muy eficiente'
    WHEN ROUND((
      (100.0 * i.engagement_promedio / NULLIF(n.max_eng_promedio, 0)) * 0.5 +
      (100.0 * i.pct_menciones_positivas / NULLIF(n.max_pct_positivas, 0)) * 0.5
    ), 1) >= 60 THEN 'Eficiente'
    WHEN ROUND((
      (100.0 * i.engagement_promedio / NULLIF(n.max_eng_promedio, 0)) * 0.5 +
      (100.0 * i.pct_menciones_positivas / NULLIF(n.max_pct_positivas, 0)) * 0.5
    ), 1) >= 45 THEN 'Moderadamente eficiente'
    ELSE 'Poco eficiente'
  END AS nivel_eficiencia,

  -- Indicador de confianza (basado en volumen de menciones)
  CASE
    WHEN i.menciones_total < 50 THEN 'Baja confianza'
    WHEN i.menciones_total < 200 THEN 'Media confianza'
    ELSE 'Alta confianza'
  END AS confianza_indice

FROM indices_base i
CROSS JOIN normalizacion n
ORDER BY indice_eficiencia DESC;
```

### Interpretación de Resultados

| Columna | Rango/Tipo | Interpretación |
|---------|------------|----------------|
| `engagement_promedio` | Numérico | Engagement promedio por mención (métrica cruda) |
| `pct_menciones_positivas` | 0-100 | % de menciones que son positivas |
| `indice_eficiencia` | 0-100 | Índice normalizado de eficiencia comunicacional |
| `nivel_eficiencia` | Categoría | Clasificación cualitativa |

**Casos de uso:**

1. **Alto IE, bajo BP:** Actor eficiente pero poco mencionado
2. **Bajo IE, alto BP:** Actor muy mencionado pero ineficiente
3. **Alto IE, alto BP:** Actor líder en todos los aspectos

### Pasos de Implementación

#### 2.1. Agregar a CLAUDE.md

Agregar después del Query 6:

```markdown
---

### Query 7: Índice de Eficiencia

#### 🎯 Objetivo

Medir la **efectividad comunicacional** de cada actor político mediante un índice que combina engagement promedio por mención y calidad de las menciones (% positivas).

#### 🧠 Qué responde esta métrica

- ¿Qué actor es más eficiente comunicacionalmente?
- ¿Quién logra más engagement con menos menciones?
- ¿Qué actor tiene mejor ROI comunicacional?

#### 💡 Casos de uso

- Identificar actores eficientes vs. ineficientes
- Optimizar estrategias de comunicación digital
- Detectar actores que generan alto impacto con pocas menciones
- Comparar eficiencia entre actores con diferente volumen

#### 📊 SQL

[Copiar SQL completo]

#### 📝 Notas técnicas

- **Filtro de outliers:** Solo actores con ≥10 menciones
- **Dos componentes:** Engagement promedio (50%) + Calidad menciones (50%)
- **Normalización:** Ambos componentes se normalizan a 0-100 antes de combinar
- **Confianza:** Basada en volumen de menciones (>200 = alta confianza)

#### 🎯 Escenarios típicos

| Escenario | Engagement promedio | % Menciones positivas | IE | Interpretación |
|-----------|---------------------|----------------------|-----|----------------|
| A | Alto | Alto | ~100 | Muy eficiente y positivo |
| B | Alto | Bajo | ~50 | Eficiente pero negativo |
| C | Bajo | Alto | ~50 | Positivo pero poco viral |
| D | Bajo | Bajo | ~0 | Poco eficiente y negativo |
```

#### 2.2. Agregar a SQL_QUERIES_METABASE.md

#### 2.3. Probar en base de datos

#### 2.4. Crear en Metabase

### Validación Fase 2

- [ ] SQL ejecuta sin errores
- [ ] Solo incluye actores con ≥10 menciones
- [ ] `engagement_promedio` es razonable (>0)
- [ ] `pct_menciones_positivas` está entre 0-100
- [ ] `indice_eficiencia` está entre 0-100
- [ ] Query agregada a CLAUDE.md
- [ ] Query agregada a SQL_QUERIES_METABASE.md
- [ ] Query creada en Metabase
- [ ] Variables funcionan correctamente

---

## 🏆 Fase 3: Query 8 - Score Global

### Objetivo

Crear un **índice compuesto único** que combine los 3 índices especializados (BP, IIP, IE) en un score global que represente el desempeño integral de cada actor.

### Concepto

**Fórmula del Score Global:**
```
SG = (Balance Ponderado × 40%) +
     (Índice de Impacto × 40%) +
     (Índice de Eficiencia × 20%)
```

**Pesos justificados:**
- **40% BP:** Percepción pública es crítica
- **40% IIP:** Impacto digital es igualmente importante
- **20% IE:** Eficiencia es un bonus, no el objetivo principal

### SQL Completo

```sql
-- ============================================================================
-- Query 8: Score Global (SG)
-- ============================================================================
-- Combina los 3 índices especializados en un score único
-- SG = BP(40%) + IIP(40%) + IE(20%)
-- ============================================================================

WITH balance_ponderado AS (
  -- Subquery: Resultado del Query 3 (Balance Ponderado)
  SELECT
    actor,
    positivas,
    negativas,
    neutrales,
    total,
    muestra,
    balance_opinion,
    balance_ponderado
  FROM (
    SELECT
      t.tag_name AS actor,
      SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS positivas,
      SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS negativas,
      SUM(CASE WHEN m.sentiment = 'Neutral' THEN 1 ELSE 0 END) AS neutrales,
      COUNT(*) AS total,
      SUM(CASE WHEN m.sentiment IN ('Positivo', 'Negativo') THEN 1 ELSE 0 END) AS muestra,
      ROUND(
        100.0 * SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) /
        NULLIF(SUM(CASE WHEN m.sentiment IN ('Positivo', 'Negativo') THEN 1 ELSE 0 END), 0),
        1
      ) AS balance_opinion,
      ROUND(
        100.0 * SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) /
        NULLIF(SUM(CASE WHEN m.sentiment IN ('Positivo', 'Negativo') THEN 1 ELSE 0 END), 0) *
        (1 - EXP(-SUM(CASE WHEN m.sentiment IN ('Positivo', 'Negativo') THEN 1 ELSE 0 END)::FLOAT / 100.0)),
        1
      ) AS balance_ponderado
    FROM mention_occurrences o
    JOIN mentions m ON m.mention_id = o.mention_id
    JOIN mention_tags mt ON mt.mention_id = o.mention_id
    JOIN tags t ON t.tag_id = mt.tag_id
    WHERE t.tag_type = 'actor'
      AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
      [[AND {{actor}}]]
      [[AND {{fecha}}]]
      [[AND {{source_system}}]]
      [[AND {{source_type}}]]
    GROUP BY t.tag_name
  ) subq
),
indice_impacto AS (
  -- Subquery: Resultado del Query 6 (Índice de Impacto Ponderado)
  WITH base_metrics AS (
    SELECT
      t.tag_name AS actor,
      SUM(CASE WHEN m.sentiment = 'Positivo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_positivo,
      SUM(CASE WHEN m.sentiment = 'Negativo' THEN COALESCE(me.engagement, 0) ELSE 0 END) AS engagement_negativo,
      SUM(COALESCE(me.engagement, 0)) AS engagement_total
    FROM mention_occurrences o
    JOIN mentions m ON m.mention_id = o.mention_id
    LEFT JOIN metrics me ON me.mention_id = m.mention_id
    JOIN mention_tags mt ON mt.mention_id = o.mention_id
    JOIN tags t ON t.tag_id = mt.tag_id
    WHERE t.tag_type = 'actor'
      AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
      [[AND {{actor}}]]
      [[AND {{fecha}}]]
      [[AND {{source_system}}]]
      [[AND {{source_type}}]]
    GROUP BY t.tag_name
  ),
  indices_base AS (
    SELECT
      actor,
      engagement_total,
      ROUND(
        100.0 * engagement_positivo / NULLIF(engagement_positivo + engagement_negativo, 0),
        1
      ) AS balance_engagement,
      (engagement_positivo + engagement_negativo) AS engagement_polarizado
    FROM base_metrics
  ),
  normalizacion AS (
    SELECT MAX(engagement_polarizado) AS max_engagement_polarizado
    FROM indices_base
  )
  SELECT
    i.actor,
    i.engagement_total,
    ROUND(
      i.balance_engagement * (i.engagement_polarizado::NUMERIC / NULLIF(n.max_engagement_polarizado, 0)),
      1
    ) AS indice_impacto_ponderado
  FROM indices_base i
  CROSS JOIN normalizacion n
  WHERE i.engagement_polarizado > 0
),
indice_eficiencia AS (
  -- Subquery: Resultado del Query 7 (Índice de Eficiencia)
  WITH base_metrics AS (
    SELECT
      t.tag_name AS actor,
      COUNT(*) AS menciones_total,
      SUM(COALESCE(me.engagement, 0)) AS engagement_total,
      SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS menciones_positivas
    FROM mention_occurrences o
    JOIN mentions m ON m.mention_id = o.mention_id
    LEFT JOIN metrics me ON me.mention_id = m.mention_id
    JOIN mention_tags mt ON mt.mention_id = o.mention_id
    JOIN tags t ON t.tag_id = mt.tag_id
    WHERE t.tag_type = 'actor'
      AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
      [[AND {{actor}}]]
      [[AND {{fecha}}]]
      [[AND {{source_system}}]]
      [[AND {{source_type}}]]
    GROUP BY t.tag_name
  ),
  indices_base AS (
    SELECT
      actor,
      menciones_total,
      ROUND(engagement_total::NUMERIC / NULLIF(menciones_total, 0), 1) AS engagement_promedio,
      ROUND(100.0 * menciones_positivas / NULLIF(menciones_total, 0), 1) AS pct_menciones_positivas
    FROM base_metrics
    WHERE menciones_total >= 10
  ),
  normalizacion AS (
    SELECT
      MAX(engagement_promedio) AS max_eng_promedio,
      MAX(pct_menciones_positivas) AS max_pct_positivas
    FROM indices_base
  )
  SELECT
    i.actor,
    i.menciones_total,
    ROUND(
      (
        (100.0 * i.engagement_promedio / NULLIF(n.max_eng_promedio, 0)) * 0.5 +
        (100.0 * i.pct_menciones_positivas / NULLIF(n.max_pct_positivas, 0)) * 0.5
      ),
      1
    ) AS indice_eficiencia
  FROM indices_base i
  CROSS JOIN normalizacion n
)
SELECT
  bp.actor,

  -- ÍNDICES INDIVIDUALES
  bp.total AS menciones_total,
  bp.balance_ponderado,
  iip.indice_impacto_ponderado,
  ie.indice_eficiencia,

  -- SCORE GLOBAL (SG)
  -- Fórmula: BP(40%) + IIP(40%) + IE(20%)
  ROUND(
    COALESCE(bp.balance_ponderado, 0) * 0.40 +
    COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
    COALESCE(ie.indice_eficiencia, 0) * 0.20,
    1
  ) AS score_global,

  -- Clasificación global
  CASE
    WHEN ROUND(
      COALESCE(bp.balance_ponderado, 0) * 0.40 +
      COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
      COALESCE(ie.indice_eficiencia, 0) * 0.20,
      1
    ) >= 75 THEN '🥇 Excelente'
    WHEN ROUND(
      COALESCE(bp.balance_ponderado, 0) * 0.40 +
      COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
      COALESCE(ie.indice_eficiencia, 0) * 0.20,
      1
    ) >= 60 THEN '🥈 Muy bueno'
    WHEN ROUND(
      COALESCE(bp.balance_ponderado, 0) * 0.40 +
      COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
      COALESCE(ie.indice_eficiencia, 0) * 0.20,
      1
    ) >= 45 THEN '🥉 Bueno'
    WHEN ROUND(
      COALESCE(bp.balance_ponderado, 0) * 0.40 +
      COALESCE(iip.indice_impacto_ponderado, 0) * 0.40 +
      COALESCE(ie.indice_eficiencia, 0) * 0.20,
      1
    ) >= 30 THEN '⚠️ Regular'
    ELSE '❌ Deficiente'
  END AS clasificacion_global,

  -- Métricas de contexto
  bp.positivas,
  bp.negativas,
  bp.neutrales,
  iip.engagement_total

FROM balance_ponderado bp
LEFT JOIN indice_impacto iip ON iip.actor = bp.actor
LEFT JOIN indice_eficiencia ie ON ie.actor = bp.actor
ORDER BY score_global DESC NULLS LAST;
```

### Interpretación del Score Global

| Score Global | Clasificación | Interpretación |
|--------------|---------------|----------------|
| 75-100 | 🥇 Excelente | Líder en percepción, impacto y eficiencia |
| 60-74 | 🥈 Muy bueno | Desempeño sólido en la mayoría de áreas |
| 45-59 | 🥉 Bueno | Desempeño aceptable, con áreas de mejora |
| 30-44 | ⚠️ Regular | Necesita mejorar en múltiples áreas |
| 0-29 | ❌ Deficiente | Bajo desempeño general |

### Análisis de Componentes

El Score Global permite identificar **perfiles de actores**:

| Perfil | BP | IIP | IE | Interpretación |
|--------|----|----|-----|----------------|
| Líder integral | Alto | Alto | Alto | Domina en todos los aspectos |
| Viral negativo | Bajo | Alto | Alto | Alto impacto pero mala percepción |
| Eficiente discreto | Medio | Bajo | Alto | Eficiente pero poco mencionado |
| Popular ineficiente | Alto | Bajo | Bajo | Muy mencionado pero bajo engagement |

### Pasos de Implementación

#### 3.1. Agregar a CLAUDE.md

#### 3.2. Agregar a SQL_QUERIES_METABASE.md

#### 3.3. Probar en base de datos

#### 3.4. Crear en Metabase

Con visualización especial:
- Tipo: Tabla
- Columnas principales: actor, score_global, clasificacion_global
- Formato condicional en score_global:
  - Verde: ≥60
  - Amarillo: 45-59
  - Rojo: <45

### Validación Fase 3

- [ ] SQL ejecuta sin errores
- [ ] Todos los actores con datos aparecen
- [ ] `score_global` está entre 0-100
- [ ] Los 3 índices componentes son visibles
- [ ] Clasificación_global es correcta según umbrales
- [ ] LEFT JOINs manejan correctamente actores con datos faltantes
- [ ] Query agregada a CLAUDE.md
- [ ] Query agregada a SQL_QUERIES_METABASE.md
- [ ] Query creada en Metabase
- [ ] Visualización con formato condicional configurada

---

## 🧪 Fase 4: Validación y Pruebas

### Objetivo

Validar la coherencia, consistencia y utilidad de los 4 índices implementados.

### 4.1. Tests de Coherencia

#### Test 1: Consistencia de Rankings

```sql
-- Verificar que los índices no se contradicen sistemáticamente
SELECT
  actor,
  balance_ponderado,
  indice_impacto_ponderado,
  indice_eficiencia,
  score_global,

  -- Verificar correlación esperada
  CASE
    WHEN balance_ponderado > 70 AND indice_impacto_ponderado < 30
      THEN '⚠️ Inconsistencia: Alto BP pero bajo IIP'
    WHEN balance_ponderado < 30 AND indice_impacto_ponderado > 70
      THEN '⚠️ Inconsistencia: Bajo BP pero alto IIP'
    ELSE '✅ Coherente'
  END AS validacion

FROM [Query 8: Score Global]
ORDER BY score_global DESC;
```

**Criterio de éxito:**
- <10% de actores con inconsistencias marcadas
- Si hay inconsistencias, deben ser explicables (ej: viral negativo)

#### Test 2: Rangos Válidos

```sql
-- Verificar que todos los índices están en rango 0-100
SELECT
  COUNT(*) AS total_actores,
  COUNT(CASE WHEN balance_ponderado < 0 OR balance_ponderado > 100 THEN 1 END) AS bp_fuera_rango,
  COUNT(CASE WHEN indice_impacto_ponderado < 0 OR indice_impacto_ponderado > 100 THEN 1 END) AS iip_fuera_rango,
  COUNT(CASE WHEN indice_eficiencia < 0 OR indice_eficiencia > 100 THEN 1 END) AS ie_fuera_rango,
  COUNT(CASE WHEN score_global < 0 OR score_global > 100 THEN 1 END) AS sg_fuera_rango
FROM [Query 8: Score Global];
```

**Criterio de éxito:**
- Todos los conteos de "fuera_rango" deben ser 0

#### Test 3: Cobertura de Datos

```sql
-- Verificar cuántos actores tienen datos completos
SELECT
  COUNT(*) AS total_actores,
  COUNT(balance_ponderado) AS con_bp,
  COUNT(indice_impacto_ponderado) AS con_iip,
  COUNT(indice_eficiencia) AS con_ie,
  COUNT(CASE WHEN balance_ponderado IS NOT NULL
                  AND indice_impacto_ponderado IS NOT NULL
                  AND indice_eficiencia IS NOT NULL
             THEN 1 END) AS con_datos_completos
FROM [Query 8: Score Global];
```

**Criterio de éxito:**
- >80% de actores con datos completos
- Actores sin IE explicable (filtro de <10 menciones)

### 4.2. Tests de Utilidad

#### Test 4: Diferenciación de Actores

```sql
-- Verificar que los índices diferencian efectivamente a los actores
SELECT
  COUNT(DISTINCT score_global) AS scores_unicos,
  COUNT(*) AS total_actores,
  ROUND(100.0 * COUNT(DISTINCT score_global) / COUNT(*), 1) AS pct_diferenciacion
FROM [Query 8: Score Global];
```

**Criterio de éxito:**
- >50% de diferenciación (no todos tienen el mismo score)

#### Test 5: Comparación con Query 1 y Query 2

```sql
-- Verificar consistencia con queries base
WITH base AS (
  SELECT actor, total FROM [Query 1: Menciones por actor]
),
scores AS (
  SELECT actor, score_global FROM [Query 8: Score Global]
)
SELECT
  b.actor,
  b.total AS menciones,
  s.score_global,
  RANK() OVER (ORDER BY b.total DESC) AS rank_volumen,
  RANK() OVER (ORDER BY s.score_global DESC) AS rank_score,
  ABS(RANK() OVER (ORDER BY b.total DESC) - RANK() OVER (ORDER BY s.score_global DESC)) AS diferencia_ranking
FROM base b
LEFT JOIN scores s ON s.actor = b.actor
ORDER BY diferencia_ranking DESC
LIMIT 10;
```

**Criterio de éxito:**
- Los actores con mayor diferencia_ranking deben tener explicación lógica
- Ej: Alto volumen pero negativo → rank_volumen alto, rank_score bajo

### 4.3. Tests de Performance

#### Test 6: Tiempo de Ejecución

```bash
# Ejecutar cada query con EXPLAIN ANALYZE
docker-compose exec db psql -U youscan_admin -d youscan -c "
EXPLAIN ANALYZE
[Pegar Query 6]
"

# Repetir para Query 7 y Query 8
```

**Criterio de éxito:**
- Query 6: <500ms
- Query 7: <500ms
- Query 8: <1000ms (es más complejo)

### Validación Fase 4

- [ ] Test 1: Coherencia - <10% inconsistencias
- [ ] Test 2: Rangos - 0 valores fuera de rango
- [ ] Test 3: Cobertura - >80% con datos completos
- [ ] Test 4: Diferenciación - >50% scores únicos
- [ ] Test 5: Comparación - Diferencias explicables
- [ ] Test 6: Performance - Tiempos aceptables
- [ ] Resultados documentados en sección de pruebas

---

## 📝 Fase 5: Documentación y Deployment

### Objetivo

Documentar completamente los nuevos índices y preparar el sistema para uso en producción.

### 5.1. Actualizar Documentación Principal

#### Archivos a actualizar:

1. **docs/CLAUDE.md**
   - [ ] Query 6 agregado con documentación completa
   - [ ] Query 7 agregado con documentación completa
   - [ ] Query 8 agregado con documentación completa
   - [ ] Tabla de contenido actualizada
   - [ ] Sección de índices comparativos agregada

2. **docs/SQL_QUERIES_METABASE.md**
   - [ ] Query 6 con SQL listo para copiar
   - [ ] Query 7 con SQL listo para copiar
   - [ ] Query 8 con SQL listo para copiar
   - [ ] Configuración de variables documentada
   - [ ] Visualizaciones recomendadas

3. **README.md**
   - [ ] Sección "Queries Disponibles" actualizada (ahora 8 queries)
   - [ ] Actualizar de "5 queries" a "8 queries"

### 5.2. Crear Documentación Específica de Índices

Crear nuevo archivo: `docs/GUIA_INDICES_AVANZADOS.md`

```markdown
# Guía de Uso: Índices Avanzados

## Introducción

Los índices avanzados (Queries 6-8) complementan el análisis base proporcionando:
- Medición de impacto digital real (engagement)
- Evaluación de eficiencia comunicacional
- Ranking integral unificado

## Cómo Usar los Índices

### Para Analistas Políticos

**Pregunta:** ¿Qué actor tiene mejor desempeño general?
**Respuesta:** Query 8 (Score Global) - Ranking único

**Pregunta:** ¿Quién genera más impacto digital?
**Respuesta:** Query 6 (Índice de Impacto) - Mide engagement × sentimiento

**Pregunta:** ¿Quién es más eficiente comunicacionalmente?
**Respuesta:** Query 7 (Índice de Eficiencia) - Mide engagement/mención

### Para Estrategas de Comunicación

[Continuar con casos de uso específicos...]
```

### 5.3. Crear Dashboard Integrado en Metabase

**Dashboard:** "Índices Avanzados - Desempeño Integral"

**Layout recomendado:**

```
┌────────────────────────────────────────────────────────────┐
│  Filtros: [Actor ▼] [Fecha ▼] [Fuente ▼] [Tipo ▼]        │
├────────────────────────────────────────────────────────────┤
│  🏆 Query 8: Score Global (tabla destacada - grande)       │
│  Columnas: Actor | SG | BP | IIP | IE | Clasificación     │
├──────────────────────────┬─────────────────────────────────┤
│  📊 Query 3:             │  💬 Query 6:                    │
│  Balance Ponderado       │  Índice de Impacto              │
│  (gráfico de barras)     │  (gráfico de barras)            │
├──────────────────────────┴─────────────────────────────────┤
│  🎯 Query 7: Índice de Eficiencia                          │
│  (tabla con ranking)                                        │
└────────────────────────────────────────────────────────────┘
```

### 5.4. Actualizar Resumen de Implementación

Actualizar `docs/RESUMEN_IMPLEMENTACION.md`:

```markdown
## Fase 6: Índices Avanzados ✅ Completado

### Queries Agregadas
- Query 6: Índice de Impacto Ponderado
- Query 7: Índice de Eficiencia
- Query 8: Score Global

### Archivos Modificados
- docs/CLAUDE.md - +300 líneas
- docs/SQL_QUERIES_METABASE.md - +200 líneas
- docs/GUIA_INDICES_AVANZADOS.md - Nuevo archivo
- README.md - Actualizado
```

### 5.5. Crear Archivo de Changelog

Crear `docs/CHANGELOG_FASE6.md`:

```markdown
# Changelog - Fase 6: Índices Avanzados

## [2.1.0] - 2026-01-07

### Agregado
- Query 6: Índice de Impacto Ponderado (IIP)
  - Mide resonancia digital usando engagement + sentimiento
  - Análogo al Balance Ponderado pero con engagement

- Query 7: Índice de Eficiencia (IE)
  - Mide efectividad comunicacional
  - Combina engagement promedio + calidad de menciones

- Query 8: Score Global (SG)
  - Índice compuesto: BP(40%) + IIP(40%) + IE(20%)
  - Ranking integral unificado

### Modificado
- docs/CLAUDE.md: Agregadas 3 queries nuevas
- docs/SQL_QUERIES_METABASE.md: Agregados 3 SQLs
- README.md: Actualizado conteo de queries

### Testing
- 6 tests de validación ejecutados
- Performance < 1000ms en todas las queries
- Coherencia validada entre índices
```

### Validación Fase 5

- [ ] CLAUDE.md actualizado
- [ ] SQL_QUERIES_METABASE.md actualizado
- [ ] README.md actualizado
- [ ] GUIA_INDICES_AVANZADOS.md creado
- [ ] CHANGELOG_FASE6.md creado
- [ ] Dashboard en Metabase creado
- [ ] RESUMEN_IMPLEMENTACION.md actualizado
- [ ] Todos los links internos funcionan

---

## ✅ Checklist de Implementación Completa

### Pre-requisitos

- [ ] Fase 5 (Metabase básico) completada
- [ ] Queries 1-5 funcionando correctamente
- [ ] Base de datos con índices aplicados
- [ ] Acceso a Metabase con permisos de admin

### Fase 1: Query 6 (Índice de Impacto)

- [ ] SQL probado en PostgreSQL
- [ ] Retorna resultados coherentes
- [ ] Agregado a CLAUDE.md
- [ ] Agregado a SQL_QUERIES_METABASE.md
- [ ] Creado en Metabase
- [ ] Variables configuradas
- [ ] Validación: IIP entre 0-100

### Fase 2: Query 7 (Índice de Eficiencia)

- [ ] SQL probado en PostgreSQL
- [ ] Retorna resultados coherentes
- [ ] Agregado a CLAUDE.md
- [ ] Agregado a SQL_QUERIES_METABASE.md
- [ ] Creado en Metabase
- [ ] Variables configuradas
- [ ] Validación: IE entre 0-100

### Fase 3: Query 8 (Score Global)

- [ ] SQL probado en PostgreSQL
- [ ] Los 3 índices se combinan correctamente
- [ ] Agregado a CLAUDE.md
- [ ] Agregado a SQL_QUERIES_METABASE.md
- [ ] Creado en Metabase
- [ ] Variables configuradas
- [ ] Validación: SG entre 0-100
- [ ] Clasificación global funciona

### Fase 4: Validación

- [ ] Test 1: Coherencia ejecutado
- [ ] Test 2: Rangos ejecutado
- [ ] Test 3: Cobertura ejecutado
- [ ] Test 4: Diferenciación ejecutado
- [ ] Test 5: Comparación ejecutado
- [ ] Test 6: Performance ejecutado
- [ ] Todos los tests pasados
- [ ] Problemas documentados y resueltos

### Fase 5: Documentación

- [ ] CLAUDE.md completo
- [ ] SQL_QUERIES_METABASE.md completo
- [ ] README.md actualizado
- [ ] GUIA_INDICES_AVANZADOS.md creado
- [ ] CHANGELOG_FASE6.md creado
- [ ] Dashboard integrado creado
- [ ] RESUMEN_IMPLEMENTACION.md actualizado
- [ ] Screenshots del dashboard tomados

### Post-implementación

- [ ] Usuarios notificados de nuevas funcionalidades
- [ ] Capacitación básica impartida (si aplica)
- [ ] Feedback inicial recopilado
- [ ] Ajustes menores aplicados

---

## 📊 Métricas de Éxito

### Técnicas

- ✅ 3 queries nuevas funcionando
- ✅ 100% de queries con variables configuradas
- ✅ Performance <1000ms en todas
- ✅ 0 errores de SQL en producción

### Funcionales

- ✅ Score Global diferencia actores efectivamente
- ✅ Índices complementan (no duplican) información
- ✅ Rankings son interpretables y accionables

### Documentación

- ✅ 100% de queries documentadas en CLAUDE.md
- ✅ SQLs listos para copiar en SQL_QUERIES_METABASE.md
- ✅ Guía de uso creada
- ✅ Dashboard funcional en Metabase

---

## 🎯 Resultado Final Esperado

Al completar la Fase 6 tendrás:

```
Sistema Completo de 8 Queries:
├─ Queries Base (1-2): Datos crudos
├─ Índices Especializados (3, 6-7): Análisis enfocados
└─ Índice Compuesto (8): Ranking integral

Dashboard en Metabase:
├─ Filtros globales funcionando
├─ 8 visualizaciones diferentes
└─ Score Global destacado

Documentación Completa:
├─ CLAUDE.md: Documentación técnica
├─ SQL_QUERIES_METABASE.md: SQLs listos
├─ GUIA_INDICES_AVANZADOS.md: Manual de uso
└─ CHANGELOG_FASE6.md: Historial de cambios
```

---

## 🆘 Troubleshooting

### Problema: Query 8 muy lento

**Solución:**
```sql
-- Crear índice adicional si es necesario
CREATE INDEX IF NOT EXISTS ix_mentions_sentiment_published
ON mentions (sentiment, published_at);
```

### Problema: Actores con NULL en índices

**Causa:** Actor no cumple filtros mínimos (ej: <10 menciones en Query 7)

**Solución:** Documentar que es comportamiento esperado, o ajustar umbrales

### Problema: Clasificación global todos "Deficiente"

**Causa:** Posible error en pesos o normalización

**Solución:** Verificar que los 3 índices componentes están calculados correctamente

---

## 📞 Soporte

**Documentación relacionada:**
- [FASE5_METABASE.md](FASE5_METABASE.md) - Implementación de queries básicas
- [CLAUDE.md](CLAUDE.md) - Documentación técnica completa
- [PLAN_MEJORAS.md](PLAN_MEJORAS.md) - Plan original de mejoras

**Comandos útiles:**
```bash
# Verificar que queries ejecutan
docker-compose exec db psql -U youscan_admin -d youscan

# Ver índices en BD
\di

# Probar performance
EXPLAIN ANALYZE [SQL Query 6/7/8]
```

---

_Documento creado: 2026-01-07_
_Versión: 1.0_
_Autor: Sistema de Análisis Político - YouScan ETL_
