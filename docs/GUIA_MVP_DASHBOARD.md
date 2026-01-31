# 🚀 Guía MVP Dashboard - Implementación Inmediata

**Objetivo:** Dashboard operativo con 4 gráficas ✅ LOGRADO
**Fecha Creación:** 2026-01-08
**Fecha Implementación:** 2026-01-09
**Estado:** 🎉 IMPLEMENTADO Y EN PRODUCCIÓN

---

## 📊 Dashboard MVP - Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  📊 ANÁLISIS POLÍTICO - DASHBOARD GENERAL                       │
├─────────────────────────────────────────────────────────────────┤
│  Filtros: [Fecha Inicio] [Fecha Fin] [Source Type: Todos ▼]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  📈 MENCIONES                                                   │
│  ┌─────────────────────┬──────────────────────────────────────┐│
│  │  Gráfica 1:         │  Gráfica 2:                          ││
│  │  Total Menciones    │  Menciones por Sentimiento           ││
│  │  (barras)           │  (barras apiladas)                   ││
│  │                     │                                       ││
│  │  Andrea: 8,417      │  [Verde][Gris][Rojo] Andrea          ││
│  │  Maru: 5,186        │  [Verde][Gris][Rojo] Maru            ││
│  │  ...                │  ...                                  ││
│  └─────────────────────┴──────────────────────────────────────┘│
│                                                                  │
│  💬 ENGAGEMENT (IMPACTO)                                        │
│  ┌─────────────────────┬──────────────────────────────────────┐│
│  │  Gráfica 3:         │  Gráfica 4:                          ││
│  │  Total Engagement   │  Engagement por Sentimiento          ││
│  │  (barras)           │  (barras apiladas)                   ││
│  │                     │                                       ││
│  │  Andrea: 274,001    │  [Verde][Gris][Rojo] Andrea          ││
│  │  Cruz: 67,555       │  [Verde][Gris][Rojo] Cruz            ││
│  │  ...                │  ...                                  ││
│  └─────────────────────┴──────────────────────────────────────┘│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✅ Archivos SQL Creados

Todos los archivos están en [sql/](../sql/) y han sido validados con datos reales:

| # | Archivo | Descripción | Formato Salida | Estado |
|---|---------|-------------|----------------|--------|
| 1 | `mvp_01_menciones_total.sql` | Total de menciones por actor | actor, total_menciones | ✅ |
| 2 | `mvp_02_menciones_sentimiento.sql` | Menciones desglosadas por sentimiento | actor, positivas, negativas, neutrales, total | ✅ |
| 3 | `mvp_03_engagement_total.sql` | Total de engagement por actor | actor, total_engagement | ✅ |
| 4 | `mvp_04_engagement_sentimiento.sql` | Engagement desglosado por sentimiento | actor, positivas, negativas, neutrales, total | ✅ |

**Nota Importante:** Los Queries 2 y 4 utilizan formato de columnas (pivotado) para facilitar la visualización en tabla o gráficos de barras apiladas.

---

## 🎯 Paso a Paso - Implementación en Metabase

### Paso 1: Crear Query 1 - Total Menciones

1. **Abrir Metabase:** http://localhost:3000
2. **Nueva pregunta:** Botón "+ New" → SQL query
3. **Seleccionar BD:** youscan
4. **Copiar SQL:**

```sql
SELECT
  t.tag_name AS actor,
  COUNT(*) AS total_menciones
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  [[AND {{fecha}}]]
  [[AND {{source_name}}]]
GROUP BY t.tag_name
ORDER BY total_menciones DESC;
```

5. **Configurar variables OPCIONALES:**

**Variable 1: fecha**
- Type: **Field Filter**
- Field to map to: **Mentions → Published At**
- Widget type: **Date Range** (o Date Filter)
- Default: **vacío** (mostrará todos los datos)
- Label: "Fecha"

**Variable 2: source_name**
- Type: **Field Filter**
- Field to map to: **Mentions → Source Name**
- Widget type: **Dropdown** (o String filter)
- Default: **vacío** (mostrará todas las plataformas)
- Label: "Plataforma" (Facebook, Instagram, Twitter, etc.)

**IMPORTANTE:** Los corchetes dobles `[[ ]]` hacen que las variables sean opcionales.
Si no seleccionas valor, la query mostrará todos los datos sin filtrar.

6. **Configurar visualización:**
- Click "Visualization" en esquina inferior izquierda
- Seleccionar: **Bar chart**
- Settings:
  - X-axis: total_menciones
  - Y-axis: actor
  - Display: Horizontal bars
  - Show values: ON

7. **Guardar:**
- Nombre: "MVP - Total Menciones por Actor"
- Colección: (crear nueva) "MVP Dashboard"
- Click "Save"

---

### Paso 2: Crear Query 2 - Menciones por Sentimiento

1. **Nueva pregunta:** SQL query
2. **Copiar SQL:**

```sql
SELECT
  t.tag_name AS actor,
  COUNT(CASE WHEN m.sentiment = 'Positivo' THEN 1 END) AS positivas,
  COUNT(CASE WHEN m.sentiment = 'Negativo' THEN 1 END) AS negativas,
  COUNT(CASE WHEN m.sentiment = 'Neutral' THEN 1 END) AS neutrales,
  COUNT(*) AS total
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  [[AND {{fecha}}]]
  [[AND {{source_name}}]]
GROUP BY t.tag_name
ORDER BY total DESC;
```

3. **Configurar MISMAS 2 variables** que Query 1 (fecha y source_name)
4. **Configurar visualización:**

**Opción A - Tabla (Recomendado para ver todos los números):**
- Visualization: **Table**
- Settings:
  - Mostrar todas las columnas: actor, positivas, negativas, neutrales, total
  - Number format: "123,456" (con separador de miles)
  - Sort: Por columna "total" descendente

**Opción B - Gráfico de barras apiladas:**
- Visualization: **Stacked bar chart**
- Settings:
  - X-axis: actor
  - Y-axis: Stack positivas, negativas, neutrales
  - Show values: OFF (para que no esté saturado)
  - Colores:
    - positivas: #10b981 (verde)
    - negativas: #ef4444 (rojo)
    - neutrales: #9ca3af (gris)

5. **Guardar:**
- Nombre: "MVP - Menciones por Sentimiento"
- Colección: "MVP Dashboard"

---

### Paso 3: Crear Query 3 - Total Engagement

1. **Nueva pregunta:** SQL query
2. **Copiar SQL:**

```sql
SELECT
  t.tag_name AS actor,
  SUM(COALESCE(me.engagement, 0)) AS total_engagement
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
LEFT JOIN metrics me ON me.mention_id = m.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  [[AND {{fecha}}]]
  [[AND {{source_name}}]]
GROUP BY t.tag_name
ORDER BY total_engagement DESC;
```

3. **Configurar MISMAS 2 variables** que Query 1 (fecha y source_name)
4. **Configurar visualización:**
- Visualization: **Bar chart**
- Settings:
  - X-axis: total_engagement
  - Y-axis: actor
  - Display: Horizontal bars
  - Show values: ON
  - Number format: "123,456" (con separador de miles)

5. **Guardar:**
- Nombre: "MVP - Total Engagement por Actor"
- Colección: "MVP Dashboard"

---

### Paso 4: Crear Query 4 - Engagement por Sentimiento

1. **Nueva pregunta:** SQL query
2. **Copiar SQL:**

```sql
SELECT
  t.tag_name AS actor,
  SUM(CASE WHEN m.sentiment = 'Positivo' THEN COALESCE(me.engagement, 0) END) AS positivas,
  SUM(CASE WHEN m.sentiment = 'Negativo' THEN COALESCE(me.engagement, 0) END) AS negativas,
  SUM(CASE WHEN m.sentiment = 'Neutral' THEN COALESCE(me.engagement, 0) END) AS neutrales,
  SUM(COALESCE(me.engagement, 0)) AS total
FROM mention_occurrences o
JOIN mentions m ON m.mention_id = o.mention_id
LEFT JOIN metrics me ON me.mention_id = m.mention_id
JOIN mention_tags mt ON mt.mention_id = o.mention_id
JOIN tags t ON t.tag_id = mt.tag_id
WHERE t.tag_type = 'actor'
  [[AND {{fecha}}]]
  [[AND {{source_name}}]]
GROUP BY t.tag_name
ORDER BY total DESC;
```

3. **Configurar MISMAS 2 variables** que Query 1 (fecha y source_name)
4. **Configurar visualización:**

**Opción A - Tabla (Recomendado para ver todos los números):**
- Visualization: **Table**
- Settings:
  - Mostrar todas las columnas: actor, positivas, negativas, neutrales, total
  - Number format: "123,456" (con separador de miles)
  - Sort: Por columna "total" descendente

**Opción B - Gráfico de barras apiladas:**
- Visualization: **Stacked bar chart**
- Settings:
  - X-axis: actor
  - Y-axis: Stack positivas, negativas, neutrales
  - Number format: "123,456" (con separador de miles)
  - Colores:
    - positivas: #10b981 (verde)
    - negativas: #ef4444 (rojo)
    - neutrales: #9ca3af (gris)

5. **Guardar:**
- Nombre: "MVP - Engagement por Sentimiento"
- Colección: "MVP Dashboard"

---

### Paso 5: Crear Dashboard y Ensamblar

1. **Nuevo Dashboard:**
- Click "+ New" → Dashboard
- Nombre: "MVP - Dashboard General de Análisis Político"
- Colección: "MVP Dashboard"

2. **Agregar queries:**
- Click "Add a question"
- Buscar y agregar cada una de las 4 queries creadas

3. **Organizar layout:**

**Fila 1 - Filtros:**
- Agregar: "Add a filter" → Date
- Conectar a todas las queries (fecha_inicio, fecha_fin)
- Agregar: "Add a filter" → Dropdown
- Conectar a todas las queries (source_name)

**Fila 2 - Menciones:**
- Query 1 (izquierda, 50% ancho)
- Query 2 (derecha, 50% ancho)

**Fila 3 - Engagement:**
- Query 3 (izquierda, 50% ancho)
- Query 4 (derecha, 50% ancho)

4. **Ajustar tamaño:**
- Arrastrar esquinas de cada gráfica para ajustar
- Altura recomendada: 4-5 bloques

5. **Guardar dashboard**

---

## 📊 Datos de Validación

Con datos del periodo **2025-12-29 a 2026-01-04**:

### Query 1: Total Menciones
| Actor | Total |
|-------|-------|
| Andrea Chávez | 8,417 |
| Maru Campos | 5,186 |
| Ariadna Montiel | 4,468 |

### Query 2: Menciones por Sentimiento
| Actor | Positivas | Negativas | Neutrales | Total |
|-------|-----------|-----------|-----------|-------|
| Andrea Chávez | 1,580 | 1,688 | 5,149 | 8,417 |
| Maru Campos | 841 | 2,133 | 2,212 | 5,186 |
| Ariadna Montiel | 1,615 | 526 | 2,327 | 4,468 |
| Cruz Pérez Cuéllar | 1,272 | 359 | 1,676 | 3,307 |

### Query 3: Total Engagement
| Actor | Engagement |
|-------|------------|
| Andrea Chávez | 274,001 |
| Cruz Pérez Cuéllar | 67,555 |
| Ariadna Montiel | 59,033 |

### Query 4: Engagement por Sentimiento
| Actor | Positivas | Negativas | Neutrales | Total |
|-------|-----------|-----------|-----------|--------|
| Andrea Chávez | 77,979 | 72,248 | 123,774 | 274,001 |
| Cruz Pérez Cuéllar | 35,036 | 1,913 | 30,606 | 67,555 |
| Ariadna Montiel | 2,884 | 823 | 55,326 | 59,033 |
| Maru Campos | 2,456 | 5,178 | 50,640 | 58,274 |

---

## ✅ Checklist de Implementación

### Preparación (✅ COMPLETADO)
- [x] Query 1 creado y validado (formato: actor, total_menciones)
- [x] Query 2 creado y validado (formato columnas: actor, positivas, negativas, neutrales, total)
- [x] Query 3 creado y validado (formato: actor, total_engagement)
- [x] Query 4 creado y validado (formato columnas: actor, positivas, negativas, neutrales, total)
- [x] Todos los queries usan variables opcionales `[[AND {{fecha}}]]` y `[[AND {{source_name}}]]`
- [x] LEFT JOIN verificado en Queries 3 y 4
- [x] Todas las queries ejecutan sin errores
- [x] Datos de validación verificados con periodo 2025-12-29 a 2026-01-04

### Implementación en Metabase (✅ COMPLETADO)
- [x] Query 1 creada en Metabase con 2 variables (fecha, source_name)
- [x] Query 2 creada en Metabase con 2 variables (fecha, source_name)
- [x] Query 3 creada en Metabase con 2 variables (fecha, source_name)
- [x] Query 4 creada en Metabase con 2 variables (fecha, source_name)
- [x] Visualizaciones configuradas correctamente
- [x] Colores de sentimiento aplicados en Queries 2 y 4 (verde, rojo, gris)

### Dashboard (✅ COMPLETADO)
- [x] Dashboard creado en Metabase
- [x] 4 queries agregadas al dashboard
- [x] Filtros globales conectados (fecha, source_name)
- [x] Layout organizado (2 filas × 2 columnas)
- [x] Títulos de gráficas visibles
- [x] Dashboard guardado

### Validación Final (✅ COMPLETADO)
- [x] Filtro de fechas funciona en todas las gráficas
- [x] Filtro de source_name funciona en todas las gráficas
- [x] Números coinciden entre gráficas relacionadas (total Query 2 = total Query 1)
- [x] Números coinciden entre gráficas relacionadas (total Query 4 = total Query 3)
- [x] Colores de sentimiento son consistentes
- [x] Dashboard carga en < 3 segundos

**🎉 TODAS LAS TAREAS COMPLETADAS - MVP DASHBOARD EN PRODUCCIÓN**

---

## 🎨 Guía de Colores (para copiar/pegar)

```
Positivo:  #10b981  (verde esmeralda)
Negativo:  #ef4444  (rojo coral)
Neutral:   #9ca3af  (gris medio)
```

---

## 🚀 Tiempo Estimado

| Tarea | Tiempo |
|-------|--------|
| Crear Query 1 | 8 min |
| Crear Query 2 | 10 min |
| Crear Query 3 | 8 min |
| Crear Query 4 | 10 min |
| Crear Dashboard | 5 min |
| Ajustar layout y colores | 10 min |
| Pruebas y validación | 5 min |
| **TOTAL** | **45-60 minutos** |

---

## 🐛 Troubleshooting

### Problema: Variables no aparecen
**Solución:** Asegúrate de usar sintaxis `{{variable}}` con dobles llaves

### Problema: Error "column does not exist"
**Solución:** Verifica que estás conectado a la BD correcta (youscan)

### Problema: LEFT JOIN no funciona
**Solución:** Verifica que dice `LEFT JOIN metrics me` y no `JOIN metrics me`

### Problema: Colores no se aplican
**Solución:** Ve a Settings → Series settings → Selecciona cada sentimiento individualmente

### Problema: Filtros no funcionan
**Solución:** En dashboard settings, verifica que cada filtro está "mapped" a las variables de las queries

---

## 📸 Screenshots de Referencia

**Query 1 - Debe verse así:**
```
Andrea Chávez      ████████████████ 8,417
Maru Campos        ██████████ 5,186
Ariadna Montiel    █████████ 4,468
...
```

**Query 2 - Debe verse así:**
```
Andrea    [███Verde][██████Gris][███Rojo]
Maru      [██Verde][█████Gris][██Rojo]
...
```

---

## 🎯 Próximos Pasos Después del MVP

Una vez que el MVP esté funcionando, puedes agregar:

1. **Query 3: Balance Ponderado** (ya existe en SQL_QUERIES_METABASE.md)
2. **Query 4: Evolución Temporal** (gráfico de líneas)
3. **Query 5: Calidad de Datos** (tabla de auditoría)
4. **Queries 6-11: Índices Avanzados** (cuando estés listo)

Pero con estas 4 gráficas ya tienes un dashboard funcional y útil para entregar.

---

## 📞 Soporte

Si tienes algún problema durante la implementación, verifica:

1. PostgreSQL está corriendo: `docker ps | grep youscan-etl-db-1`
2. Metabase está corriendo: `docker ps | grep youscan-etl-metabase-1`
3. Puedes acceder a Metabase: http://localhost:3000
4. La conexión a la BD está configurada en Metabase

---

**¡Listo para implementar!** 🚀

Sigue los 5 pasos en orden y tendrás tu MVP Dashboard funcionando en menos de 1 hora.
