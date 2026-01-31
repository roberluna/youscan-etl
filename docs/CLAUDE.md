# 📊 Sistema de Análisis Político – YouScan ETL

> **Arquitectura de datos para análisis político cuantitativo basado en datos de YouScan**

## 📋 Tabla de contenido

1. [Contexto general](#-contexto-general)
2. [Arquitectura del sistema](#-arquitectura-del-sistema)
3. [Modelo de datos](#-modelo-de-datos)
4. [Consultas SQL principales](#-consultas-sql-principales)
   - [Query 1: Menciones por actor político](#query-1-menciones-por-actor-político-volumen-y-sentimiento)
   - [Query 2: Engagement por actor político](#query-2-engagement-por-actor-político)
   - [Query 3: Balance de opinión ponderado](#query-3-balance-de-opinión-ponderado)
   - [Query 4: Evolución temporal](#query-4-evolución-temporal-de-menciones)
   - [Query 5: Validación de calidad de datos](#query-5-validación-de-calidad-de-datos)
5. [Variables dinámicas en Metabase](#-variables-dinámicas-en-metabase)
6. [Glosario](#-glosario)

---

## 📌 Contexto general

Este sistema procesa y analiza datos estructurados exportados desde **YouScan**, una plataforma de social listening, para generar métricas políticas cuantitativas.

### Objetivos del análisis

El sistema mide:
- **Volumen de menciones** por actor político
- **Sentimiento** asociado a las menciones (positivo, negativo, neutral)
- **Engagement** generado por las menciones
- **Balance de opinión** ponderado por tamaño de muestra

### Características clave

- Análisis **100% cuantitativo** basado en datos estructurados
- Sin procesamiento de lenguaje natural (NLP) adicional
- Sentimiento proporcionado directamente por YouScan
- Destinado a visualización en **Metabase**

---

## 🏗️ Arquitectura del sistema

### Flujo de datos

```
[YouScan Export (.xlsx)]
    ↓
[data/] → [etl_youscan.py]
    ↓
[PostgreSQL Database]
    ↓
[Metabase Dashboards]
```

### Componentes principales

| Componente | Descripción | Ubicación |
|------------|-------------|-----------|
| **Datos de origen** | Archivos Excel exportados de YouScan | `data/` |
| **Script ETL** | Proceso de extracción, transformación y carga | `etl_youscan.py` |
| **Base de datos** | PostgreSQL con esquema normalizado | PostgreSQL (puerto 5433) |
| **Esquema SQL** | Definición de tablas y relaciones | `sql/001_init.sql` |
| **Visualización** | Dashboards interactivos | Metabase |

---

## 🧱 Modelo de datos

El modelo de datos está definido en [sql/001_init.sql](../sql/001_init.sql) y consta de las siguientes tablas:

### Tablas principales

#### `mentions`
Tabla central que almacena cada mención única capturada por YouScan.

**Campos clave:**
- `mention_id`: Identificador único (PK)
- `mention_key`: Clave única de negocio
- `source_system`: Sistema origen (ej. "youscan")
- `source_type`: Tipo de fuente (ej. "social")
- `published_at`: Fecha de publicación
- `sentiment`: Sentimiento de la mención (Positivo/Negativo/Neutral)
- `author`, `author_nickname`: Información del autor
- `body_text`, `title`: Contenido textual
- `url`: Enlace a la mención original

#### `metrics`
Almacena métricas de engagement por mención (relación 1:1 con mentions).

**Campos clave:**
- `mention_id`: FK a mentions
- `engagement`: Métrica principal de interacción total
- `likes`, `comments`, `reposts`: Interacciones específicas
- `views`, `reach_potential`: Métricas de alcance
- `reactions`: Suma de reacciones emocionales

#### `tags`
Catálogo de etiquetas utilizadas para clasificar menciones.

**Campos clave:**
- `tag_id`: Identificador único (PK)
- `tag_name`: Nombre de la etiqueta
- `tag_type`: Tipo de etiqueta (`actor`, `category`, `query`)

**Tipos de tags:**
- `actor`: Actores políticos (candidatos, funcionarios, partidos)
- `category`: Temas o categorías temáticas
- `query`: Palabras clave de búsqueda

#### `mention_tags`
Tabla puente que relaciona menciones con etiquetas (relación N:M).

**Campos clave:**
- `mention_id`: FK a mentions
- `tag_id`: FK a tags
- `tag_sentiment`: Sentimiento específico del tag (opcional)

#### `mention_occurrences`
Rastrea las apariciones de cada mención en los archivos de carga, permitiendo trazabilidad y deduplicación.

**Campos clave:**
- `occurrence_id`: Identificador único (PK)
- `mention_id`: FK a mentions
- `run_id`: FK a ingestion_runs
- `row_hash`: Hash de la fila para deduplicación
- `row_number`: Número de fila en el archivo original

**Importancia crítica:** Esta tabla es esencial para que las métricas coincidan con los archivos originales. Siempre debe incluirse en los JOIN principales.

#### `ingestion_runs`
Registra cada ejecución del proceso ETL para auditoría.

**Campos clave:**
- `run_id`: Identificador único (PK)
- `source_system`: Sistema de origen
- `file_name`: Nombre del archivo procesado
- `status`: Estado de la ejecución
- `started_at`, `finished_at`: Timestamps de ejecución

### Diagrama de relaciones

```
ingestion_runs
    ↓ (1:N)
mention_occurrences ← (N:1) → mentions ← (1:1) → metrics
    ↓ (N:M)
mention_tags ← (N:1) → tags
```

### Reglas de negocio clave

1. **Identificación de actores:** Los actores políticos se identifican mediante `tags.tag_type = 'actor'`
2. **Fuente de sentimiento:** El sentimiento proviene directamente de `mentions.sentiment` (no requiere cálculo)
3. **Engagement:** Se obtiene desde `metrics.engagement` (puede ser NULL para menciones sin métricas)
4. **Conteo correcto:** Siempre usar `mention_occurrences` en los JOIN para que el conteo coincida con los archivos exportados
5. **Co-menciones y atribución múltiple:** Cuando una mención incluye múltiples actores (ej. "AMLO y Sheinbaum en evento"), se contabiliza para cada actor individualmente. Esto significa:
   - Una mención con 3 actores suma +1 a cada uno (total sistema: 3)
   - El engagement se suma completo a cada actor (no se divide)
   - El total agregado puede ser mayor que el número único de menciones
   - Este comportamiento es intencional para medir **atribución por actor** en lugar de totales únicos

---

## 🔍 Consultas SQL principales

### ⚠️ Consideraciones técnicas importantes

Antes de usar las consultas, ten en cuenta estos aspectos:

#### 1. Comportamiento de agregación

Las queries agregan por `tag_name` (actor), lo que significa:
- Una mención con múltiples actores se cuenta para cada uno
- Los totales agregados pueden superar el número único de menciones
- Esto es correcto para análisis de **atribución por actor**

**Ejemplo:**
```
Mención: "AMLO y Claudia inauguran obra"
Tags: ["López Obrador", "Sheinbaum"]
Engagement: 1,000

Resultado:
- López Obrador: +1 mención, +1,000 engagement
- Sheinbaum: +1 mención, +1,000 engagement
- Total sistema: 2 menciones, 2,000 engagement
- Menciones únicas reales: 1, engagement real: 1,000
```

#### 2. Menciones sin métricas

No todas las menciones tienen métricas de engagement:
- Query 1 (volumen) incluye TODAS las menciones
- Query 2 (engagement) usa LEFT JOIN para incluirlas con engagement=0
- Query 3 (balance) no requiere métricas, solo sentiment

#### 3. Actores sin muestra válida

En Query 3, actores con solo menciones neutrales tendrán:
- `muestra = 0` (no hay positivos ni negativos)
- `balance_opinion = NULL`
- `balance_ponderado = NULL`

Estos actores aparecerán al final del ranking.

#### 4. Rendimiento con grandes volúmenes

Para periodos largos (>3 meses) o datasets grandes (>100K menciones):
- Considera agregar índices (ver sección de optimización)
- Usa siempre filtros de fecha
- Limita resultados con `LIMIT` si es necesario

---

### Query 1: Menciones por actor político (volumen y sentimiento)

#### 🎯 Objetivo

Medir el **volumen total de menciones** por actor político y su distribución por sentimiento (positivo, negativo, neutral).

#### 🧠 Qué responde esta métrica

- ¿Quiénes son los actores más mencionados en el periodo?
- ¿Qué tono de conversación domina para cada actor?
- ¿Cómo se compara el volumen de menciones entre actores?

#### 💡 Casos de uso

- Identificar los actores con mayor presencia mediática
- Detectar actores con predominancia de sentimiento negativo o positivo
- Comparar la visibilidad relativa entre competidores políticos

#### 📊 SQL

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

#### 📝 Notas técnicas

- **JOIN crítico:** Se utiliza `mention_occurrences` para garantizar conteos consistentes con archivos de origen
- **Filtro de actores:** `tag_type = 'actor'` asegura que solo se incluyan actores políticos
- **Variables Metabase:** `{{actor}}`, `{{fecha}}`, `{{source_system}}` y `{{source_type}}` permiten filtrado dinámico (ver sección de variables)
- **Rango de fechas:** Ajustar según el periodo de análisis deseado

---

### Query 2: Engagement por actor político

#### 🎯 Objetivo

Medir el **impacto real** de las menciones mediante engagement total y distribuido por sentimiento.

#### 🧠 Qué responde esta métrica

- ¿Qué actor genera mayor interacción en redes sociales?
- ¿El engagement positivo o negativo domina para cada actor?
- ¿Existe correlación entre volumen de menciones y engagement?

#### 💡 Casos de uso

- Evaluar la resonancia real de las menciones (no solo volumen)
- Identificar actores con alta capacidad de movilización digital
- Detectar campañas de alto engagement (positivo o negativo)

#### 📊 SQL

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

#### 📝 Notas técnicas

- **LEFT JOIN crítico:** Se usa LEFT JOIN con metrics para incluir menciones sin métricas disponibles (el COALESCE las trata como 0)
- **COALESCE:** Maneja valores NULL en engagement (menciones sin métricas disponibles)
- **JOIN con metrics:** Relación 1:1, algunas menciones pueden no tener métricas
- **Engagement:** Suma de interacciones (likes, comments, shares, etc.) según YouScan
- **Variables Metabase:** `{{actor}}`, `{{fecha}}`, `{{source_system}}` y `{{source_type}}` permiten filtrado dinámico

---

### Query 3: Balance de opinión ponderado

#### 🎯 Objetivo

Construir un **índice normalizado (0–100)** que mida el balance entre menciones positivas y negativas, considerando el tamaño de la muestra.

#### 🧠 Metodología del índice

##### 1. Muestra válida
Solo se consideran menciones con sentimiento definido (positivas y negativas):

```
muestra = positivos + negativos
```

##### 2. Balance de opinión (0–100)
Normalización lineal donde:
- **50** = balance neutro (igual positivos y negativos)
- **100** = 100% positivo
- **0** = 100% negativo

```
balance_opinion = 50 + 50 × (positivos - negativos) / muestra
```

##### 3. Balance ponderado
Ajuste por tamaño relativo de muestra para evitar sobrevalorar actores con pocas menciones:

```
balance_ponderado = balance_opinion × (muestra / muestra_maxima)
```

#### 💡 Casos de uso

- Ranking objetivo de percepción pública
- Comparación justa entre actores con diferente volumen de menciones
- Identificación de actores con opinión polarizada vs. balanceada
- Alertas tempranas de deterioro/mejora en percepción

#### 📊 SQL

```sql
WITH base AS (
  SELECT
    t.tag_name AS actor,
    SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS pos,
    SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS neg
  FROM mention_occurrences o
  JOIN mentions m ON m.mention_id = o.mention_id
  JOIN mention_tags mt ON mt.mention_id = o.mention_id
  JOIN tags t ON t.tag_id = mt.tag_id
  WHERE t.tag_type = 'actor'
    AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
    [[AND {{actor}}]]
    [[AND {{source_system}}]]
    [[AND {{source_type}}]]
  GROUP BY t.tag_name
),
scored AS (
  SELECT
    actor,
    pos,
    neg,
    (pos + neg) AS muestra,
    ROUND(50 + 50 * (pos - neg)::NUMERIC / NULLIF(pos + neg, 0), 2) AS balance_opinion
  FROM base
),
maxes AS (
  SELECT MAX(muestra) AS max_muestra
  FROM scored
)
SELECT
  s.actor,
  s.pos,
  s.neg,
  s.muestra,
  s.balance_opinion,
  ROUND(s.balance_opinion * (s.muestra::NUMERIC / NULLIF(m.max_muestra, 0)), 2) AS balance_ponderado,
  CASE
    WHEN s.muestra < 100 THEN 'Muestra baja'
    WHEN s.muestra < 300 THEN 'Muestra media'
    ELSE 'Muestra alta'
  END AS calidad_muestra,
  CASE
    WHEN s.balance_opinion >= 70 THEN 'Muy positivo'
    WHEN s.balance_opinion >= 55 THEN 'Positivo'
    WHEN s.balance_opinion >= 45 THEN 'Neutral'
    WHEN s.balance_opinion >= 30 THEN 'Negativo'
    ELSE 'Muy negativo'
  END AS nivel
FROM scored s
CROSS JOIN maxes m
ORDER BY balance_ponderado DESC;
```

#### 📝 Notas técnicas

- **CTE base:** Calcula positivos y negativos por actor
- **CTE scored:** Genera el balance de opinión (0–100)
- **CTE maxes:** Encuentra la muestra más grande para ponderación
- **NULLIF:** Previene división por cero
- **calidad_muestra:** Clasificación cualitativa de confiabilidad estadística
  - Baja: < 100 menciones
  - Media: 100–299 menciones
  - Alta: ≥ 300 menciones
- **nivel:** Interpretación cualitativa del balance de opinión
- **Actores solo con neutrales:** Si un actor tiene únicamente menciones neutrales (pos=0, neg=0), su `balance_opinion` y `balance_ponderado` serán NULL, apareciendo al final del ranking
- **Empates en balance_ponderado:** Actores con mismo balance ponderado se ordenan alfabéticamente (agregar `actor ASC` al ORDER BY si se requiere control)

#### 📊 Interpretación de resultados

| balance_opinion | nivel | Interpretación |
|-----------------|-------|----------------|
| 70–100 | Muy positivo | Percepción altamente favorable |
| 55–69 | Positivo | Percepción favorable |
| 45–54 | Neutral | Opinión equilibrada o no polarizada |
| 30–44 | Negativo | Percepción desfavorable |
| 0–29 | Muy negativo | Percepción altamente desfavorable |

---

### Query 4: Evolución temporal de menciones

#### 🎯 Objetivo

Analizar la **evolución diaria/semanal** de menciones y sentimiento por actor político para identificar tendencias, picos de conversación y patrones temporales.

#### 🧠 Qué responde esta métrica

- ¿Cómo ha evolucionado la conversación sobre cada actor?
- ¿Cuándo ocurrieron picos de menciones (positivas o negativas)?
- ¿Hay patrones temporales (días de semana vs. fines de semana)?
- ¿Cómo se compara la tendencia entre actores?

#### 💡 Casos de uso

- Detectar eventos que generaron conversación (debates, declaraciones, crisis)
- Monitorear impacto de campañas en tiempo real
- Identificar días críticos para análisis cualitativo posterior
- Crear gráficos de línea de tiempo en Metabase

#### 📊 SQL

```sql
SELECT
  DATE_TRUNC('day', m.published_at)::DATE AS fecha,
  t.tag_name AS actor,
  COUNT(*) AS menciones_total,
  SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) AS menciones_positivas,
  SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) AS menciones_negativas,
  SUM(CASE WHEN m.sentiment = 'Neutral' THEN 1 ELSE 0 END) AS menciones_neutrales,
  ROUND(
    100.0 * SUM(CASE WHEN m.sentiment = 'Positivo' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
    1
  ) AS pct_positivo,
  ROUND(
    100.0 * SUM(CASE WHEN m.sentiment = 'Negativo' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
    1
  ) AS pct_negativo,
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

#### 📝 Notas técnicas

- **DATE_TRUNC:** Agrupa por día. Cambiar a `'week'` o `'hour'` según granularidad deseada
- **::DATE casting:** Convierte timestamp a fecha para mejor visualización
- **Porcentajes:** Se calculan para facilitar comparación entre días con diferente volumen
- **LEFT JOIN metrics:** Incluye menciones sin engagement (tratadas como 0)
- **ORDER BY fecha DESC:** Muestra días más recientes primero

#### 📊 Variantes de la query

**Agregación semanal:**
```sql
-- Cambiar línea 2:
DATE_TRUNC('week', m.published_at)::DATE AS semana,
-- Y ajustar GROUP BY y ORDER BY
```

**Solo días con actividad significativa:**
```sql
-- Agregar al final:
HAVING COUNT(*) >= 10  -- Mínimo 10 menciones por día
```

**Incluir día de la semana:**
```sql
-- Agregar al SELECT:
TO_CHAR(m.published_at, 'Day') AS dia_semana,
TO_CHAR(m.published_at, 'D') AS dia_numero  -- 1=Domingo, 7=Sábado
```

---

### Query 5: Validación de calidad de datos

#### 🎯 Objetivo

Identificar **problemas de calidad de datos** como menciones sin sentimiento, sin tags, sin métricas, o duplicados para auditoría y limpieza.

#### 🧠 Qué responde esta métrica

- ¿Hay menciones sin sentimiento asignado?
- ¿Existen menciones sin tags de actor?
- ¿Cuántas menciones no tienen métricas?
- ¿Qué porcentaje de datos está completo?

#### 💡 Casos de uso

- Auditoría de calidad después de cada carga ETL
- Identificar problemas en el proceso de exportación de YouScan
- Detectar menciones que requieren revisión manual
- Reportar KPIs de completitud de datos

#### 📊 SQL

```sql
-- Resumen de calidad de datos
WITH stats AS (
  SELECT
    COUNT(DISTINCT m.mention_id) AS total_menciones,
    COUNT(DISTINCT o.occurrence_id) AS total_occurrences,
    COUNT(DISTINCT CASE WHEN m.sentiment IS NULL OR m.sentiment = '' THEN m.mention_id END) AS sin_sentiment,
    COUNT(DISTINCT CASE WHEN me.mention_id IS NULL THEN m.mention_id END) AS sin_metrics,
    COUNT(DISTINCT CASE WHEN actor_tags.mention_id IS NULL THEN m.mention_id END) AS sin_actor_tags,
    COUNT(DISTINCT CASE WHEN m.published_at IS NULL THEN m.mention_id END) AS sin_fecha
  FROM mentions m
  JOIN mention_occurrences o ON o.mention_id = m.mention_id
  LEFT JOIN metrics me ON me.mention_id = m.mention_id
  LEFT JOIN (
    SELECT DISTINCT mt.mention_id
    FROM mention_tags mt
    JOIN tags t ON t.tag_id = mt.tag_id
    WHERE t.tag_type = 'actor'
  ) actor_tags ON actor_tags.mention_id = m.mention_id
  WHERE m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
    [[AND {{fecha}}]]
)
SELECT
  'Menciones únicas' AS metrica,
  total_menciones AS cantidad,
  '100.0' AS porcentaje_completitud
FROM stats

UNION ALL

SELECT
  'Occurrences (filas de archivo)',
  total_occurrences,
  ROUND(100.0 * total_occurrences / NULLIF(total_menciones, 0), 1)::TEXT
FROM stats

UNION ALL

SELECT
  'Menciones SIN sentimiento',
  sin_sentiment,
  ROUND(100.0 * sin_sentiment / NULLIF(total_menciones, 0), 1)::TEXT
FROM stats

UNION ALL

SELECT
  'Menciones SIN métricas',
  sin_metrics,
  ROUND(100.0 * sin_metrics / NULLIF(total_menciones, 0), 1)::TEXT
FROM stats

UNION ALL

SELECT
  'Menciones SIN tags de actor',
  sin_actor_tags,
  ROUND(100.0 * sin_actor_tags / NULLIF(total_menciones, 0), 1)::TEXT
FROM stats

UNION ALL

SELECT
  'Menciones SIN fecha',
  sin_fecha,
  ROUND(100.0 * sin_fecha / NULLIF(total_menciones, 0), 1)::TEXT
FROM stats

ORDER BY metrica;
```

#### 📝 Notas técnicas

- **Menciones vs. Occurrences:** Ratio debe ser ≥1 (una mención puede aparecer en múltiples cargas)
- **Sin sentimiento:** Idealmente 0%, si >5% indica problema en exportación de YouScan
- **Sin métricas:** Normal para menciones de news/blogs (esperado 20-40%)
- **Sin actor tags:** Idealmente 0% si el análisis es exclusivamente político
- **Sin fecha:** Crítico, debe ser 0%

#### 🚨 Umbrales de alerta

| Métrica | Umbral OK | Umbral Advertencia | Umbral Crítico |
|---------|-----------|-------------------|----------------|
| Sin sentimiento | < 2% | 2-5% | > 5% |
| Sin métricas | < 50% | 50-70% | > 70% |
| Sin actor tags | < 5% | 5-10% | > 10% |
| Sin fecha | 0% | 0% | > 0% |

#### 📊 Query adicional: Detalle de menciones problemáticas

```sql
-- Listar menciones con problemas para revisión
SELECT
  m.mention_id,
  m.external_id,
  m.published_at,
  m.source_type,
  m.sentiment,
  m.url,
  CASE
    WHEN m.sentiment IS NULL THEN '❌ Sin sentiment'
    WHEN me.mention_id IS NULL THEN '⚠️ Sin metrics'
    WHEN actor_tags.mention_id IS NULL THEN '❌ Sin actor tags'
    ELSE '✅ OK'
  END AS problema,
  SUBSTRING(m.body_text, 1, 100) AS preview
FROM mentions m
JOIN mention_occurrences o ON o.mention_id = m.mention_id
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

---

## 🎛️ Variables dinámicas en Metabase

Las consultas incluyen variables parametrizadas que permiten filtrado interactivo en Metabase.

### Sintaxis de variables

```sql
[[AND {{nombre_variable}}]]
```

- Los dobles corchetes `[[ ]]` hacen la cláusula opcional
- Si la variable no tiene valor, toda la cláusula se omite
- El `AND` se incluye dentro de los corchetes para mantener sintaxis SQL válida

### Variables disponibles

#### `{{actor}}`
**Tipo:** Text / Field Filter
**Descripción:** Filtra por uno o más actores políticos específicos
**Ejemplo SQL:** `t.tag_name = {{actor}}`
**Uso:** Analizar un actor individual o comparar un subconjunto

#### `{{fecha}}`
**Tipo:** Date Range / Field Filter
**Descripción:** Filtra por rango de fechas
**Campo:** `m.published_at`
**Ejemplo SQL:** `m.published_at::DATE BETWEEN {{fecha}}`
**Uso:** Análisis de periodos específicos (semanal, mensual, campaña)

#### `{{source_system}}`
**Tipo:** Text / Field Filter
**Descripción:** Filtra por sistema de origen (ej. "youscan", "monito")
**Campo:** `m.source_system`
**Ejemplo SQL:** `m.source_system = {{source_system}}`
**Uso:** Comparar datos de diferentes plataformas de listening

#### `{{source_type}}`
**Tipo:** Text / Field Filter
**Descripción:** Filtra por tipo de fuente (ej. "social", "news", "blog")
**Campo:** `m.source_type`
**Ejemplo SQL:** `m.source_type = {{source_type}}`
**Uso:** Segmentar análisis por tipo de medio

### Ejemplo de configuración en Metabase

1. Al crear una pregunta SQL, las variables se detectan automáticamente
2. Configurar cada variable:
   - **Widget type:** "Field Filter" (recomendado) o "Text"
   - **Field to map to:** Seleccionar el campo correspondiente de la tabla
   - **Default value:** Opcional, puede dejarse vacío para mostrar todos los datos
3. Las variables aparecerán como filtros en el dashboard

---

## 📚 Glosario

| Término | Definición |
|---------|------------|
| **Mención** | Publicación o comentario en medios digitales que contiene términos monitoreados |
| **Sentimiento** | Clasificación emocional de la mención (positivo/negativo/neutral) generada por YouScan |
| **Engagement** | Suma de interacciones (likes, comments, shares) en una mención |
| **Actor** | Persona, partido o entidad política monitoreada mediante tags |
| **Tag** | Etiqueta utilizada para clasificar menciones (actor, categoría, query) |
| **Occurrence** | Aparición de una mención en un archivo de carga específico |
| **Balance ponderado** | Índice (0–100) que combina sentimiento con volumen de menciones |
| **Muestra** | Cantidad de menciones con sentimiento positivo o negativo (excluye neutrales) |

---

## 🔗 Referencias

- **Script ETL:** [etl_youscan.py](../etl_youscan.py)
- **Esquema de base de datos:** [sql/001_init.sql](../sql/001_init.sql)
- **Configuración Docker:** [docker-compose.yml](../docker-compose.yml)

---

## 📄 Licencia y uso

Este documento describe el sistema de análisis político para uso interno. Las consultas SQL pueden adaptarse según necesidades específicas de análisis.

