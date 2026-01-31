# 📋 Plan de Implementación de Mejoras - YouScan ETL

> **Documento de trabajo para implementar correcciones y mejoras al sistema de análisis político**

**Fecha:** 2026-01-07
**Autor:** Equipo de Datos
**Estado:** Pendiente de aprobación

---

## 📊 Resumen Ejecutivo

Este plan detalla las mejoras necesarias para corregir problemas identificados en las queries SQL del sistema YouScan ETL y optimizar su rendimiento y precisión.

### Problemas identificados

| Prioridad | Problema | Impacto | Queries afectadas |
|-----------|----------|---------|-------------------|
| 🔴 **Crítico** | INNER JOIN con metrics excluye menciones sin engagement | Alto - sesgo de datos | Query 2 |
| 🟡 **Alto** | Falta documentación de comportamiento de co-menciones | Medio - interpretación incorrecta | Todas |
| 🟡 **Medio** | Inconsistencia en variables de filtrado | Medio - UX inconsistente | Queries 1, 2 |
| 🟢 **Bajo** | Falta de índices para optimización | Bajo - performance | Schema SQL |
| 🟢 **Bajo** | Falta query de evolución temporal | Bajo - análisis limitado | N/A |

### Tiempo estimado de implementación

- **Correcciones críticas:** 30 minutos
- **Mejoras de documentación:** 1 hora
- **Optimizaciones opcionales:** 2 horas
- **Total:** 3.5 horas

---

## 🎯 Fase 1: Correcciones Críticas (Obligatorias)

### 1.1. Corregir Query 2 - JOIN con metrics

**Objetivo:** Evitar exclusión de menciones sin métricas de engagement

**Archivo:** `docs/CLAUDE.md`

**Problema actual:**
```sql
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN metrics me ON me.mention_id = m.mention_id  -- ❌ INNER JOIN
```

**Solución:**
```sql
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
LEFT JOIN metrics me ON me.mention_id = m.mention_id  -- ✅ LEFT JOIN
```

**Pasos de implementación:**

1. **Abrir archivo:** `docs/CLAUDE.md`
2. **Ubicar:** Línea ~232 (Query 2 - sección SQL)
3. **Modificar:** Cambiar `JOIN metrics me` por `LEFT JOIN metrics me`
4. **Actualizar nota técnica:** Agregar al final de "📝 Notas técnicas" de Query 2:
   ```markdown
   - **LEFT JOIN crítico:** Se usa LEFT JOIN para incluir menciones sin métricas disponibles (el COALESCE las trata como 0)
   ```

**Validación:**
- [ ] Ejecutar Query 2 en PostgreSQL
- [ ] Verificar que el número de menciones coincida con Query 1
- [ ] Confirmar que actores con menciones sin métricas aparezcan

**Criterio de éxito:**
- Query 2 retorna todos los actores que aparecen en Query 1
- Menciones sin métricas se cuentan con engagement=0

---

### 1.2. Estandarizar variables de filtrado

**Objetivo:** Consistencia en todas las queries

**Archivo:** `docs/CLAUDE.md`

**Cambios requeridos:**

#### Query 1: Agregar variables source_system y source_type

**Ubicar:** Línea ~188 (cláusula WHERE de Query 1)

**Antes:**
```sql
WHERE t.tag_type = 'actor'
  AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
  [[AND {{actor}}]]
  [[AND {{fecha}}]]
```

**Después:**
```sql
WHERE t.tag_type = 'actor'
  AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
  [[AND {{actor}}]]
  [[AND {{fecha}}]]
  [[AND {{source_system}}]]
  [[AND {{source_type}}]]
```

#### Query 2: Agregar variables source_system y source_type

**Ubicar:** Línea ~237 (cláusula WHERE de Query 2)

**Antes:**
```sql
WHERE t.tag_type = 'actor'
  AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
  [[AND {{actor}}]]
```

**Después:**
```sql
WHERE t.tag_type = 'actor'
  AND m.published_at::DATE BETWEEN '2025-12-29' AND '2026-01-04'
  [[AND {{actor}}]]
  [[AND {{fecha}}]]
  [[AND {{source_system}}]]
  [[AND {{source_type}}]]
```

**Validación:**
- [ ] Todas las queries (1, 2, 3) tienen las mismas 4 variables opcionales
- [ ] Variables aparecen en el mismo orden en todas las queries
- [ ] Sintaxis `[[AND {{variable}}]]` es correcta

---

## 🎯 Fase 2: Mejoras de Documentación (Recomendadas)

### 2.1. Documentar comportamiento de co-menciones

**Objetivo:** Aclarar que menciones con múltiples actores se cuentan para cada uno

**Archivo:** `docs/CLAUDE.md`

**Ubicar:** Sección "### Reglas de negocio clave" (línea ~145)

**Agregar como punto 5:**

```markdown
5. **Co-menciones y atribución múltiple:** Cuando una mención incluye múltiples actores (ej. "AMLO y Sheinbaum en evento"), se contabiliza para cada actor individualmente. Esto significa:
   - Una mención con 3 actores suma +1 a cada uno (total sistema: 3)
   - El engagement se suma completo a cada actor (no se divide)
   - El total agregado puede ser mayor que el número único de menciones
   - Este comportamiento es intencional para medir **atribución por actor** en lugar de totales únicos
```

**Validación:**
- [ ] Texto es claro y no técnico
- [ ] Incluye ejemplo concreto
- [ ] Explica el "por qué" del diseño

---

### 2.2. Agregar sección de consideraciones técnicas

**Objetivo:** Documentar edge cases y limitaciones

**Archivo:** `docs/CLAUDE.md`

**Ubicar:** Después de "## 🔍 Consultas SQL principales" y antes de Query 1

**Agregar nueva sección:**

```markdown
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
```

**Validación:**
- [ ] Sección aparece antes de las queries
- [ ] Formato es consistente con el resto del documento
- [ ] Ejemplos son claros y realistas

---

### 2.3. Mejorar notas técnicas de Query 3

**Objetivo:** Explicar casos edge del balance ponderado

**Archivo:** `docs/CLAUDE.md`

**Ubicar:** Sección "📝 Notas técnicas" de Query 3 (línea ~346)

**Agregar al final de las notas:**

```markdown
- **Actores solo con neutrales:** Si un actor tiene únicamente menciones neutrales (pos=0, neg=0), su `balance_opinion` y `balance_ponderado` serán NULL, apareciendo al final del ranking
- **Empates en balance_ponderado:** Actores con mismo balance ponderado se ordenan alfabéticamente (agregar `actor ASC` al ORDER BY si se requiere control)
```

**Validación:**
- [ ] Texto integrado correctamente en la lista existente
- [ ] Formato de lista con viñetas `-` es consistente

---

## 🎯 Fase 3: Optimizaciones de Base de Datos (Opcionales)

### 3.1. Agregar índices de optimización

**Objetivo:** Mejorar performance de queries frecuentes

**Archivo:** `sql/001_init.sql`

**Ubicar:** Final del archivo (después de la última tabla)

**Agregar sección:**

```sql
-- ==============================================
-- ÍNDICES DE OPTIMIZACIÓN
-- ==============================================
-- Agregados para optimizar queries de análisis político
-- Fecha: 2026-01-07

-- Optimización para filtrado por tipo y nombre de tag
-- Beneficia: Queries 1, 2, 3 (filtro WHERE tag_type = 'actor')
CREATE INDEX IF NOT EXISTS ix_tags_type_name
ON tags (tag_type, tag_name);

-- Optimización para filtros por fuente y fecha
-- Beneficia: Queries con filtros source_system, source_type, published_at
CREATE INDEX IF NOT EXISTS ix_mentions_source_published
ON mentions (source_system, source_type, published_at);

-- Optimización para join con mention_occurrences
-- Beneficia: Todas las queries principales (join crítico)
CREATE INDEX IF NOT EXISTS ix_mention_occurrences_mention_id
ON mention_occurrences (mention_id);

-- Índice compuesto para análisis de sentimiento por fecha
-- Beneficia: Queries que filtran por fecha Y sentimiento
CREATE INDEX IF NOT EXISTS ix_mentions_published_sentiment
ON mentions (published_at, sentiment);

-- Nota: El índice ix_mentions_published_at ya existe (línea 64-65)
-- Nota: El índice ix_mention_tags_tag_id ya existe (línea 107-108)
```

**Pasos de implementación:**

1. **Backup de base de datos:**
   ```bash
   pg_dump -h localhost -p 5433 -U youscan_admin youscan > backup_pre_indices.sql
   ```

2. **Aplicar cambios al archivo SQL:**
   - Abrir `sql/001_init.sql`
   - Agregar la sección al final

3. **Ejecutar índices en base de datos existente:**
   ```bash
   psql -h localhost -p 5433 -U youscan_admin -d youscan -c "
   CREATE INDEX IF NOT EXISTS ix_tags_type_name ON tags (tag_type, tag_name);
   CREATE INDEX IF NOT EXISTS ix_mentions_source_published ON mentions (source_system, source_type, published_at);
   CREATE INDEX IF NOT EXISTS ix_mention_occurrences_mention_id ON mention_occurrences (mention_id);
   CREATE INDEX IF NOT EXISTS ix_mentions_published_sentiment ON mentions (published_at, sentiment);
   "
   ```

4. **Verificar creación:**
   ```sql
   -- Conectar a la base de datos y ejecutar:
   SELECT
     tablename,
     indexname,
     indexdef
   FROM pg_indexes
   WHERE schemaname = 'public'
     AND tablename IN ('tags', 'mentions', 'mention_occurrences')
   ORDER BY tablename, indexname;
   ```

**Validación:**
- [ ] Backup realizado exitosamente
- [ ] 4 índices nuevos creados (verificar con `\di` en psql)
- [ ] Queries ejecutan más rápido (medir con `EXPLAIN ANALYZE`)

**Rollback en caso de problemas:**
```sql
DROP INDEX IF EXISTS ix_tags_type_name;
DROP INDEX IF EXISTS ix_mentions_source_published;
DROP INDEX IF EXISTS ix_mention_occurrences_mention_id;
DROP INDEX IF EXISTS ix_mentions_published_sentiment;
```

---

### 3.2. Crear vista materializada para performance

**Objetivo:** Cache para queries frecuentes

**Archivo:** Nuevo archivo `sql/002_views.sql`

**Crear archivo con contenido:**

```sql
-- ==============================================
-- VISTAS MATERIALIZADAS
-- ==============================================
-- Cache de agregaciones frecuentes para mejorar performance
-- Se debe refrescar después de cada carga ETL

-- Vista: Menciones por actor y día
DROP MATERIALIZED VIEW IF EXISTS mv_mentions_by_actor_day CASCADE;

CREATE MATERIALIZED VIEW mv_mentions_by_actor_day AS
SELECT
  DATE_TRUNC('day', m.published_at)::DATE AS fecha,
  t.tag_name AS actor,
  m.source_system,
  m.source_type,
  m.sentiment,
  COUNT(DISTINCT o.mention_id) AS num_menciones,
  SUM(COALESCE(me.engagement, 0)) AS engagement_total,
  SUM(COALESCE(me.likes, 0)) AS likes_total,
  SUM(COALESCE(me.comments, 0)) AS comments_total,
  SUM(COALESCE(me.reposts, 0)) AS reposts_total
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
LEFT JOIN metrics me ON me.mention_id = m.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  AND m.published_at IS NOT NULL
GROUP BY
  DATE_TRUNC('day', m.published_at)::DATE,
  t.tag_name,
  m.source_system,
  m.source_type,
  m.sentiment;

-- Índices en la vista materializada
CREATE INDEX ix_mv_mentions_fecha_actor
ON mv_mentions_by_actor_day (fecha, actor);

CREATE INDEX ix_mv_mentions_actor
ON mv_mentions_by_actor_day (actor);

-- Comentarios
COMMENT ON MATERIALIZED VIEW mv_mentions_by_actor_day IS
'Vista materializada con agregaciones diarias por actor. Refrescar después de cada carga ETL con: REFRESH MATERIALIZED VIEW mv_mentions_by_actor_day;';
```

**Pasos de implementación:**

1. **Crear archivo:** `sql/002_views.sql` con el contenido de arriba

2. **Ejecutar en base de datos:**
   ```bash
   psql -h localhost -p 5433 -U youscan_admin -d youscan -f sql/002_views.sql
   ```

3. **Modificar script ETL:** Agregar refresco de vista al final de `etl_youscan.py`

   Ubicar la función `main()` al final del archivo y agregar antes del commit final:

   ```python
   # Refrescar vista materializada
   logger.info("Refrescando vista materializada...")
   cursor.execute("REFRESH MATERIALIZED VIEW mv_mentions_by_actor_day;")
   logger.info("Vista materializada actualizada")
   ```

**Validación:**
- [ ] Vista materializada creada exitosamente
- [ ] Índices creados en la vista
- [ ] Script ETL actualizado para refrescar vista
- [ ] Ejecución del ETL refresca la vista correctamente

**Uso de la vista:**

```sql
-- Query optimizada usando la vista
SELECT
  actor,
  SUM(CASE WHEN sentiment = 'Positivo' THEN num_menciones ELSE 0 END) AS positivas,
  SUM(CASE WHEN sentiment = 'Negativo' THEN num_menciones ELSE 0 END) AS negativas,
  SUM(CASE WHEN sentiment = 'Neutral' THEN num_menciones ELSE 0 END) AS neutrales,
  SUM(num_menciones) AS total
FROM mv_mentions_by_actor_day
WHERE fecha BETWEEN '2025-12-29' AND '2026-01-04'
GROUP BY actor
ORDER BY total DESC;
```

---

## 🎯 Fase 4: Queries Adicionales (Opcionales)

### 4.1. Query 4: Evolución temporal

**Objetivo:** Análisis de tendencias y series de tiempo

**Archivo:** `docs/CLAUDE.md`

**Ubicar:** Después de Query 3, antes de "## 🎛️ Variables dinámicas en Metabase"

**Agregar nueva sección:**

```markdown
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
```

**Validación:**
- [ ] Query ejecuta sin errores
- [ ] Formato de fecha es correcto (YYYY-MM-DD)
- [ ] Porcentajes suman ~100% por día/actor
- [ ] Ordenamiento cronológico es correcto

---

### 4.2. Query 5: Validación y calidad de datos

**Objetivo:** Detectar problemas de datos para auditoría

**Archivo:** `docs/CLAUDE.md`

**Ubicar:** Después de Query 4

**Agregar nueva sección:**

```markdown
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
```

**Validación:**
- [ ] Query de resumen ejecuta correctamente
- [ ] Porcentajes suman sentido lógico
- [ ] Query de detalle muestra menciones problemáticas
- [ ] Umbrales documentados son realistas

---

## 🎯 Fase 5: Actualización de Metabase (Opcional)

### 5.1. Recrear queries en Metabase

**Objetivo:** Aplicar cambios a dashboards existentes

**Herramienta:** Interfaz web de Metabase

**Pasos:**

1. **Acceder a Metabase:**
   - URL: http://localhost:3000 (o URL configurada)
   - Login con credenciales de admin

2. **Identificar preguntas existentes:**
   - Navegar a "Preguntas" → Buscar preguntas relacionadas con actores políticos
   - Listar IDs y nombres de preguntas a actualizar

3. **Para cada query modificada:**

   **Query 1 - Menciones por actor:**
   - Abrir pregunta en Metabase
   - Click en "..." → "Editar pregunta"
   - Cambiar a modo "SQL nativo"
   - Reemplazar SQL completo con versión corregida de CLAUDE.md
   - Click "Visualizar" para validar
   - Configurar variables:
     - `actor`: Field Filter → Tags → Tag Name
     - `fecha`: Field Filter → Mentions → Published At
     - `source_system`: Field Filter → Mentions → Source System
     - `source_type`: Field Filter → Mentions → Source Type
   - Guardar cambios

   **Query 2 - Engagement:**
   - Repetir proceso anterior
   - **CRÍTICO:** Verificar que el JOIN con metrics sea LEFT JOIN
   - Validar que el conteo de actores coincida con Query 1

   **Query 3 - Balance ponderado:**
   - Repetir proceso anterior
   - Verificar que variables adicionales funcionen correctamente

4. **Crear nuevas preguntas:**

   **Query 4 - Evolución temporal:**
   - Click "Nueva pregunta" → "SQL nativo"
   - Pegar SQL de Query 4
   - Configurar visualización como "Gráfico de líneas"
   - Eje X: fecha
   - Eje Y: menciones_total
   - Series: actor
   - Configurar variables de filtrado
   - Guardar como "Evolución temporal - Menciones por actor"

   **Query 5 - Calidad de datos:**
   - Click "Nueva pregunta" → "SQL nativo"
   - Pegar SQL de Query 5 (resumen)
   - Configurar como tabla
   - Guardar como "Auditoría - Calidad de datos"

5. **Actualizar dashboards:**
   - Abrir dashboard principal
   - Reemplazar visualizaciones antiguas con las nuevas
   - Ajustar tamaños y posiciones
   - Configurar filtros a nivel de dashboard
   - Guardar y publicar

**Validación:**
- [ ] Todas las queries ejecutan sin errores en Metabase
- [ ] Variables de filtrado funcionan correctamente
- [ ] Visualizaciones muestran datos coherentes
- [ ] Dashboards actualizados y publicados
- [ ] Filtros a nivel dashboard afectan todas las preguntas

---

## ✅ Checklist Final de Implementación

### Fase 1: Correcciones Críticas
- [ ] Query 2: JOIN cambiado a LEFT JOIN
- [ ] Query 1: Variables source_system y source_type agregadas
- [ ] Query 2: Variables fecha, source_system y source_type agregadas
- [ ] Todas las queries tienen las mismas 4 variables opcionales

### Fase 2: Documentación
- [ ] Regla de negocio #5 sobre co-menciones agregada
- [ ] Sección "Consideraciones técnicas" agregada antes de queries
- [ ] Notas técnicas de Query 3 mejoradas con casos edge

### Fase 3: Optimizaciones Base de Datos
- [ ] Backup de base de datos realizado
- [ ] 4 índices nuevos creados en sql/001_init.sql
- [ ] Índices aplicados en base de datos de desarrollo
- [ ] Vista materializada creada (sql/002_views.sql)
- [ ] Script ETL actualizado para refrescar vista

### Fase 4: Queries Adicionales
- [ ] Query 4 (Evolución temporal) agregada a CLAUDE.md
- [ ] Query 5 (Calidad de datos) agregada a CLAUDE.md
- [ ] Queries adicionales validadas en base de datos

### Fase 5: Metabase
- [ ] Queries 1, 2, 3 actualizadas en Metabase
- [ ] Query 4 creada en Metabase
- [ ] Query 5 creada en Metabase
- [ ] Dashboards actualizados
- [ ] Filtros configurados correctamente

---

## 🧪 Testing y Validación

### Test 1: Consistencia de conteos

```sql
-- Verificar que Query 1 y Query 2 retornan mismos actores
WITH q1 AS (
  -- Pegar Query 1 aquí
),
q2 AS (
  -- Pegar Query 2 aquí
)
SELECT
  COALESCE(q1.actor, q2.actor) AS actor,
  q1.total AS menciones_q1,
  q2.engagement_total AS engagement_q2,
  CASE
    WHEN q1.actor IS NULL THEN '❌ Falta en Query 1'
    WHEN q2.actor IS NULL THEN '❌ Falta en Query 2'
    ELSE '✅ OK'
  END AS status
FROM q1
FULL OUTER JOIN q2 ON q1.actor = q2.actor
ORDER BY COALESCE(q1.total, 0) DESC;
```

**Esperado:** Todos los actores aparecen en ambas queries con status "✅ OK"

### Test 2: Validación de balance ponderado

```sql
-- Verificar que balance_ponderado está en rango 0-100
SELECT
  actor,
  balance_opinion,
  balance_ponderado,
  CASE
    WHEN balance_opinion < 0 OR balance_opinion > 100 THEN '❌ Balance fuera de rango'
    WHEN balance_ponderado < 0 OR balance_ponderado > 100 THEN '❌ Ponderado fuera de rango'
    ELSE '✅ OK'
  END AS validacion
FROM (
  -- Pegar Query 3 aquí
) sub
WHERE balance_opinion IS NOT NULL;
```

**Esperado:** Todos con validacion "✅ OK"

### Test 3: Performance de índices

```sql
-- Medir tiempo de Query 1 con EXPLAIN ANALYZE
EXPLAIN ANALYZE
-- Pegar Query 1 aquí
```

**Esperado:**
- Planning time: < 5ms
- Execution time: < 500ms para datasets de ~10K menciones
- Uso de índices ix_tags_type_name visible en el plan

---

## 📊 Métricas de Éxito

| Métrica | Antes | Objetivo | Medición |
|---------|-------|----------|----------|
| Queries con bugs críticos | 1 (Query 2) | 0 | ✅ Manual |
| Consistencia de variables | 33% | 100% | ✅ Manual |
| Tiempo de ejecución Query 1 | ? | < 500ms | ⏱️ EXPLAIN ANALYZE |
| Tiempo de ejecución Query 2 | ? | < 800ms | ⏱️ EXPLAIN ANALYZE |
| Tiempo de ejecución Query 3 | ? | < 1000ms | ⏱️ EXPLAIN ANALYZE |
| Cobertura de documentación | 60% | 95% | ✅ Manual |
| Queries de validación | 0 | 1 | ✅ Manual |

---

## 🚀 Plan de Rollout

### Opción A: Implementación por fases (Recomendado)

**Semana 1:**
- Día 1-2: Fase 1 (Correcciones críticas) en dev
- Día 3: Testing y validación en dev
- Día 4: Deploy a producción
- Día 5: Monitoreo post-deploy

**Semana 2:**
- Día 1-2: Fase 2 (Documentación) y Fase 3 (Índices) en dev
- Día 3: Testing de performance
- Día 4: Deploy a producción
- Día 5: Validación de mejoras de performance

**Semana 3:**
- Día 1-3: Fase 4 (Queries adicionales) en dev
- Día 4: Fase 5 (Metabase)
- Día 5: Capacitación a usuarios

### Opción B: Implementación completa

**Día 1:**
- Todas las fases en ambiente de desarrollo
- Testing exhaustivo

**Día 2:**
- Deploy a producción en horario de bajo uso
- Monitoreo intensivo

**Día 3:**
- Validación con usuarios
- Ajustes menores

---

## 📞 Contacto y Soporte

**Responsables:**
- Implementación técnica: [Nombre del DBA/Dev]
- Validación de negocio: [Nombre del Analista Político]
- Aprobación final: [Nombre del Project Manager]

**Canales de comunicación:**
- Issues críticos: [Canal de Slack / Email]
- Seguimiento: [Reunión diaria / Reporte escrito]

---

## 📎 Anexos

### Anexo A: Scripts de respaldo

```bash
#!/bin/bash
# backup_database.sh
# Crear backup completo antes de cambios

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_youscan_${TIMESTAMP}.sql"

echo "Creando backup de base de datos..."
pg_dump -h localhost -p 5433 -U youscan_admin youscan > $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "✅ Backup creado exitosamente: $BACKUP_FILE"
    gzip $BACKUP_FILE
    echo "✅ Backup comprimido: ${BACKUP_FILE}.gz"
else
    echo "❌ Error al crear backup"
    exit 1
fi
```

### Anexo B: Script de rollback

```sql
-- rollback_indices.sql
-- Eliminar índices agregados en caso de problemas

DROP INDEX IF EXISTS ix_tags_type_name;
DROP INDEX IF EXISTS ix_mentions_source_published;
DROP INDEX IF EXISTS ix_mention_occurrences_mention_id;
DROP INDEX IF EXISTS ix_mentions_published_sentiment;

-- Eliminar vista materializada
DROP MATERIALIZED VIEW IF EXISTS mv_mentions_by_actor_day CASCADE;
```

### Anexo C: Queries de monitoreo

```sql
-- Monitorear uso de índices
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan AS veces_usado,
    idx_tup_read AS tuplas_leidas,
    idx_tup_fetch AS tuplas_obtenidas
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND tablename IN ('mentions', 'tags', 'mention_occurrences')
ORDER BY idx_scan DESC;

-- Monitorear tamaño de índices
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

**Fin del documento**

_Versión: 1.0_
_Última actualización: 2026-01-07_
