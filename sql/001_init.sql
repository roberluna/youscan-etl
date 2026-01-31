-- Single-schema model for social listening indicators (Youscan/Monito)

-- Drop tables (clean reset)
drop table if exists mention_occurrences cascade;
drop table if exists mention_tags cascade;
drop table if exists tags cascade;
drop table if exists metrics cascade;
drop table if exists mentions cascade;
drop table if exists qual_insights cascade;
drop table if exists ingestion_runs cascade;

create table if not exists ingestion_runs (
  run_id uuid primary key,
  source_system text not null,
  file_name text,
  file_hash text,
  status text not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  rows_in_file int,
  rows_mentions int,
  rows_tags int,
  error_message text
);

create table if not exists mentions (
  mention_id bigserial primary key,
  mention_key text not null unique,
  external_id text unique,
  source_system text not null,
  source_type text,
  source_name text,
  published_at timestamptz,
  title text,
  body_text text,
  url text,
  author text,
  author_nickname text,
  author_profile text,
  language text,
  country text,
  region text,
  city text,
  publication_place text,
  publication_profile text,
  publication_type text,
  content_type text,
  source_format text,
  resource_type text,
  notes text,
  assigned_to text,
  processed text,
  demographics text,
  age text,
  saved text,
  sentiment text,
  raw jsonb,
  first_run_id uuid,
  last_run_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ix_mentions_published_at
on mentions (published_at);

create table if not exists metrics (
  mention_id bigint primary key references mentions(mention_id) on delete cascade,
  reactions numeric,
  engagement numeric,
  likes numeric,
  love numeric,
  haha numeric,
  wow numeric,
  sad numeric,
  angry numeric,
  worried numeric,
  dislike numeric,
  comments numeric,
  reposts numeric,
  views numeric,
  impressions_own numeric,
  reach_own numeric,
  saves numeric,
  reach_potential numeric,
  rating numeric,
  publication_rating numeric,
  author_subscribers numeric,
  publication_subscribers numeric,
  updated_at timestamptz not null default now()
);

create table if not exists tags (
  tag_id bigserial primary key,
  tag_name text not null unique,
  tag_type text not null,
  created_at timestamptz not null default now()
);

create table if not exists mention_tags (
  mention_id bigint not null references mentions(mention_id) on delete cascade,
  tag_id bigint not null references tags(tag_id) on delete cascade,
  tag_sentiment text,
  primary key (mention_id, tag_id)
);

create index if not exists ix_mention_tags_tag_id
on mention_tags (tag_id);

create table if not exists mention_occurrences (
  occurrence_id bigserial primary key,
  mention_id bigint not null references mentions(mention_id) on delete cascade,
  run_id uuid not null,
  row_hash text not null,
  row_number int,
  created_at timestamptz not null default now()
);

create unique index if not exists ux_occurrence_run_rownum
on mention_occurrences (run_id, row_number);

create table if not exists qual_insights (
  insight_id bigserial primary key,
  actor_name text not null,
  period_start date not null,
  period_end date not null,
  insight_text text not null,
  mentions_count int,
  support_pct numeric,
  source_system text,
  created_at timestamptz not null default now()
);

-- ==============================================
-- ÍNDICES DE OPTIMIZACIÓN
-- ==============================================
-- Agregados para optimizar queries de análisis político
-- Fecha: 2026-01-07

-- Optimización para filtrado por tipo y nombre de tag
-- Beneficia: Queries 1, 2, 3 (filtro WHERE tag_type = 'actor')
create index if not exists ix_tags_type_name
on tags (tag_type, tag_name);

-- Optimización para filtros por fuente y fecha
-- Beneficia: Queries con filtros source_system, source_type, published_at
create index if not exists ix_mentions_source_published
on mentions (source_system, source_type, published_at);

-- Optimización para join con mention_occurrences
-- Beneficia: Todas las queries principales (join crítico)
create index if not exists ix_mention_occurrences_mention_id
on mention_occurrences (mention_id);

-- Índice compuesto para análisis de sentimiento por fecha
-- Beneficia: Queries que filtran por fecha Y sentimiento
create index if not exists ix_mentions_published_sentiment
on mentions (published_at, sentiment);

-- Nota: El índice ix_mentions_published_at ya existe (línea 64-65)
-- Nota: El índice ix_mention_tags_tag_id ya existe (línea 107-108)
