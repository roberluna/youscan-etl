-- =====================================================
-- Tabla: indices_historico
-- Propósito: Almacenar histórico de índices calculados
--            para análisis temporal y proyecciones
-- Fecha: 2026-01-08
-- =====================================================

-- Crear tabla si no existe
CREATE TABLE IF NOT EXISTS indices_historico (
  historico_id SERIAL PRIMARY KEY,

  -- Identificadores
  actor TEXT NOT NULL,
  periodo_inicio DATE NOT NULL,
  periodo_fin DATE NOT NULL,
  tipo_periodo TEXT NOT NULL CHECK (tipo_periodo IN ('semanal', 'mensual', 'diario')),

  -- Métricas base
  menciones_total INTEGER,
  menciones_positivas INTEGER,
  menciones_negativas INTEGER,
  menciones_neutrales INTEGER,
  engagement_total NUMERIC(15, 2),
  engagement_positivo NUMERIC(15, 2),
  engagement_negativo NUMERIC(15, 2),

  -- Índices calculados (0-100)
  balance_ponderado NUMERIC(5, 1),
  indice_impacto_ponderado NUMERIC(5, 1),
  indice_eficiencia NUMERIC(5, 1),
  score_global NUMERIC(5, 1),

  -- Metadata
  calculado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fuente_sistema TEXT DEFAULT 'metabase',

  -- Constraint: Un solo registro por actor/periodo
  UNIQUE(actor, periodo_inicio, periodo_fin, tipo_periodo)
);

-- Comentarios descriptivos
COMMENT ON TABLE indices_historico IS 'Almacena histórico de índices calculados para análisis temporal y proyecciones';
COMMENT ON COLUMN indices_historico.actor IS 'Nombre del actor político (ej: "Claudia Sheinbaum")';
COMMENT ON COLUMN indices_historico.tipo_periodo IS 'Tipo de agregación temporal: diario, semanal, mensual';
COMMENT ON COLUMN indices_historico.balance_ponderado IS 'Query 3: Balance Ponderado (0-100)';
COMMENT ON COLUMN indices_historico.indice_impacto_ponderado IS 'Query 6: Índice de Impacto Ponderado (0-100)';
COMMENT ON COLUMN indices_historico.indice_eficiencia IS 'Query 7: Índice de Eficiencia (0-100)';
COMMENT ON COLUMN indices_historico.score_global IS 'Query 8: Score Global = BP(40%) + IIP(40%) + IE(20%)';

-- Índices para optimizar queries
CREATE INDEX IF NOT EXISTS ix_historico_actor_periodo
ON indices_historico (actor, tipo_periodo, periodo_inicio DESC);

CREATE INDEX IF NOT EXISTS ix_historico_periodo_tipo
ON indices_historico (tipo_periodo, periodo_inicio DESC);

CREATE INDEX IF NOT EXISTS ix_historico_actor
ON indices_historico (actor);

-- Verificar creación
SELECT
  'Tabla indices_historico creada exitosamente' AS status,
  COUNT(*) AS registros_existentes
FROM indices_historico;
