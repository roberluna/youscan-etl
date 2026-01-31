# ✅ Checklist Fase 5 - Actualización Metabase

**Fecha inicio:** 2026-01-07
**Estado:** En progreso
**Responsable:** _____________

---

## 🚀 Preparación

- [ ] Metabase está corriendo en http://localhost:3000
- [ ] Tengo acceso de administrador a Metabase
- [ ] Base de datos tiene los 4 índices nuevos aplicados
- [ ] Vista materializada `mv_mentions_by_actor_day` existe
- [ ] He leído [docs/FASE5_METABASE.md](FASE5_METABASE.md)

---

## 📊 Query 1: Menciones por actor

### Localización
- [ ] Query encontrada en Metabase
- [ ] ID de pregunta anotado: `___________`
- [ ] Nombre actual: `_______________________________`

### Respaldo
- [ ] Query duplicada con nombre: `_______________ (v1)`

### Actualización
- [ ] Abierta en modo edición
- [ ] SQL reemplazado con versión de [docs/CLAUDE.md](CLAUDE.md) líneas 236-255
- [ ] Variable `{{actor}}` configurada
- [ ] Variable `{{fecha}}` configurada
- [ ] Variable `{{source_system}}` configurada ✨ NUEVA
- [ ] Variable `{{source_type}}` configurada ✨ NUEVA

### Pruebas
- [ ] Ejecutada sin filtros → Funciona
- [ ] Probado filtro por actor → Funciona
- [ ] Probado filtro por fecha → Funciona
- [ ] Probado filtro por source_system → Funciona
- [ ] Probado filtro por source_type → Funciona
- [ ] Número de actores retornados: `_____`

### Guardar
- [ ] Guardada exitosamente
- [ ] Timestamp: `_____________`

---

## 💬 Query 2: Engagement por actor

### Localización
- [ ] Query encontrada en Metabase
- [ ] ID de pregunta anotado: `___________`
- [ ] Nombre actual: `_______________________________`

### Respaldo
- [ ] Query duplicada con nombre: `_______________ (v1)`

### Actualización
- [ ] Abierta en modo edición
- [ ] SQL reemplazado con versión de [docs/CLAUDE.md](CLAUDE.md) líneas 283-303
- [ ] ⚠️ **VERIFICADO:** `LEFT JOIN metrics` (no `JOIN metrics`) ✨ BUG CRÍTICO
- [ ] Variable `{{actor}}` configurada
- [ ] Variable `{{fecha}}` configurada
- [ ] Variable `{{source_system}}` configurada ✨ NUEVA
- [ ] Variable `{{source_type}}` configurada ✨ NUEVA

### Pruebas - Bug crítico corregido
- [ ] Query 1 retorna `_____` actores
- [ ] Query 2 (nueva) retorna `_____` actores
- [ ] ✅ **Ambos números coinciden** (antes NO coincidían)
- [ ] Verificado que actores con engagement=0 ahora aparecen
- [ ] Actor de prueba sin engagement: `_______________` → Aparece con 0

### Guardar
- [ ] Guardada exitosamente
- [ ] Timestamp: `_____________`

---

## ⚖️ Query 3: Balance ponderado

### Localización
- [ ] Query encontrada en Metabase
- [ ] ID de pregunta anotado: `___________`
- [ ] Nombre actual: `_______________________________`

### Respaldo
- [ ] Query duplicada con nombre: `_______________ (v1)`

### Actualización
- [ ] Abierta en modo edición
- [ ] SQL reemplazado con versión de [docs/CLAUDE.md](CLAUDE.md) líneas 345-386
- [ ] Variable `{{actor}}` configurada
- [ ] Variable `{{fecha}}` configurada
- [ ] Variable `{{source_system}}` configurada ✨ NUEVA
- [ ] Variable `{{source_type}}` configurada ✨ NUEVA

### Pruebas
- [ ] Ejecutada sin filtros → Funciona
- [ ] Rango de `balance_ponderado`: `___` a `___` (debe ser 0-100)
- [ ] Actores con solo neutrales aparecen al final con NULL
- [ ] Probados filtros de source_system y source_type → Funcionan

### Guardar
- [ ] Guardada exitosamente
- [ ] Timestamp: `_____________`

---

## 📈 Query 4: Evolución temporal (NUEVA)

### Creación
- [ ] Click en "Nueva pregunta" → "SQL nativo"
- [ ] Base de datos "youscan" seleccionada

### SQL
- [ ] SQL copiado de [docs/FASE5_METABASE.md](FASE5_METABASE.md) sección Query 4
- [ ] O de [docs/CLAUDE.md](CLAUDE.md) líneas 433-454
- [ ] Variable `{{actor}}` configurada
- [ ] Variable `{{fecha}}` configurada
- [ ] Variable `{{source_system}}` configurada
- [ ] Variable `{{source_type}}` configurada

### Visualización
- [ ] Tipo de gráfico configurado: `__________` (recomendado: Línea)
- [ ] Eje X: `fecha`
- [ ] Eje Y: `menciones_total`
- [ ] Series: `actor`
- [ ] Colores asignados por actor

### Pruebas
- [ ] Ejecutada sin filtros → Muestra evolución temporal
- [ ] Filtrar por un actor específico → Muestra solo su línea
- [ ] Filtrar por rango de fechas → Gráfico se actualiza
- [ ] Tendencias visibles: `_______________________________`

### Guardar
- [ ] Nombre: "Evolución temporal - Menciones por actor"
- [ ] Descripción agregada
- [ ] Colección asignada: `_______________`
- [ ] Guardada exitosamente
- [ ] ID de pregunta: `___________`

---

## 🔍 Query 5: Calidad de datos (NUEVA)

### Creación
- [ ] Click en "Nueva pregunta" → "SQL nativo"
- [ ] Base de datos "youscan" seleccionada

### SQL
- [ ] SQL copiado de [docs/FASE5_METABASE.md](FASE5_METABASE.md) sección Query 5
- [ ] O de [docs/CLAUDE.md](CLAUDE.md) líneas 549-598

### Visualización
- [ ] Tipo: Tabla
- [ ] Todas las columnas visibles
- [ ] Formato condicional configurado en `porcentaje_completitud`:
  - [ ] Verde: ≥ 95%
  - [ ] Amarillo: 85-95%
  - [ ] Rojo: < 85%

### Pruebas
- [ ] Ejecutada → Muestra métricas de calidad
- [ ] Menciones únicas: `___________`
- [ ] % Sin sentimiento: `_____` (debe ser ~0%)
- [ ] % Sin métricas: `_____` (debe ser ~0%)
- [ ] % Sin actor tags: `_____` (puede variar)

### Alertas (opcional)
- [ ] Alerta configurada si calidad < 90%
- [ ] Email de notificación: `_______________________`
- [ ] Frecuencia: Diaria

### Guardar
- [ ] Nombre: "Auditoría - Calidad de datos"
- [ ] Descripción agregada
- [ ] Colección asignada: `_______________`
- [ ] Guardada exitosamente
- [ ] ID de pregunta: `___________`

---

## 📊 Dashboard

### Creación
- [ ] Click en "Dashboards" → "Nuevo dashboard"
- [ ] Nombre: "Análisis Político Cuantitativo - v2"
- [ ] Descripción agregada

### Agregar visualizaciones
- [ ] Query 1 agregada (posición: superior)
- [ ] Query 2 agregada (posición: izquierda media)
- [ ] Query 3 agregada (posición: derecha media)
- [ ] Query 4 agregada (posición: centro - gráfico grande)
- [ ] Query 5 agregada (posición: inferior)

### Configurar filtros globales
- [ ] Filtro 1: "Actor político" (Field Filter → Tags.tag_name)
- [ ] Filtro 2: "Rango de fechas" (Field Filter → Mentions.published_at)
- [ ] Filtro 3: "Fuente" (Field Filter → Mentions.source_system)
- [ ] Filtro 4: "Tipo de contenido" (Field Filter → Mentions.source_type)

### Mapear variables por tarjeta
- [ ] Query 1: 4 variables mapeadas a filtros de dashboard
- [ ] Query 2: 4 variables mapeadas a filtros de dashboard
- [ ] Query 3: 4 variables mapeadas a filtros de dashboard
- [ ] Query 4: 4 variables mapeadas a filtros de dashboard

### Pruebas de dashboard
- [ ] Filtro "Actor político" afecta todas las queries
- [ ] Filtro "Rango de fechas" afecta todas las queries
- [ ] Filtro "Fuente" afecta todas las queries
- [ ] Filtro "Tipo de contenido" afecta todas las queries
- [ ] Todos los filtros funcionan en combinación

### Layout y diseño
- [ ] Tamaños de tarjetas ajustados
- [ ] Posiciones optimizadas para lectura
- [ ] Títulos claros y descriptivos
- [ ] Sin overlapping de elementos

### Guardar y compartir
- [ ] Dashboard guardado
- [ ] Permisos configurados para usuarios: `_______________`
- [ ] URL del dashboard: `___________________________________`

---

## 📝 Validación Final

### Comparación con queries antiguas
- [ ] Query 1 (nueva) vs Query 1 (antigua): Mismos actores + 2 variables nuevas ✅
- [ ] Query 2 (nueva) vs Query 2 (antigua): **Más actores** (bug corregido) ✅
- [ ] Query 3 (nueva) vs Query 3 (antigua): Mismos resultados + 2 variables nuevas ✅

### Performance
- [ ] Query 1 tiempo de ejecución: `_____` ms (debe ser <500ms con índices)
- [ ] Query 2 tiempo de ejecución: `_____` ms
- [ ] Query 3 tiempo de ejecución: `_____` ms
- [ ] Query 4 tiempo de ejecución: `_____` ms
- [ ] Query 5 tiempo de ejecución: `_____` ms

### Funcionalidad
- [ ] Todas las queries retornan datos
- [ ] No hay errores de SQL
- [ ] Variables funcionan correctamente
- [ ] Visualizaciones se renderizan correctamente
- [ ] Dashboard es funcional y usable

---

## 🎯 Documentación y Comunicación

### Documentación interna
- [ ] Screenshots del dashboard tomados
- [ ] Notas sobre cambios documentadas en: `_______________`
- [ ] Queries antiguas archivadas en colección "v1"

### Comunicación a usuarios
- [ ] Email/mensaje enviado notificando cambios
- [ ] Guía de uso del dashboard compartida
- [ ] Capacitación programada (si aplica): `_______________`
- [ ] Feedback inicial recopilado

---

## 📊 Métricas de Éxito

| Métrica | Antes | Después | ✅ |
|---------|-------|---------|-----|
| Queries en Metabase | 3 | 5 | [ ] |
| Bug de LEFT JOIN | ❌ Presente | ✅ Corregido | [ ] |
| Variables consistentes | ⚠️ Parcial | ✅ 4 en todas | [ ] |
| Dashboard actualizado | ❌ Antiguo | ✅ Nuevo v2 | [ ] |
| Auditoría de calidad | ❌ No existe | ✅ Query 5 | [ ] |

---

## 🎉 Completado

- [ ] **Todas las tareas marcadas ✅**
- [ ] **Dashboard funcional y validado**
- [ ] **Usuarios notificados**
- [ ] **Fase 5 completada exitosamente**

**Fecha de completado:** `_______________`
**Tiempo total invertido:** `_______________`
**Problemas encontrados:**
```
________________________________________
________________________________________
________________________________________
```

**Notas finales:**
```
________________________________________
________________________________________
________________________________________
```

---

_Checklist versión 1.0 - 2026-01-07_
