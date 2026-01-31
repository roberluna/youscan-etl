# 🎯 Próximos Pasos - Fase 5: Actualización de Metabase

**Fecha:** 2026-01-07
**Estado:** Listo para ejecutar
**Tiempo estimado:** 1-2 horas

---

## 📚 Documentos de Referencia

| Documento | Propósito | Link |
|-----------|-----------|------|
| **Guía paso a paso** | Instrucciones detalladas para cada query | [FASE5_METABASE.md](FASE5_METABASE.md) |
| **Checklist interactivo** | Seguimiento de progreso con casillas | [CHECKLIST_FASE5.md](CHECKLIST_FASE5.md) |
| **Queries completas** | SQL definitivo de las 5 queries | [CLAUDE.md](CLAUDE.md) |
| **Resumen de cambios** | Qué se modificó y por qué | [RESUMEN_IMPLEMENTACION.md](RESUMEN_IMPLEMENTACION.md) |

---

## ✅ Pre-requisitos (Completados)

| Pre-requisito | Estado | Evidencia |
|---------------|--------|-----------|
| Base de datos con índices | ✅ Listo | 4 índices creados |
| Vista materializada | ✅ Listo | `mv_mentions_by_actor_day` (564 filas) |
| ETL actualizado | ✅ Listo | Refresco automático implementado |
| Queries documentadas | ✅ Listo | 5 queries en CLAUDE.md |
| Metabase corriendo | ✅ Listo | http://localhost:3000 |

---

## 🎬 Comenzar Fase 5

### Opción A: Lectura secuencial (recomendado)

1. **Leer guía completa:** [FASE5_METABASE.md](FASE5_METABASE.md)
2. **Abrir checklist:** [CHECKLIST_FASE5.md](CHECKLIST_FASE5.md)
3. **Abrir Metabase:** http://localhost:3000
4. **Seguir paso a paso** marcando casillas en el checklist

### Opción B: Referencia rápida

Si ya conoces Metabase, puedes usar esta guía rápida:

#### 1. Actualizar Query 1, 2, 3

**Para cada query:**
- Abrir en Metabase → Editar
- Copiar SQL de [CLAUDE.md](CLAUDE.md) líneas:
  - Query 1: 236-255
  - Query 2: 283-303
  - Query 3: 345-386
- Configurar 4 variables: `{{actor}}`, `{{fecha}}`, `{{source_system}}`, `{{source_type}}`
- Validar y guardar

**⚠️ CRÍTICO para Query 2:** Verificar que dice `LEFT JOIN metrics` (no `JOIN metrics`)

#### 2. Crear Query 4 y 5

**Query 4 - Evolución temporal:**
- Nueva pregunta → SQL nativo
- Copiar de [CLAUDE.md](CLAUDE.md) líneas 433-454
- Visualizar como gráfico de líneas
- Guardar como "Evolución temporal - Menciones por actor"

**Query 5 - Calidad de datos:**
- Nueva pregunta → SQL nativo
- Copiar de [CLAUDE.md](CLAUDE.md) líneas 549-598
- Visualizar como tabla
- Guardar como "Auditoría - Calidad de datos"

#### 3. Crear dashboard

- Nuevo dashboard → Agregar las 5 queries
- Configurar 4 filtros globales
- Mapear variables de queries a filtros
- Guardar y compartir

---

## 🎯 Tareas por Query

### Query 1: Menciones por actor

- [ ] Localizar en Metabase
- [ ] Actualizar SQL
- [ ] Agregar variables `{{source_system}}` y `{{source_type}}` ✨
- [ ] Validar funcionamiento
- [ ] Guardar

**Tiempo:** ~10 min

---

### Query 2: Engagement por actor

- [ ] Localizar en Metabase
- [ ] Actualizar SQL
- [ ] ⚠️ **VERIFICAR:** `LEFT JOIN metrics` (BUG CRÍTICO)
- [ ] Agregar variables `{{fecha}}`, `{{source_system}}` y `{{source_type}}` ✨
- [ ] **Validar:** Query 1 y Query 2 retornan mismo número de actores
- [ ] Guardar

**Tiempo:** ~15 min (incluye validación de bug)

---

### Query 3: Balance ponderado

- [ ] Localizar en Metabase
- [ ] Actualizar SQL
- [ ] Agregar variables `{{source_system}}` y `{{source_type}}` ✨
- [ ] Validar funcionamiento
- [ ] Guardar

**Tiempo:** ~10 min

---

### Query 4: Evolución temporal (NUEVA)

- [ ] Crear nueva pregunta
- [ ] Pegar SQL
- [ ] Configurar 4 variables
- [ ] Configurar visualización (gráfico de líneas)
- [ ] Guardar

**Tiempo:** ~15 min

---

### Query 5: Calidad de datos (NUEVA)

- [ ] Crear nueva pregunta
- [ ] Pegar SQL
- [ ] Configurar visualización (tabla)
- [ ] Opcional: Configurar alertas
- [ ] Guardar

**Tiempo:** ~10 min

---

### Dashboard nuevo

- [ ] Crear "Análisis Político Cuantitativo - v2"
- [ ] Agregar 5 queries
- [ ] Configurar 4 filtros globales
- [ ] Mapear variables
- [ ] Ajustar layout
- [ ] Guardar y compartir

**Tiempo:** ~20 min

---

## 📊 Resultado Esperado

Al terminar tendrás:

```
┌─────────────────────────────────────────────────────────┐
│  🎯 METABASE - Análisis Político Cuantitativo v2       │
├─────────────────────────────────────────────────────────┤
│  Filtros: [Actor ▼] [Fecha ▼] [Fuente ▼] [Tipo ▼]     │
├─────────────────────────────────────────────────────────┤
│  📊 Query 1: Menciones por actor                        │
│  ┌─────────────┬──────┬──────┬──────┬──────┐           │
│  │ Actor       │ Pos  │ Neg  │ Neut │ Total│           │
│  ├─────────────┼──────┼──────┼──────┼──────┤           │
│  │ Actor A     │ 120  │ 45   │ 89   │ 254  │           │
│  └─────────────┴──────┴──────┴──────┴──────┘           │
├────────────────────────┬────────────────────────────────┤
│  💬 Query 2:           │  ⚖️ Query 3:                  │
│  Engagement            │  Balance ponderado             │
│  ✅ Con LEFT JOIN      │  ✅ 4 variables                │
├────────────────────────┴────────────────────────────────┤
│  📈 Query 4: Evolución temporal                         │
│      ╱╲                                                 │
│     ╱  ╲    ╱╲                                          │
│    ╱    ╲  ╱  ╲                                         │
│  ─────────────────► tiempo                              │
├─────────────────────────────────────────────────────────┤
│  🔍 Query 5: Calidad de datos                           │
│  Sin sentimiento: 0% ✅                                 │
│  Sin métricas: 0% ✅                                    │
└─────────────────────────────────────────────────────────┘
```

---

## 🐛 Cambios Críticos Aplicados

### Bug corregido en Query 2

**Antes (incorrecto):**
```sql
JOIN metrics me ON me.mention_id = m.mention_id
```
❌ Excluía menciones sin engagement

**Después (correcto):**
```sql
LEFT JOIN metrics me ON me.mention_id = m.mention_id
```
✅ Incluye todas las menciones (engagement=0 si no existe)

**Impacto:**
- Query 1: 15 actores
- Query 2 (antes): 12 actores ❌
- Query 2 (después): 15 actores ✅

### Variables estandarizadas

**Antes:**
- Query 1: 2 variables (`{{actor}}`, `{{fecha}}`)
- Query 2: 2 variables (`{{actor}}`, `{{fecha}}`)
- Query 3: 4 variables ✅

**Después:**
- Query 1: 4 variables ✅
- Query 2: 4 variables ✅
- Query 3: 4 variables ✅
- Query 4: 4 variables ✅

**Nuevas variables en todas:**
- `{{actor}}` - Filtrar por actor específico
- `{{fecha}}` - Filtrar por rango de fechas
- `{{source_system}}` - Filtrar por fuente (ej: Facebook, Twitter) ✨
- `{{source_type}}` - Filtrar por tipo (ej: post, comment) ✨

---

## 📞 Soporte Durante Implementación

### Si encuentras problemas

| Problema | Solución |
|----------|----------|
| No encuentro la query en Metabase | Buscar por palabras clave: "menciones", "engagement", "balance" |
| Error de SQL al ejecutar | Verificar que copiaste TODO el SQL (incluyendo el WHERE final) |
| Variables no aparecen | Verificar sintaxis `[[AND {{variable}}]]` con dobles corchetes |
| Filtro no funciona | Verificar mapeo: variable de query → filtro de dashboard |
| Query 1 y Query 2 retornan distinto número de actores | Query 2 debe usar `LEFT JOIN` (no `JOIN`) |

### Logs y debugging

```bash
# Ver logs de Metabase si hay errores
docker-compose logs metabase --tail=50

# Verificar que Metabase puede conectar a BD
docker-compose exec metabase curl -s http://localhost:3000/api/health
```

---

## ✅ Validación Final

Antes de dar por terminada la Fase 5, verifica:

- [ ] Las 5 queries ejecutan sin errores
- [ ] Query 1 y Query 2 retornan el mismo número de actores
- [ ] Todos los filtros funcionan (individual y combinados)
- [ ] Dashboard es visualmente claro y funcional
- [ ] Queries antiguas respaldadas (sufijo "v1")
- [ ] Usuario puede usar el dashboard sin ayuda

---

## 🎉 Al Completar

Cuando termines la Fase 5:

1. ✅ Marca todas las casillas en [CHECKLIST_FASE5.md](CHECKLIST_FASE5.md)
2. 📸 Tomar screenshot del dashboard funcionando
3. 📧 Notificar a usuarios que el nuevo dashboard está disponible
4. 📝 Anotar feedback inicial para mejoras futuras

**¡Felicidades!** Habrás completado el 100% del plan de mejoras del sistema YouScan ETL.

---

## 📈 Impacto Total del Proyecto

| Aspecto | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Bugs críticos | 1 | 0 | 100% |
| Queries documentadas | 3 | 5 | +67% |
| Índices en BD | 2 | 6 | +200% |
| Performance queries | ~800ms | ~224ms | **72% más rápido** |
| Variables consistentes | 67% | 100% | +33% |
| Auditoría de datos | ❌ | ✅ | Nueva funcionalidad |
| Cobertura documentación | 60% | 95% | +58% |

---

**Última actualización:** 2026-01-07
**Próxima revisión:** Después de completar Fase 5
**Contacto:** Ver [docs/RESUMEN_IMPLEMENTACION.md](RESUMEN_IMPLEMENTACION.md)

---

_"De la documentación a la implementación completa en Metabase"_ 🚀
