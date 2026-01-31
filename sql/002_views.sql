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
