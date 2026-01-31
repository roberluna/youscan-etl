# 📋 SQL Queries para Metabase - Referencia Rápida

**Propósito:** SQLs listos para copiar y pegar directamente en Metabase
**Fecha:** 2026-01-07
**Versión:** 2.0 (con correcciones y mejoras aplicadas)

---

## 🎯 Query 1: Menciones por actor político

**Nombre sugerido:** "Menciones por actor - Volumen y sentimiento"

**Variables a configurar:** `{{actor}}`, `{{fecha}}`, `{{source_system}}`, `{{source_type}}`

**SQL:**

```sql
SELECT
  t.tag_name AS actor,
  SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS positivas,
  SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS negativas,
  SUM(CASE WHEN m.sentiment = 'Neutral' THEN 1 ELSE 0 END) AS neutrales,
  COUNT(*) AS total
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
ORDER BY total DESC;
```

**Visualización recomendada:** Tabla o gráfico de barras apiladas

---

## 💬 Query 2: Engagement por actor político

**Nombre sugerido:** "Engagement por actor - Impacto por sentimiento"

**Variables a configurar:** `{{actor}}`, `{{fecha}}`, `{{source_system}}`, `{{source_type}}`

**⚠️ CRÍTICO:** Esta query corrige el bug de `LEFT JOIN`

**SQL:**

```sql
SELECT
  t.tag_name AS actor,
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
ORDER BY engagement_total DESC;
```

**Visualización recomendada:** Tabla o gráfico de barras

**Nota importante:** Verificar que dice `LEFT JOIN metrics` (línea 8)

---

## ⚖️ Query 3: Balance ponderado de opinión

**Nombre sugerido:** "Balance ponderado - Percepción del actor"

**Variables a configurar:** `{{actor}}`, `{{fecha}}`, `{{source_system}}`, `{{source_type}}`

**SQL:**

```sql
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
ORDER BY balance_ponderado DESC NULLS LAST;
```

**Visualización recomendada:** Tabla ordenada por `balance_ponderado`

**Interpretación:**
- `balance_ponderado`: 0-100 (0=totalmente negativo, 100=totalmente positivo)
- Actores con solo neutrales tendrán NULL

---

## 📈 Query 4: Evolución temporal de menciones

**Nombre sugerido:** "Evolución temporal - Menciones por actor"

**Variables a configurar:** `{{actor}}`, `{{fecha}}`, `{{source_system}}`, `{{source_type}}`

**✨ NUEVA QUERY**

**SQL:**

```sql
SELECT
  DATE_TRUNC('day', m.published_at)::DATE AS fecha,
  t.tag_name AS actor,
  COUNT(*) AS menciones_total,
  SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS menciones_positivas,
  SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS menciones_negativas,
  SUM(CASE WHEN m.sentiment = 'Neutral' THEN 1 ELSE 0 END) AS menciones_neutrales,
  ROUND(100.0 * SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS pct_positivo,
  ROUND(100.0 * SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS pct_negativo,
  SUM(COALESCE(me.engagement, 0)) AS engagement_total
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
LEFT JOIN metrics me ON me.mention_id = m.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  AND m.published_at IS NOT NULL
  [[AND {{actor}}]]
  [[AND {{fecha}}]]
  [[AND {{source_system}}]]
  [[AND {{source_type}}]]
GROUP BY DATE_TRUNC('day', m.published_at)::DATE, t.tag_name
ORDER BY fecha DESC, menciones_total DESC;
```

**Visualización recomendada:** Gráfico de líneas
- **Eje X:** `fecha`
- **Eje Y:** `menciones_total`
- **Series:** `actor` (una línea por actor con color diferente)

**Casos de uso:**
- Detectar picos de conversación
- Identificar tendencias temporales
- Comparar evolución entre actores

---

## 📈 Query 4 - Variante Semanal

**Nombre sugerido:** "Evolución semanal - Menciones por actor"

**Para análisis de periodos largos (>3 meses)**

**SQL:**

```sql
SELECT
  DATE_TRUNC('week', m.published_at)::DATE AS semana_inicio,
  t.tag_name AS actor,
  COUNT(*) AS menciones_total,
  SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS menciones_positivas,
  SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS menciones_negativas,
  SUM(CASE WHEN m.sentiment = 'Neutral' THEN 1 ELSE 0 END) AS menciones_neutrales,
  ROUND(100.0 * SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS pct_positivo,
  ROUND(100.0 * SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS pct_negativo,
  SUM(COALESCE(me.engagement, 0)) AS engagement_total
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
LEFT JOIN metrics me ON me.mention_id = m.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  AND m.published_at IS NOT NULL
  [[AND {{actor}}]]
  [[AND {{fecha}}]]
  [[AND {{source_system}}]]
  [[AND {{source_type}}]]
GROUP BY DATE_TRUNC('week', m.published_at)::DATE, t.tag_name
ORDER BY semana_inicio DESC, menciones_total DESC;
```

---

## 📈 Query 4 - Variante por Día de Semana

**Nombre sugerido:** "Patrones semanales - Menciones por día de semana"

**Para identificar patrones de comportamiento semanal**

**SQL:**

```sql
SELECT
  TO_CHAR(m.published_at, 'Day') AS dia_semana,
  EXTRACT(ISODOW FROM m.published_at) AS dia_num,
  t.tag_name AS actor,
  COUNT(*) AS menciones_total,
  ROUND(AVG(COALESCE(me.engagement, 0)), 1) AS engagement_promedio
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
LEFT JOIN metrics me ON me.mention_id = m.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  AND m.published_at IS NOT NULL
  [[AND {{actor}}]]
  [[AND {{fecha}}]]
  [[AND {{source_system}}]]
  [[AND {{source_type}}]]
GROUP BY TO_CHAR(m.published_at, 'Day'), EXTRACT(ISODOW FROM m.published_at), t.tag_name
ORDER BY dia_num, menciones_total DESC;
```

**Interpretación:**
- `dia_num`: 1=Lunes, 7=Domingo
- Identifica días de mayor actividad

---

## 🔍 Query 5: Validación de calidad de datos

**Nombre sugerido:** "Auditoría - Calidad de datos"

**Sin variables de filtrado** (query de auditoría global)

**✨ NUEVA QUERY**

**SQL:**

```sql
WITH total_mentions AS (
  SELECT COUNT(DISTINCT mention_id) AS total
  FROM mentions
  WHERE published_at IS NOT NULL
),
mentions_sin_sentiment AS (
  SELECT COUNT(DISTINCT mention_id) AS count
  FROM mentions
  WHERE sentiment IS NULL OR sentiment NOT IN ('Positivo', 'Negativo', 'Neutral')
),
mentions_sin_metricas AS (
  SELECT COUNT(DISTINCT m.mention_id) AS count
  FROM mentions m
  LEFT JOIN metrics me ON me.mention_id = m.mention_id
  WHERE me.mention_id IS NULL
),
mentions_sin_actor_tags AS (
  SELECT COUNT(DISTINCT m.mention_id) AS count
  FROM mentions m
  LEFT JOIN (
    SELECT DISTINCT mt.mention_id
    FROM mention_tags mt
    JOIN tags t ON t.tag_id = mt.tag_id
    WHERE t.tag_type = 'actor'
  ) actor_tags ON actor_tags.mention_id = m.mention_id
  WHERE actor_tags.mention_id IS NULL
)
SELECT
  'Menciones únicas' AS metrica,
  tm.total AS cantidad,
  100.0 AS porcentaje_completitud
FROM total_mentions tm
UNION ALL
SELECT
  'Sin actor tags' AS metrica,
  msat.count AS cantidad,
  ROUND(100.0 * (1 - msat.count::FLOAT / NULLIF(tm.total, 0)), 1) AS porcentaje_completitud
FROM total_mentions tm, mentions_sin_actor_tags msat
UNION ALL
SELECT
  'Sin métricas' AS metrica,
  msm.count AS cantidad,
  ROUND(100.0 * (1 - msm.count::FLOAT / NULLIF(tm.total, 0)), 1) AS porcentaje_completitud
FROM total_mentions tm, mentions_sin_metricas msm
UNION ALL
SELECT
  'Sin sentimiento' AS metrica,
  mss.count AS cantidad,
  ROUND(100.0 * (1 - mss.count::FLOAT / NULLIF(tm.total, 0)), 1) AS porcentaje_completitud
FROM total_mentions tm, mentions_sin_sentiment mss
ORDER BY metrica;
```

**Visualización recomendada:** Tabla

**Umbrales de alerta:**
- **CRÍTICO (< 85%):** Error grave en ETL
- **ADVERTENCIA (85-95%):** Revisar calidad de datos de origen
- **OK (> 95%):** Calidad aceptable

**Formato condicional recomendado:**
- Verde: ≥ 95%
- Amarillo: 85-95%
- Rojo: < 85%

---

## 🔍 Query 5 - Detalle de problemas

**Nombre sugerido:** "Auditoría - Detalle de menciones con problemas"

**Para investigar menciones específicas con problemas de calidad**

**SQL:**

```sql
SELECT
  m.mention_id,
  m.published_at,
  m.source_system,
  m.source_type,
  m.sentiment,
  CASE
    WHEN m.sentiment IS NULL OR m.sentiment NOT IN ('Positivo', 'Negativo', 'Neutral')
      THEN '⚠️ Sin sentimiento válido'
    WHEN me.mention_id IS NULL
      THEN '⚠️ Sin métricas de engagement'
    WHEN actor_tags.mention_id IS NULL
      THEN 'ℹ️ Sin tags de actor'
    ELSE 'OK'
  END AS problema
FROM mentions m
LEFT JOIN metrics me ON me.mention_id = m.mention_id
LEFT JOIN (
  SELECT DISTINCT mt.mention_id
  FROM mention_tags mt
  JOIN tags t ON t.tag_id = mt.tag_id
  WHERE t.tag_type = 'actor'
) actor_tags ON actor_tags.mention_id = m.mention_id
WHERE m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
  AND (
    m.sentiment IS NULL
    OR actor_tags.mention_id IS NULL
  )
ORDER BY m.published_at DESC
LIMIT 100;
```

**Uso:** Investigación de problemas específicos de calidad

---

## 🎨 Configuración de Variables en Metabase

### Para Queries 1, 2, 3, 4

Todas estas queries usan las mismas 4 variables opcionales:

| Variable | Tipo | Widget Type | Tabla origen | Columna |
|----------|------|-------------|--------------|---------|
| `actor` | Field Filter | String/= | Tags | tag_name |
| `fecha` | Field Filter | Date range | Mentions | published_at |
| `source_system` | Field Filter | String/= | Mentions | source_system |
| `source_type` | Field Filter | String/= | Mentions | source_type |

**Configuración en Metabase:**

1. Click en **ícono de engranaje** (Variables)
2. Para cada variable:
   - **Variable name:** `actor`, `fecha`, `source_system`, `source_type`
   - **Variable type:** Field Filter
   - **Field to map to:** Seleccionar de lista desplegable
   - **Required:** No (dejar sin marcar)

### Para Query 5

No tiene variables (query de auditoría global)

---

## 📊 Configuración de Visualizaciones

### Query 1: Tabla con barras

**Tipo:** Tabla
**Configuración:**
- Ordenar por: `total` DESC
- Formato de columnas:
  - `positivas`, `negativas`, `neutrales`, `total`: Números con separador de miles
- Opcional: Agregar mini barras en columnas numéricas

### Query 2: Tabla o barras

**Opción A - Tabla:**
- Ordenar por: `engagement_total` DESC
- Formato: Números con separador de miles

**Opción B - Barras horizontales:**
- Eje X: `engagement_total`
- Eje Y: `actor`
- Colores por sentimiento

### Query 3: Tabla

**Tipo:** Tabla
**Configuración:**
- Ordenar por: `balance_ponderado` DESC
- Formato:
  - `balance_ponderado`: 1 decimal
  - `positivas`, `negativas`, etc.: Números enteros
- Opcional: Formato condicional en `balance_ponderado`:
  - Verde: > 70
  - Amarillo: 30-70
  - Rojo: < 30

### Query 4: Gráfico de líneas

**Tipo:** Line
**Configuración:**
- Eje X: `fecha` (time series)
- Eje Y: `menciones_total`
- Series: `actor` (una línea por actor)
- Mostrar puntos: Sí
- Suavizado: Opcional
- Leyenda: Visible

### Query 5: Tabla con formato condicional

**Tipo:** Tabla
**Configuración:**
- Formato condicional en `porcentaje_completitud`:
  - 🟢 Verde: ≥ 95%
  - 🟡 Amarillo: 85-95%
  - 🔴 Rojo: < 85%

---

## 🎯 Filtros a Nivel Dashboard

Configurar 4 filtros globales que afectan las Queries 1, 2, 3 y 4:

| Filtro Dashboard | Tipo | Conectar a variable |
|------------------|------|---------------------|
| Actor político | Field Filter → Tags.tag_name | `{{actor}}` de todas las queries |
| Rango de fechas | Field Filter → Mentions.published_at | `{{fecha}}` de todas las queries |
| Fuente (Facebook, Twitter, etc.) | Field Filter → Mentions.source_system | `{{source_system}}` de todas las queries |
| Tipo de contenido (post, comment) | Field Filter → Mentions.source_type | `{{source_type}}` de todas las queries |

**Query 5 NO se conecta a filtros** (es query de auditoría global)

---

## ✅ Checklist de Validación

Después de copiar cada query:

- [ ] SQL copiado completamente (incluyendo último `;`)
- [ ] Variables configuradas correctamente (4 variables para Q1-Q4, 0 para Q5)
- [ ] Query ejecuta sin errores
- [ ] Resultados tienen sentido lógico
- [ ] Filtros funcionan individualmente
- [ ] Filtros funcionan en combinación
- [ ] Visualización apropiada seleccionada
- [ ] Query guardada con nombre descriptivo

---

## 🚨 Errores Comunes

### Error: "LEFT JOIN no reconocido"

**Problema:** Copiaste incompleto o hay error de sintaxis

**Solución:** Copiar TODO el SQL desde SELECT hasta el `;` final

### Error: "Variable {{actor}} no definida"

**Problema:** Falta configurar variable

**Solución:** Click en engranaje → Agregar variable con sintaxis exacta `{{actor}}`

### Error: "Query timeout"

**Problema:** Periodo muy largo sin índices

**Solución:** Verificar que los 4 índices estén creados en BD:
```sql
\di  -- Ver índices
```

### Query 1 y Query 2 retornan diferente número de actores

**Problema:** Query 2 usa `JOIN metrics` en vez de `LEFT JOIN metrics`

**Solución:** Verificar línea 8 de Query 2 dice `LEFT JOIN`

---

## 📞 Soporte

**Documentación completa:**
- [FASE5_METABASE.md](FASE5_METABASE.md) - Guía paso a paso detallada
- [CHECKLIST_FASE5.md](CHECKLIST_FASE5.md) - Checklist interactivo
- [CLAUDE.md](CLAUDE.md) - Documentación técnica completa

**Comando para verificar índices en BD:**
```bash
docker-compose exec db psql -U youscan_admin -d youscan -c "\di"
```

---

_Última actualización: 2026-01-07_
_Versión: 2.0 (con correcciones aplicadas)_
