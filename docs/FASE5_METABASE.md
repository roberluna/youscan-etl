# 📊 Fase 5: Actualización de Queries en Metabase

**Fecha:** 2026-01-07
**Estado:** En progreso
**Objetivo:** Aplicar las mejoras y correcciones de queries en Metabase

---

## 📋 Índice

1. [Preparación](#preparación)
2. [Query 1: Actualizar "Menciones por actor"](#query-1-actualizar-menciones-por-actor)
3. [Query 2: Actualizar "Engagement por actor"](#query-2-actualizar-engagement-por-actor)
4. [Query 3: Actualizar "Balance ponderado"](#query-3-actualizar-balance-ponderado)
5. [Query 4: Crear "Evolución temporal"](#query-4-crear-evolución-temporal)
6. [Query 5: Crear "Calidad de datos"](#query-5-crear-calidad-de-datos)
7. [Configuración de dashboards](#configuración-de-dashboards)
8. [Checklist final](#checklist-final)

---

## 🚀 Preparación

### 1.1. Acceso a Metabase

- **URL:** http://localhost:3000
- **Estado:** ✅ Servicio corriendo
- **Docker:** Contenedor `metabase` activo

### 1.2. Verificaciones previas

Antes de comenzar, verifica:

- [ ] Base de datos tiene los 4 índices nuevos creados
- [ ] Vista materializada `mv_mentions_by_actor_day` existe
- [ ] Queries actualizadas en [docs/CLAUDE.md](CLAUDE.md)
- [ ] Tienes acceso de administrador a Metabase

### 1.3. Estrategia de actualización

**Recomendación:** Duplicar queries existentes antes de modificarlas

1. Abrir query original en Metabase
2. "Guardar como..." con sufijo " (v2)"
3. Modificar la versión nueva
4. Validar resultados comparando ambas versiones
5. Una vez validado, reemplazar original o actualizar dashboards

---

## 🔄 Query 1: Actualizar "Menciones por actor"

### Cambios a aplicar

**Antes:**
- Solo tenía variables `{{actor}}` y `{{fecha}}`

**Después:**
- Agregar variables `{{source_system}}` y `{{source_type}}`

### Pasos de actualización

#### 1. Localizar query en Metabase

1. Ir a **"Preguntas"** en menú lateral
2. Buscar: "Menciones por actor" o similar
3. Anotar el ID de la pregunta (aparece en URL)

#### 2. Abrir en modo edición

1. Click en la pregunta
2. Click en **"..."** (menú) → **"Editar pregunta"**
3. Verificar que está en modo **"SQL nativo"**

#### 3. Reemplazar SQL

Copiar y pegar el siguiente SQL completo:

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

#### 4. Configurar variables

Click en **"Variables"** (ícono de engranaje) y configurar:

| Variable | Tipo | Tabla origen | Columna | Requerido |
|----------|------|--------------|---------|-----------|
| `actor` | Field Filter | Tags | tag_name | No |
| `fecha` | Field Filter | Mentions | published_at | No |
| `source_system` | Field Filter | Mentions | source_system | No |
| `source_type` | Field Filter | Mentions | source_type | No |

#### 5. Validar

1. Click **"Visualizar"** (sin filtros)
2. Verificar que aparecen todos los actores
3. Probar cada filtro individualmente:
   - Filtrar por un actor específico
   - Filtrar por rango de fechas
   - Filtrar por source_system (ej: "Facebook")
   - Filtrar por source_type (ej: "post")

#### 6. Guardar

1. Click **"Guardar"** (esquina superior derecha)
2. Confirmar cambios

---

## 💬 Query 2: Actualizar "Engagement por actor"

### Cambios a aplicar

**CRÍTICO:** Este es el bug más importante a corregir

**Antes:**
```sql
JOIN metrics me ON me.mention_id = m.mention_id
```

**Después:**
```sql
LEFT JOIN metrics me ON me.mention_id = m.mention_id
```

**Impacto:** Ahora incluye TODAS las menciones, incluso sin engagement

### Pasos de actualización

#### 1. Localizar y abrir query

1. Buscar en **"Preguntas"**: "Engagement" o similar
2. Click → **"..."** → **"Editar pregunta"**

#### 2. Reemplazar SQL completo

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

#### 3. Configurar variables

Mismas 4 variables que Query 1:
- `actor`, `fecha`, `source_system`, `source_type`

#### 4. Validar cambio crítico

**Test de consistencia:**

1. Ejecutar Query 1 y contar actores únicos (ej: 15 actores)
2. Ejecutar Query 2 (nueva versión) y contar actores
3. **Deben coincidir:** Ambas queries deben retornar los mismos actores

**Antes del fix:**
- Query 1: 15 actores
- Query 2: 12 actores ❌ (faltan 3 actores sin engagement)

**Después del fix:**
- Query 1: 15 actores
- Query 2: 15 actores ✅ (todos incluidos, algunos con engagement=0)

#### 5. Guardar

Click **"Guardar"** y confirmar

---

## ⚖️ Query 3: Actualizar "Balance ponderado"

### Cambios a aplicar

**Antes:**
- Ya tenía `{{actor}}` y `{{fecha}}`
- Solo faltaban `{{source_system}}` y `{{source_type}}`

**Después:**
- Consistencia con las otras 4 variables

### Pasos de actualización

#### 1. Localizar y abrir query

1. Buscar: "Balance ponderado" o "Balance opinión"
2. Abrir en modo edición

#### 2. Reemplazar SQL completo

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

#### 3. Configurar variables

Mismas 4 variables que Query 1 y 2

#### 4. Validar

1. Verificar que el rango de `balance_ponderado` está entre 0-100
2. Verificar que actores con solo neutrales aparecen al final con NULL
3. Probar filtros de source_system y source_type

#### 5. Guardar

---

## 📈 Query 4: Crear "Evolución temporal"

### Query nueva - No existe en Metabase

Esta query permite analizar tendencias temporales de menciones por actor.

### Pasos de creación

#### 1. Crear nueva pregunta

1. Click **"Nueva pregunta"** (botón azul)
2. Seleccionar **"SQL nativo"**
3. Seleccionar base de datos: **"youscan"**

#### 2. Pegar SQL

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

#### 3. Configurar variables

Mismas 4 variables opcionales

#### 4. Configurar visualización

**Tipo recomendado:** Gráfico de líneas

1. Click en **"Visualización"** (ícono de gráfico)
2. Seleccionar **"Línea"**
3. Configurar:
   - **Eje X:** `fecha`
   - **Eje Y:** `menciones_total`
   - **Series:** `actor` (cada actor una línea de color diferente)

**Alternativas:**
- Gráfico de barras apiladas (para comparar sentimientos)
- Tabla (para análisis detallado)

#### 5. Guardar

1. Click **"Guardar"**
2. Nombre sugerido: **"Evolución temporal - Menciones por actor"**
3. Descripción: "Análisis de series de tiempo de menciones por actor político con distribución de sentimiento"
4. Seleccionar colección apropiada

---

## 🔍 Query 5: Crear "Calidad de datos"

### Query nueva - Auditoría de calidad

Esta query permite monitorear problemas de calidad en los datos.

### Pasos de creación

#### 1. Crear nueva pregunta SQL nativa

1. **"Nueva pregunta"** → **"SQL nativo"** → Base de datos **"youscan"**

#### 2. Pegar SQL (versión resumen)

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

#### 3. Configurar visualización

**Tipo recomendado:** Tabla

- Sin variables de filtrado (esta es una query de auditoría global)
- Mostrar todas las columnas

#### 4. Agregar alertas visuales (opcional)

En Metabase puedes configurar formato condicional:

1. Click en columna `porcentaje_completitud`
2. Configurar colores:
   - Verde: ≥ 95%
   - Amarillo: 85-95%
   - Rojo: < 85%

#### 5. Guardar

- **Nombre:** "Auditoría - Calidad de datos"
- **Descripción:** "Monitoreo de completitud y calidad de datos YouScan"

#### 6. Programar alerta (opcional)

1. Click **"..."** → **"Configurar alertas"**
2. **Condición:** "Si porcentaje_completitud < 90%"
3. **Notificar a:** Tu email
4. **Frecuencia:** Diariamente después del ETL

---

## 📊 Configuración de dashboards

### Crear dashboard nuevo: "Análisis Político - v2"

#### 1. Crear dashboard

1. Click **"Dashboards"** → **"Nuevo dashboard"**
2. Nombre: **"Análisis Político Cuantitativo - v2"**
3. Descripción: "Dashboard actualizado con queries optimizadas y nuevas funcionalidades"

#### 2. Agregar visualizaciones

**Layout recomendado:**

```
┌─────────────────────────────────────────────────────┐
│  Filtros globales:                                  │
│  [Actor ▼] [Fecha ▼] [Fuente ▼] [Tipo ▼]          │
├─────────────────────────────────────────────────────┤
│  📊 Query 1: Menciones por actor (tabla)            │
│  - Top 10 actores con volumen y sentimiento         │
├────────────────────────┬────────────────────────────┤
│  💬 Query 2:           │  ⚖️ Query 3:              │
│  Engagement por actor  │  Balance ponderado         │
│  (tabla o barras)      │  (tabla ordenada)          │
├────────────────────────┴────────────────────────────┤
│  📈 Query 4: Evolución temporal                     │
│  (gráfico de líneas - toda la altura)               │
├─────────────────────────────────────────────────────┤
│  🔍 Query 5: Calidad de datos (tabla pequeña)      │
└─────────────────────────────────────────────────────┘
```

#### 3. Configurar filtros a nivel dashboard

1. Click **"Agregar filtro"** (ícono embudo)
2. Crear 4 filtros globales:

| Filtro | Tipo | Conectar a |
|--------|------|------------|
| Actor político | Field Filter → Tags.tag_name | Todas las queries (variable `{{actor}}`) |
| Rango de fechas | Field Filter → Mentions.published_at | Todas las queries (variable `{{fecha}}`) |
| Fuente | Field Filter → Mentions.source_system | Todas las queries (variable `{{source_system}}`) |
| Tipo de contenido | Field Filter → Mentions.source_type | Todas las queries (variable `{{source_type}}`) |

#### 4. Configurar parámetros por tarjeta

Para cada visualización en el dashboard:

1. Click en **"..."** de la tarjeta → **"Editar"**
2. **Mapear variables:**
   - `{{actor}}` → Filtro dashboard "Actor político"
   - `{{fecha}}` → Filtro dashboard "Rango de fechas"
   - `{{source_system}}` → Filtro dashboard "Fuente"
   - `{{source_type}}` → Filtro dashboard "Tipo de contenido"

#### 5. Guardar y publicar

1. Click **"Guardar"** (esquina superior derecha)
2. Click **"Compartir"** → Configurar permisos según necesidad

---

## ✅ Checklist final

### Queries actualizadas

- [ ] Query 1: "Menciones por actor" - 4 variables agregadas
- [ ] Query 2: "Engagement por actor" - LEFT JOIN aplicado + 4 variables
- [ ] Query 3: "Balance ponderado" - 4 variables agregadas
- [ ] Query 4: "Evolución temporal" - Query nueva creada
- [ ] Query 5: "Calidad de datos" - Query nueva creada

### Validación de queries

- [ ] Query 1 y Query 2 retornan mismo número de actores
- [ ] Query 2 incluye actores con engagement = 0 (antes no aparecían)
- [ ] Todas las queries responden a filtros correctamente
- [ ] Variables funcionan en modo individual y combinado
- [ ] No hay errores de SQL en ninguna query

### Dashboard

- [ ] Dashboard nuevo creado con 5 queries
- [ ] Filtros globales configurados (4 filtros)
- [ ] Variables de queries mapeadas a filtros de dashboard
- [ ] Layout organizado y visualmente claro
- [ ] Dashboard guardado y compartido con usuarios apropiados

### Documentación

- [ ] Queries antiguas respaldadas (guardadas con sufijo " (v1)")
- [ ] Usuarios notificados del cambio
- [ ] Guía de uso del dashboard compartida

---

## 🎯 Resultado esperado

Al completar esta fase tendrás:

✅ **5 queries actualizadas/creadas** en Metabase
✅ **Bug crítico corregido** (Query 2 con LEFT JOIN)
✅ **Filtros consistentes** en todas las queries (4 variables)
✅ **Dashboard optimizado** con nuevas funcionalidades
✅ **Auditoría de calidad** disponible para monitoreo

**Mejora estimada:**
- 🚀 Queries 70% más rápidas (gracias a índices)
- 📊 100% de menciones incluidas (bug de LEFT JOIN corregido)
- 🎛️ Mayor flexibilidad de filtrado (4 variables en todas las queries)
- 🔍 Visibilidad de calidad de datos (Query 5)

---

## 📞 Soporte

**Documentación de referencia:**
- [docs/CLAUDE.md](CLAUDE.md) - SQL completo de todas las queries
- [docs/APLICACION_COMPLETA.md](APLICACION_COMPLETA.md) - Cambios aplicados en BD
- [docs/PLAN_MEJORAS.md](PLAN_MEJORAS.md) - Plan completo de mejoras

**En caso de problemas:**
1. Verificar que la base de datos tiene los índices aplicados
2. Verificar que la vista materializada existe
3. Revisar logs de Metabase: `docker-compose logs metabase`

---

_Guía creada: 2026-01-07_
_Versión: 1.0_
