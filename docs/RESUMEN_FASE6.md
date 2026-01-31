# 📊 Resumen Ejecutivo - Fase 6: Sistema de Índices Avanzados

**Fecha:** 2026-01-07
**Estado:** Planificación completa ✅
**Documento técnico:** [FASE6_INDICES_AVANZADOS.md](FASE6_INDICES_AVANZADOS.md)

---

## 🎯 Objetivo

Expandir el sistema de análisis político con **6 nuevas queries** que complementen las 5 queries existentes, proporcionando:

1. **Índices compuestos** que combinen múltiples métricas
2. **Análisis temporal** para detectar tendencias y cambios
3. **Capacidad de pronóstico** para anticipar comportamientos futuros

---

## 📈 Queries Nuevas (6 en total)

### Grupo A: Índices Avanzados

| Query | Nombre | Fórmula | Qué mide |
|-------|--------|---------|----------|
| **Query 6** | Índice de Impacto Ponderado (IIP) | `balance_engagement × engagement_normalizado` | Resonancia digital real |
| **Query 7** | Índice de Eficiencia (IE) | `engagement_promedio × calidad_menciones` | ROI comunicacional |
| **Query 8** | Score Global (SG) | `BP(40%) + IIP(40%) + IE(20%)` | Ranking integral |

### Grupo B: Análisis Temporal

| Query | Nombre | Qué analiza |
|-------|--------|-------------|
| **Query 9** | Comparación vs. Periodo Anterior | Variaciones week-over-week o month-over-month |
| **Query 10** | Serie de Tiempo | Últimas 12 semanas con medias móviles y tendencias |
| **Query 11** | Proyección Simple | Pronóstico de la próxima semana |

---

## 🏗️ Infraestructura Requerida

### Nueva tabla: `indices_historico`

```sql
CREATE TABLE indices_historico (
  historico_id SERIAL PRIMARY KEY,
  actor TEXT NOT NULL,
  periodo_inicio DATE NOT NULL,
  periodo_fin DATE NOT NULL,
  tipo_periodo TEXT NOT NULL,  -- 'semanal' o 'mensual'

  -- Índices calculados
  balance_ponderado NUMERIC,
  indice_impacto_ponderado NUMERIC,
  indice_eficiencia NUMERIC,
  score_global NUMERIC,

  -- Metadata
  calculado_en TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(actor, periodo_inicio, periodo_fin, tipo_periodo)
);
```

**Propósito:** Almacenar histórico de índices para análisis temporal sin recalcular.

**Estimación de almacenamiento:** ~780 filas/año (15 actores × 52 semanas)

---

## 🔑 Conceptos Clave

### 1. Balance Ponderado (BP) - Query 3 existente

**¿Qué mide?** Percepción pública basada en volumen de menciones.

**Fórmula:**
```
BP = balance_sentimiento × factor_confianza
balance_sentimiento = menciones_positivas / menciones_polarizadas × 100
factor_confianza = menciones_polarizadas / max_menciones_polarizadas
```

**Resultado:** 0-100 (mayor = mejor percepción)

**Ejemplo:**
- Actor A: 500 menciones positivas, 200 negativas → BP = 71.4
- Actor B: 100 menciones positivas, 20 negativas → BP = 61.3

Actor A tiene mejor score porque tiene mayor volumen (más confianza estadística).

---

### 2. Índice de Impacto Ponderado (IIP) - Query 6 nueva

**¿Qué mide?** Resonancia digital basada en engagement real.

**Diferencia con BP:** Usa engagement en lugar de conteo de menciones.

**Fórmula:**
```
IIP = balance_engagement × factor_impacto
balance_engagement = engagement_positivo / engagement_polarizado × 100
factor_impacto = engagement_polarizado / max_engagement_polarizado
```

**Resultado:** 0-100 (mayor = mayor impacto digital)

**Ejemplo:**
- Actor A: 10,000 engagement positivo, 3,000 negativo → IIP = 76.9
- Actor B: 5,000 engagement positivo, 500 negativo → IIP = 69.4

Actor A tiene mejor score porque genera mayor engagement total.

---

### 3. Índice de Eficiencia (IE) - Query 7 nueva

**¿Qué mide?** Efectividad comunicacional (ROI de engagement).

**Fórmula:**
```
IE = eficiencia_bruta × factor_calidad
eficiencia_bruta = engagement_promedio (engagement_total / menciones_total)
factor_calidad = menciones_con_engagement / menciones_total
```

**Resultado:** 0-100 normalizado (mayor = comunicación más eficiente)

**Ejemplo:**
- Actor A: 1,000 menciones, 50,000 engagement → 50 engagement/mención → IE alto
- Actor B: 1,000 menciones, 5,000 engagement → 5 engagement/mención → IE bajo

Actor A es más eficiente: cada mención genera 10× más engagement.

---

### 4. Score Global (SG) - Query 8 nueva

**¿Qué mide?** Índice compuesto que combina percepción, impacto y eficiencia.

**Fórmula:**
```
SG = BP × 40% + IIP × 40% + IE × 20%
```

**Justificación de pesos:**
- **BP (40%):** Percepción pública es fundamental
- **IIP (40%):** Impacto digital es igualmente importante
- **IE (20%):** Eficiencia es deseable pero menos crítica

**Resultado:** 0-100 (mayor = mejor desempeño general)

**Ejemplo integrado:**
```
Actor A:
  BP  = 71.4 → 71.4 × 0.40 = 28.6
  IIP = 76.9 → 76.9 × 0.40 = 30.8
  IE  = 65.0 → 65.0 × 0.20 = 13.0
  -----------------------------------
  SG = 72.4

Actor B:
  BP  = 61.3 → 61.3 × 0.40 = 24.5
  IIP = 69.4 → 69.4 × 0.40 = 27.8
  IE  = 80.0 → 80.0 × 0.20 = 16.0
  -----------------------------------
  SG = 68.3
```

Actor A gana por mejor balance general, aunque Actor B es más eficiente.

---

## 📅 Análisis Temporal

### Query 9: Comparación histórica

**Objetivo:** Detectar cambios significativos entre periodos.

**Salida:**
```
Actor     | Score Actual | Score Anterior | Variación | % Cambio | Tendencia
----------|--------------|----------------|-----------|----------|------------------
Actor A   | 72.4         | 68.1          | +4.3      | +6.3%    | 📈 Mejora significativa
Actor B   | 68.3         | 69.5          | -1.2      | -1.7%    | ↘️ Deterioro
```

**Umbrales:**
- Variación > 5 puntos → Cambio significativo
- Variación > 0 y ≤ 5 → Mejora/Deterioro moderado
- Variación = 0 → Sin cambio

---

### Query 10: Series de tiempo

**Objetivo:** Identificar tendencias de largo plazo.

**Características:**
- Últimas 12 semanas de datos
- Media móvil de 4 semanas (suaviza fluctuaciones)
- Tendencia lineal (pendiente de regresión)
- Volatilidad (desviación estándar)

**Salida:**
```
Semana      | Score | Media Móvil 4sem | Tendencia | Volatilidad
------------|-------|------------------|-----------|-------------
2026-01-05  | 72.4  | 71.2            | ↗️ +0.5/sem | 2.3 (baja)
2025-12-29  | 70.8  | 70.5            | ↗️ +0.5/sem | 2.1 (baja)
```

**Interpretación:**
- Tendencia positiva (+0.5/semana) → Actor está mejorando consistentemente
- Volatilidad baja (2.3) → Comportamiento predecible

---

### Query 11: Proyección simple

**Objetivo:** Estimar score de la próxima semana.

**Método:** Media móvil ponderada + tendencia lineal

**Salida:**
```
Actor   | Score Actual | Proyección Próxima Semana | Confianza
--------|--------------|---------------------------|------------------
Actor A | 72.4         | 73.1                     | Alta (estable)
Actor B | 68.3         | 67.5                     | Media (tendencia moderada)
```

**Niveles de confianza:**
- Alta: Pendiente < 0.5 (comportamiento estable)
- Media: Pendiente entre 0.5 y 2.0
- Baja: Pendiente > 2.0 (alta volatilidad)

---

## 🚀 Plan de Implementación

### Fase 1: Índices base (Queries 6-7)
**Tiempo:** 4-6 horas
**Tareas:**
1. Crear Query 6 (IIP) en Metabase
2. Crear Query 7 (IE) en Metabase
3. Validar resultados vs. métricas conocidas
4. Documentar interpretación de resultados

---

### Fase 2: Score Global (Query 8)
**Tiempo:** 1-2 horas
**Tareas:**
1. Crear Query 8 (SG) que combine BP + IIP + IE
2. Validar fórmula de pesos (40% + 40% + 20%)
3. Crear visualización de ranking

---

### Fase 3: Infraestructura temporal
**Tiempo:** 2-3 horas
**Tareas:**
1. Crear tabla `indices_historico`
2. Crear índices en BD
3. Implementar proceso de cálculo semanal (ETL o vista materializada)

---

### Fase 4: Queries temporales (Queries 9-11)
**Tiempo:** 2-3 horas
**Tareas:**
1. Crear Query 9 (comparación)
2. Crear Query 10 (series de tiempo)
3. Crear Query 11 (proyección)
4. Validar cálculos de tendencias

---

### Fase 5: Dashboard y documentación
**Tiempo:** 2-3 horas
**Tareas:**
1. Crear dashboard "Índices Avanzados v2"
2. Configurar filtros temporales (semanal/mensual)
3. Documentar uso e interpretación
4. Capacitar usuarios

---

## 📊 Dashboard Propuesto

```
┌─────────────────────────────────────────────────────────────────┐
│  🏆 ANÁLISIS POLÍTICO - ÍNDICES AVANZADOS v2                    │
├─────────────────────────────────────────────────────────────────┤
│  Filtros: [Actor ▼] [Periodo: Semanal ▼] [Fecha ▼]            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  📊 RANKING SCORE GLOBAL (Query 8)                              │
│  ┌──────────┬────┬─────┬────┬──────┬──────────┐                │
│  │ Actor    │ BP │ IIP │ IE │  SG  │ Posición │                │
│  ├──────────┼────┼─────┼────┼──────┼──────────┤                │
│  │ Actor A  │ 71 │ 77  │ 65 │ 72.4 │    1     │                │
│  │ Actor B  │ 61 │ 69  │ 80 │ 68.3 │    2     │                │
│  └──────────┴────┴─────┴────┴──────┴──────────┘                │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  📈 EVOLUCIÓN TEMPORAL (Query 10)                               │
│      80 ┤              ╱─╲                                      │
│      75 ┤           ╱─╯   ╲                                     │
│      70 ┤        ╱─╯       ╲─╮                                  │
│      65 ┤     ╱─╯             ╲                                 │
│      60 ┼─────────────────────────────────► semanas            │
│           -12  -10   -8   -6   -4   -2    0                    │
│                                                                  │
├──────────────────────┬──────────────────────────────────────────┤
│                      │                                           │
│  🔄 CAMBIO SEMANAL   │  🔮 PROYECCIÓN                           │
│  (Query 9)           │  (Query 11)                              │
│                      │                                           │
│  Actor A: +4.3 📈    │  Próxima semana: 73.1                   │
│  Actor B: -1.2 ↘️     │  Confianza: Alta                        │
│                      │                                           │
└──────────────────────┴──────────────────────────────────────────┘
```

---

## 🎯 Casos de Uso

### Caso 1: Identificar mejores comunicadores
**Query:** Query 7 (Índice de Eficiencia)
**Pregunta:** ¿Quién genera más engagement con menos menciones?
**Acción:** Aprender de las estrategias de comunicación de actores eficientes

---

### Caso 2: Detectar crisis de reputación
**Query:** Query 9 (Comparación histórica)
**Pregunta:** ¿Hubo caídas significativas en el score esta semana?
**Acción:** Investigar qué evento causó la caída y planear respuesta

---

### Caso 3: Planear campañas
**Query:** Query 11 (Proyección)
**Pregunta:** ¿Qué actores están en tendencia ascendente?
**Acción:** Aprovechar momentum con contenido adicional

---

### Caso 4: Ranking integral
**Query:** Query 8 (Score Global)
**Pregunta:** ¿Quién tiene el mejor desempeño general considerando todas las métricas?
**Acción:** Benchmark para otros actores

---

## 🔮 Próximos Pasos Opcionales (Post-Fase 6)

### 1. Pronósticos avanzados con Prophet

Integrar Facebook Prophet para pronósticos más precisos que consideren:
- Estacionalidad (días de semana, eventos políticos)
- Tendencias no lineales
- Intervalos de confianza

**Ejemplo de código Python:**
```python
from fbprophet import Prophet

def pronosticar_actor(actor, semanas_futuras=4):
    df = pd.read_sql(f"""
        SELECT periodo_inicio as ds, score_global as y
        FROM indices_historico
        WHERE actor = '{actor}' AND tipo_periodo = 'semanal'
        ORDER BY periodo_inicio
    """, conn)

    model = Prophet(weekly_seasonality=True)
    model.fit(df)

    future = model.make_future_dataframe(periods=semanas_futuras, freq='W')
    forecast = model.predict(future)

    return forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']]
```

---

### 2. Alertas automáticas

Configurar notificaciones cuando:
- Score cae > 10 puntos en una semana
- Volatilidad aumenta significativamente
- Proyección indica deterioro continuo

---

### 3. Análisis de correlaciones

Investigar qué factores impulsan los índices:
- ¿Qué tipo de contenido genera más engagement?
- ¿Qué fuentes (Facebook vs. Twitter) son más efectivas?
- ¿Qué días/horas tienen mejor engagement?

---

## 📚 Documentación Relacionada

| Documento | Propósito |
|-----------|-----------|
| [FASE6_INDICES_AVANZADOS.md](FASE6_INDICES_AVANZADOS.md) | 📘 Plan técnico completo (55 KB) |
| [FASE5_METABASE.md](FASE5_METABASE.md) | 📋 Guía para Fase 5 (pre-requisito) |
| [CLAUDE.md](CLAUDE.md) | 📘 Documentación técnica sistema completo |
| [SQL_QUERIES_METABASE.md](SQL_QUERIES_METABASE.md) | 📋 Queries 1-5 existentes |

---

## ✅ Checklist Pre-Implementación

Antes de comenzar Fase 6, verificar:

- [ ] Fase 5 completada (Queries 1-5 funcionando en Metabase)
- [ ] Base de datos PostgreSQL 16 disponible
- [ ] Acceso a Metabase con permisos de administrador
- [ ] ETL ejecutándose correctamente
- [ ] Al menos 12 semanas de datos históricos (ideal para análisis temporal)
- [ ] Documentación de [FASE6_INDICES_AVANZADOS.md](FASE6_INDICES_AVANZADOS.md) revisada

---

## 📞 Soporte

**Preguntas frecuentes:**

**P: ¿Puedo implementar solo las Queries 6-8 sin las temporales (9-11)?**
R: Sí, las fases son independientes. Puedes implementar Queries 6-8 primero.

**P: ¿Necesito Prophet para las proyecciones?**
R: No. Query 11 usa SQL nativo. Prophet es opcional para pronósticos más avanzados.

**P: ¿Cuánto espacio en disco requiere `indices_historico`?**
R: ~780 filas/año para 15 actores. Insignificante (<1 MB/año).

**P: ¿Debo calcular índices diariamente?**
R: Recomendado semanal. Diario es posible pero genera más datos sin mucho valor adicional.

---

**Última actualización:** 2026-01-07
**Versión:** 1.0
**Estado:** Listo para implementación
**Proyecto:** YouScan ETL - Análisis Político Cuantitativo
