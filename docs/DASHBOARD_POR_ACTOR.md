# 📊 Dashboard por Actor Político - Guía de Implementación

**Fecha:** 2026-01-10
**Versión:** 1.0
**Estado:** ✅ LISTO PARA IMPLEMENTAR

---

## 🎯 Descripción General

El **Dashboard por Actor Político** es la segunda fase del MVP Dashboard. Permite analizar en detalle el desempeño de un actor político específico a través de métricas, series temporales y distribuciones de sentimiento.

**Diferencia con Dashboard General:**
- **Dashboard General:** Compara múltiples actores lado a lado
- **Dashboard por Actor:** Análisis profundo de UN actor con evolución temporal

---

## 📦 Componentes del Dashboard

### Filtros Globales (3)

Todos los filtros son **OPCIONALES**:

| Filtro | Variable | Tipo | Campo Mapeado |
|--------|----------|------|---------------|
| **Actor Político** | `{{actor}}` | Field Filter → Dropdown | `tags.tag_name` |
| **Fecha** | `{{fecha}}` | Field Filter → Date Range | `mentions.published_at` |
| **Plataforma** | `{{source_name}}` | Field Filter → String | `mentions.source_name` |

**Comportamiento:** Si no se selecciona ningún filtro, muestra datos agregados de todos los actores.

---

## 📊 Queries del Dashboard (8 en total)

### Sección 1: Métricas Principales (2 Tarjetas)

#### Query 1: Total de Menciones
- **Archivo:** [actor_01_tarjeta_menciones.sql](../sql/actor_01_tarjeta_menciones.sql)
- **Visualización:** Número grande (Number/Scalar)
- **Formato:** `123,456`
- **Propósito:** Mostrar el total de menciones del actor seleccionado

#### Query 2: Total de Engagement
- **Archivo:** [actor_02_tarjeta_engagement.sql](../sql/actor_02_tarjeta_engagement.sql)
- **Visualización:** Número grande (Number/Scalar)
- **Formato:** `123,456`
- **Propósito:** Mostrar el engagement total del actor seleccionado
- **Nota:** Usa LEFT JOIN para incluir menciones sin engagement

---

### Sección 2: Series Temporales de Menciones (2 Gráficas)

#### Query 3: Evolución de Menciones Totales
- **Archivo:** [actor_03_serie_menciones.sql](../sql/actor_03_serie_menciones.sql)
- **Visualización:** Line Chart o Bar Chart
- **Ejes:**
  - X: `fecha` (agrupado por día)
  - Y: `total_menciones`
- **Propósito:** Ver tendencias de menciones a lo largo del tiempo

#### Query 4: Evolución de Menciones por Sentimiento
- **Archivo:** [actor_04_serie_menciones_sentimiento.sql](../sql/actor_04_serie_menciones_sentimiento.sql)
- **Visualización:** Line Chart (múltiples series) o Area Chart (stacked)
- **Ejes:**
  - X: `fecha` (agrupado por día)
  - Y: `total_menciones`
  - Series: `sentiment` (Positivo, Negativo, Neutral)
- **Colores:**
  - Positivo: `#10b981` (verde)
  - Negativo: `#ef4444` (rojo)
  - Neutral: `#9ca3af` (gris)
- **Propósito:** Comparar tendencias de sentimiento a lo largo del tiempo

---

### Sección 3: Series Temporales de Engagement (2 Gráficas)

#### Query 5: Evolución de Engagement Total
- **Archivo:** [actor_05_serie_engagement.sql](../sql/actor_05_serie_engagement.sql)
- **Visualización:** Line Chart o Bar Chart
- **Ejes:**
  - X: `fecha` (agrupado por día)
  - Y: `total_engagement`
- **Propósito:** Ver tendencias de engagement a lo largo del tiempo
- **Nota:** Usa LEFT JOIN para incluir menciones sin engagement

#### Query 6: Evolución de Engagement por Sentimiento
- **Archivo:** [actor_06_serie_engagement_sentimiento.sql](../sql/actor_06_serie_engagement_sentimiento.sql)
- **Visualización:** Line Chart (múltiples series) o Area Chart (stacked)
- **Ejes:**
  - X: `fecha` (agrupado por día)
  - Y: `total_engagement`
  - Series: `sentiment` (Positivo, Negativo, Neutral)
- **Colores:** Mismos que Query 4
- **Propósito:** Comparar tendencias de engagement por sentimiento
- **Nota:** Usa LEFT JOIN para incluir menciones sin engagement

---

### Sección 4: Distribución de Sentimiento (2 Gráficas de Pastel)

#### Query 7: Menciones por Sentimiento (%)
- **Archivo:** [actor_07_pastel_menciones.sql](../sql/actor_07_pastel_menciones.sql)
- **Visualización:** Pie Chart
- **Dimensión:** `sentiment`
- **Métrica:** `total_menciones` o `porcentaje`
- **Propósito:** Ver distribución porcentual de menciones por sentimiento
- **Display:**
  - Show labels: Sí
  - Show percentages: Sí
  - Show values: Opcional

#### Query 8: Engagement por Sentimiento (%)
- **Archivo:** [actor_08_pastel_engagement.sql](../sql/actor_08_pastel_engagement.sql)
- **Visualización:** Pie Chart
- **Dimensión:** `sentiment`
- **Métrica:** `total_engagement` o `porcentaje`
- **Propósito:** Ver distribución porcentual de engagement por sentimiento
- **Display:** Mismo que Query 7
- **Nota:** Usa LEFT JOIN para incluir menciones sin engagement

---

## 🎨 Layout Propuesto del Dashboard

```
┌───────────────────────────────────────────────────────────────────────────┐
│  📊 ANÁLISIS POR ACTOR POLÍTICO                                           │
├───────────────────────────────────────────────────────────────────────────┤
│  Filtros: [👤 Actor: Seleccionar ▼] [📅 Fecha: Rango ▼] [🌐 Plataforma ▼]│
├───────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  📈 MÉTRICAS PRINCIPALES                                                  │
│  ┌────────────────────────┬────────────────────────┐                     │
│  │  Query 1               │  Query 2               │                     │
│  │  Total Menciones       │  Total Engagement      │                     │
│  │  ┏━━━━━━━━━━━━━━━━┓   │  ┏━━━━━━━━━━━━━━━━┓   │                     │
│  │  ┃    8,417       ┃   │  ┃   274,001      ┃   │                     │
│  │  ┗━━━━━━━━━━━━━━━━┛   │  ┗━━━━━━━━━━━━━━━━┛   │                     │
│  └────────────────────────┴────────────────────────┘                     │
│                                                                            │
│  📊 EVOLUCIÓN DE MENCIONES                                                │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Query 3: Menciones Totales (línea/barras)                         │  │
│  │  ╱╲    ╱╲                                                          │  │
│  │ ╱  ╲  ╱  ╲╱╲                                                       │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Query 4: Menciones por Sentimiento (líneas múltiples/área)       │  │
│  │  ████ Positivo  ████ Negativo  ████ Neutral                       │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
│  💬 EVOLUCIÓN DE ENGAGEMENT                                               │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Query 5: Engagement Total (línea/barras)                          │  │
│  │  ╱╲    ╱╲                                                          │  │
│  │ ╱  ╲  ╱  ╲╱╲                                                       │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Query 6: Engagement por Sentimiento (líneas múltiples/área)      │  │
│  │  ████ Positivo  ████ Negativo  ████ Neutral                       │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
│  🥧 DISTRIBUCIÓN DE SENTIMIENTO                                           │
│  ┌─────────────────────────┬─────────────────────────┐                   │
│  │  Query 7                │  Query 8                │                   │
│  │  Menciones (%)          │  Engagement (%)         │                   │
│  │      ╱──╲               │      ╱──╲              │                   │
│  │     │ 🥧 │              │     │ 🥧 │             │                   │
│  │      ╲──╱               │      ╲──╱              │                   │
│  └─────────────────────────┴─────────────────────────┘                   │
│                                                                            │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Guía de Implementación Paso a Paso

### Paso 1: Crear las 8 Queries en Metabase (40-60 min)

Para cada query, seguir estos pasos:

1. **Navegar a:** Metabase → New → SQL query
2. **Seleccionar base de datos:** `youscan`
3. **Copiar y pegar el SQL** desde el archivo correspondiente
4. **Configurar variables:**
   - Click en "Variables" (icono {})
   - Para cada variable `{{nombre}}`:
     - Type: **Field Filter**
     - Field to map to: (ver tabla de mapeo abajo)
     - Widget type: (ver tabla de mapeo abajo)
     - Default: **vacío** (opcional)
5. **Guardar query** con nombre descriptivo
6. **Configurar visualización** (ver tabla de visualizaciones abajo)

#### Tabla de Mapeo de Variables

| Variable | Field to Map | Widget Type |
|----------|--------------|-------------|
| `{{actor}}` | `Tags → Tag Name` | String/Dropdown |
| `{{fecha}}` | `Mentions → Published At` | Date Range |
| `{{source_name}}` | `Mentions → Source Name` | String |

#### Tabla de Visualizaciones

| Query | Tipo de Visualización | Configuración Especial |
|-------|----------------------|------------------------|
| Query 1 | Number/Scalar | Separador de miles |
| Query 2 | Number/Scalar | Separador de miles |
| Query 3 | Line Chart / Bar Chart | X: fecha, Y: total_menciones |
| Query 4 | Line Chart / Area (stacked) | X: fecha, Y: total_menciones, Series: sentiment |
| Query 5 | Line Chart / Bar Chart | X: fecha, Y: total_engagement |
| Query 6 | Line Chart / Area (stacked) | X: fecha, Y: total_engagement, Series: sentiment |
| Query 7 | Pie Chart | Dimension: sentiment, Metric: total_menciones |
| Query 8 | Pie Chart | Dimension: sentiment, Metric: total_engagement |

---

### Paso 2: Crear el Dashboard (10 min)

1. **Crear nuevo dashboard:**
   - Click en "New" → "Dashboard"
   - Nombre: "Dashboard por Actor Político"
   - Descripción: "Análisis detallado de un actor político con evolución temporal"

2. **Agregar queries al dashboard:**
   - Click en "Add a question"
   - Seleccionar cada query creada en Paso 1
   - Arrastrar y ajustar tamaño según layout propuesto

3. **Configurar filtros globales:**
   - Click en "Add a filter"
   - Agregar 3 filtros:
     - **Filtro 1:** Actor Político (Text/Dropdown)
       - Conectar a: variable `{{actor}}` de todas las 8 queries
     - **Filtro 2:** Fecha (Date Range)
       - Conectar a: variable `{{fecha}}` de todas las 8 queries
     - **Filtro 3:** Plataforma (Text)
       - Conectar a: variable `{{source_name}}` de todas las 8 queries

4. **Guardar dashboard**

---

### Paso 3: Configurar Colores de Sentimiento (5 min)

Para Queries 4, 6, 7 y 8, configurar colores manualmente:

1. Click en la visualización → Settings (⚙️)
2. En "Series settings" o "Color":
   - **Positivo:** `#10b981` (verde esmeralda)
   - **Negativo:** `#ef4444` (rojo coral)
   - **Neutral:** `#9ca3af` (gris medio)

---

### Paso 4: Validación Final (5 min)

Checklist de validación:

- [ ] Las 8 queries se ejecutan sin errores
- [ ] Los 3 filtros funcionan correctamente
- [ ] Seleccionar un actor muestra datos específicos de ese actor
- [ ] Seleccionar rango de fechas filtra todas las gráficas
- [ ] Seleccionar plataforma filtra todas las gráficas
- [ ] Colores de sentimiento son consistentes
- [ ] Totales en tarjetas son coherentes con gráficas
- [ ] Dashboard carga en menos de 5 segundos

---

## 📋 Archivos SQL del Proyecto

| # | Archivo | Propósito | Tamaño |
|---|---------|-----------|--------|
| 1 | [actor_01_tarjeta_menciones.sql](../sql/actor_01_tarjeta_menciones.sql) | Tarjeta: Total Menciones | ~1.5 KB |
| 2 | [actor_02_tarjeta_engagement.sql](../sql/actor_02_tarjeta_engagement.sql) | Tarjeta: Total Engagement | ~1.6 KB |
| 3 | [actor_03_serie_menciones.sql](../sql/actor_03_serie_menciones.sql) | Serie Temporal: Menciones | ~1.7 KB |
| 4 | [actor_04_serie_menciones_sentimiento.sql](../sql/actor_04_serie_menciones_sentimiento.sql) | Serie Temporal: Menciones × Sentimiento | ~2.0 KB |
| 5 | [actor_05_serie_engagement.sql](../sql/actor_05_serie_engagement.sql) | Serie Temporal: Engagement | ~1.8 KB |
| 6 | [actor_06_serie_engagement_sentimiento.sql](../sql/actor_06_serie_engagement_sentimiento.sql) | Serie Temporal: Engagement × Sentimiento | ~2.1 KB |
| 7 | [actor_07_pastel_menciones.sql](../sql/actor_07_pastel_menciones.sql) | Pie Chart: Menciones × Sentimiento | ~1.9 KB |
| 8 | [actor_08_pastel_engagement.sql](../sql/actor_08_pastel_engagement.sql) | Pie Chart: Engagement × Sentimiento | ~2.0 KB |

**Total:** ~15 KB de código SQL

---

## 🔧 Características Técnicas

### Variables Opcionales

Todos los queries usan la sintaxis `[[AND {{variable}}]]` para filtros opcionales:

```sql
WHERE t.tag_type = 'actor'
  [[AND t.tag_name = {{actor}}]]        -- Opcional
  [[AND {{fecha}}]]                      -- Opcional
  [[AND {{source_name}}]]                -- Opcional
```

**Comportamiento:** Sin selección = Muestra todos los datos

### LEFT JOIN Pattern

Queries 2, 5, 6 y 8 usan LEFT JOIN con `metrics`:

```sql
LEFT JOIN metrics me ON me.mention_id = o.mention_id
```

**Propósito:** Incluir menciones sin engagement (tratadas como 0)

### Agrupación Temporal

Queries 3, 4, 5 y 6 usan `DATE_TRUNC('day', ...)`:

```sql
DATE_TRUNC('day', m.published_at) AS fecha
```

**Opciones de agrupación:**
- `'day'` - Por día (default, recomendado para rangos ≤ 30 días)
- `'week'` - Por semana (para rangos > 30 días)
- `'month'` - Por mes (para análisis anual)

### Cálculo de Porcentajes

Queries 7 y 8 calculan porcentajes usando window functions:

```sql
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS porcentaje
```

**Resultado:** Porcentaje con 2 decimales (ej: 45.67%)

---

## 🎯 Casos de Uso

### Caso 1: Análisis de un Actor Específico
1. Seleccionar actor: "Andrea Chávez"
2. Seleccionar rango: Última semana
3. Ver evolución temporal de menciones y engagement
4. Identificar picos de actividad
5. Analizar distribución de sentimiento

### Caso 2: Comparación de Periodos
1. Seleccionar actor
2. Periodo 1: Enero 2026
3. Tomar screenshot
4. Cambiar a Periodo 2: Diciembre 2025
5. Comparar métricas

### Caso 3: Análisis por Plataforma
1. Seleccionar actor
2. Filtrar por plataforma: "facebook.com"
3. Ver qué sentimiento predomina en Facebook
4. Cambiar a "twitter.com"
5. Comparar diferencias entre plataformas

---

## 🔍 Troubleshooting

### Problema: Las variables no aparecen en el dashboard

**Solución:**
- Verificar sintaxis: `{{variable}}` con dobles llaves
- Verificar que el mapeo de Field Filter esté correcto
- Refresh de la página de Metabase

### Problema: Error "column does not exist"

**Solución:**
- Verificar que estás conectado a la base de datos `youscan`
- Verificar que las tablas existen: `mentions`, `mention_occurrences`, `mention_tags`, `tags`, `metrics`

### Problema: LEFT JOIN no funciona

**Solución:**
- Verificar que dice exactamente `LEFT JOIN` (no `JOIN`)
- Verificar que la condición es `ON me.mention_id = o.mention_id`

### Problema: Series temporales muestran muchos datos

**Solución:**
- Cambiar `DATE_TRUNC('day', ...)` a `DATE_TRUNC('week', ...)`
- Aplicar filtro de fecha para limitar el rango

### Problema: Colores no se aplican automáticamente

**Solución:**
- Configurar manualmente en Settings → Series/Colors
- Aplicar a cada query individualmente

---

## 📊 Métricas Esperadas

Basado en datos del periodo 2025-12-29 a 2026-01-04:

### Ejemplo: Andrea Chávez

| Métrica | Valor |
|---------|-------|
| Total Menciones | 8,417 |
| Total Engagement | 274,001 |
| Menciones Positivas | 1,580 (18.8%) |
| Menciones Negativas | 1,688 (20.0%) |
| Menciones Neutrales | 5,149 (61.2%) |
| Engagement Positivo | 77,979 (28.5%) |
| Engagement Negativo | 72,248 (26.4%) |
| Engagement Neutral | 123,774 (45.2%) |

---

## ✅ Checklist de Implementación

### Preparación (Completado ✅)
- [x] 8 queries SQL creados
- [x] Variables opcionales implementadas
- [x] LEFT JOIN verificado en queries necesarios
- [x] Agrupación temporal por día configurada
- [x] Cálculo de porcentajes implementado
- [x] Documentación completa

### Implementación Usuario (Pendiente)
- [ ] Crear Query 1 en Metabase (5 min)
- [ ] Crear Query 2 en Metabase (5 min)
- [ ] Crear Query 3 en Metabase (5 min)
- [ ] Crear Query 4 en Metabase (7 min)
- [ ] Crear Query 5 en Metabase (5 min)
- [ ] Crear Query 6 en Metabase (7 min)
- [ ] Crear Query 7 en Metabase (5 min)
- [ ] Crear Query 8 en Metabase (5 min)
- [ ] Crear dashboard (5 min)
- [ ] Conectar filtros globales (5 min)
- [ ] Configurar colores (5 min)
- [ ] Validación final (5 min)

**Tiempo total estimado:** 60-70 minutos

---

## 🎓 Recursos Adicionales

### Documentación Relacionada
- [MVP Dashboard General - Guía](GUIA_MVP_DASHBOARD.md)
- [MVP Estado Final](MVP_ESTADO_FINAL.md)
- [MVP Validación](MVP_VALIDACION_FINAL.md)
- [Índice General](INDICE.md)

### Actores Disponibles
Basado en datos del periodo validado:
1. Andrea Chávez
2. Maru Campos
3. Ariadna Montiel
4. Cruz Pérez Cuéllar
5. Rosa Icela Rodríguez
6. Claudia Sheinbaum
7. Xóchitl Gálvez

### Plataformas Principales
- facebook.com (80.8%)
- twitter.com (15.0%)
- youtube.com (1.5%)
- instagram.com (1.2%)
- Otras 300+ plataformas (1.5%)

---

## 🎉 Conclusión

El **Dashboard por Actor Político** está 100% listo para implementar. Todos los queries han sido validados técnicamente y la documentación está completa.

**Siguiente paso:** Seguir la Guía de Implementación Paso a Paso (Sección "🚀 Guía de Implementación").

**Tiempo estimado de implementación:** 60-70 minutos

---

**Versión:** 1.0
**Fecha:** 2026-01-10
**Desarrollado con:** Claude Sonnet 4.5
**Estado:** ✅ LISTO PARA PRODUCCIÓN
