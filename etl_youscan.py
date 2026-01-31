import os
import re
import json
import uuid
import hashlib
from datetime import datetime
from typing import Tuple, List, Dict

import pandas as pd
import psycopg2
from psycopg2.extras import execute_values
from dateutil import parser as dateparser


# =========================
# CONFIG
# =========================

EXCEL_PATH = "data/youscan-19-25-enero-2026.xlsx"
SOURCE_SYSTEM = "youscan"
SOURCE_TYPE_DEFAULT = "social"

DB_HOST = os.getenv("PGHOST", "localhost")
DB_PORT = int(os.getenv("PGPORT", "5433"))
DB_NAME = os.getenv("PGDATABASE", "youscan")
DB_USER = os.getenv("PGUSER", "youscan_admin")
DB_PASS = os.getenv("PGPASSWORD", "youscan_pass")

# Overrides manuales (por si quieres forzar clasificación)
FORCE_ACTOR = set([
    # "Marco Bonilla",
])
FORCE_TOPIC = set([
    # "Seguridad",
])

# Heurística de "temas"
TOPIC_KEYWORDS = [
    "seguridad", "econom", "corrup", "salud", "educ", "agua", "violencia",
    "obra", "infra", "transporte", "empleo", "impuesto", "presupuesto",
    "narco", "crimen", "polic", "fiscal", "derecho", "justicia",
    "menciones", "relevantes", "portales", "categoria", "categorias",
]
QUERY_KEYWORDS = [
    "query", "menciones", "relevantes", "eleccion", "elección", "campana", "campaña"
]

LIST_FIELDS = {
    "Etiquetas": "category",
}

# Si es False, solo usa el campo Etiquetas y evita tags derivados de columnas-flag.
USE_FLAG_COLUMNS = False


# =========================
# HELPERS
# =========================

def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def norm_str(s: object) -> str:
    if s is None:
        return ""
    s = str(s).strip()
    s = re.sub(r"\s+", " ", s)
    return s

def norm_cmp(s: object) -> str:
    return norm_str(s).lower()

def pick_column(df: pd.DataFrame, candidates: List[str]) -> str:
    cols = list(df.columns)
    cols_l = [c.lower().strip() for c in cols]
    for cand in candidates:
        cand_l = cand.lower().strip()
        for i, c in enumerate(cols_l):
            if cand_l == c:
                return cols[i]
    for cand in candidates:
        cand_l = cand.lower().strip()
        for i, c in enumerate(cols_l):
            if cand_l in c:
                return cols[i]
    return ""

def parse_event_ts(row: pd.Series, date_col: str, time_col: str) -> datetime | None:
    d = row.get(date_col, None) if date_col else None
    t = row.get(time_col, None) if time_col else None

    if pd.isna(d) and pd.isna(t):
        return None

    if isinstance(d, (datetime, pd.Timestamp)) and (pd.isna(t) or t is None):
        return pd.to_datetime(d).to_pydatetime()

    try:
        d_str = "" if pd.isna(d) else str(d)
        t_str = "" if pd.isna(t) else str(t)
        combined = (d_str + " " + t_str).strip()
        if not combined:
            return None
        return dateparser.parse(combined, dayfirst=True, fuzzy=True)
    except Exception:
        return None

def compute_mention_key(
    source_system: str,
    source_name: str,
    published_at: datetime | None,
    title: str,
    url: str,
    body_text: str,
    author: str,
) -> str:
    ts = published_at.isoformat() if published_at else ""
    base = "|".join([
        norm_str(source_system),
        norm_str(source_name),
        norm_str(ts),
        norm_str(title),
        norm_str(url),
        norm_str(body_text),
        norm_str(author),
    ])
    return hashlib.sha256(base.encode("utf-8")).hexdigest()

def compute_row_hash(raw_dict: Dict[str, object]) -> str:
    payload = json.dumps(raw_dict, ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()

def is_flag_column(series: pd.Series, colname: str) -> bool:
    s = series.dropna()
    if len(s) == 0:
        return False

    col_cmp = norm_cmp(colname)

    if len(s) > 5000:
        s = s.sample(5000, random_state=7)

    vals = s.astype(str).map(norm_cmp)
    match_ratio = (vals == col_cmp).mean()
    return match_ratio >= 0.80

def classify_flag_name(name: str) -> str:
    if name in FORCE_ACTOR:
        return "actor"
    if name in FORCE_TOPIC:
        return "topic"

    nl = norm_cmp(name)
    if any(k in nl for k in QUERY_KEYWORDS):
        return "topic"
    if any(k in nl for k in TOPIC_KEYWORDS):
        return "topic"

    parts = [p for p in re.split(r"\s+", norm_str(name)) if p]
    if 2 <= len(parts) <= 4:
        cap = sum(1 for p in parts if p[:1].isupper())
        if cap >= 2:
            return "actor"

    return "actor"

def split_list_field(value: object) -> List[str]:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return []
    text = str(value).strip()
    if not text:
        return []
    parts = [norm_str(p) for p in re.split(r"[;,|]+", text)]
    return [p for p in parts if p]

def is_probable_tag(value: str) -> bool:
    """
    Heuristica simple para evitar frases largas en campos de etiquetas.
    """
    v = norm_str(value)
    if not v:
        return False
    # evita oraciones largas / textos completos
    if len(v) > 60:
        return False
    if v.count(" ") > 6:
        return False
    return True

def to_numeric(value: object) -> float | None:
    try:
        if value is None or (isinstance(value, float) and pd.isna(value)):
            return None
        s = re.sub(r"[^0-9\.-]", "", str(value))
        if s == "" or s == "-" or s == ".":
            return None
        return float(s)
    except Exception:
        return None

def connect():
    return psycopg2.connect(
        host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASS
    )


def main():
    if not os.path.exists(EXCEL_PATH):
        raise FileNotFoundError(f"No encuentro el archivo: {EXCEL_PATH}")

    file_hash = sha256_file(EXCEL_PATH)
    file_name = os.path.basename(EXCEL_PATH)
    run_id = str(uuid.uuid4())

    conn = connect()
    conn.autocommit = False

    counts = {
        "rows_in_file": 0,
        "rows_mentions": 0,
        "rows_tags": 0,
    }

    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into ingestion_runs (run_id, source_system, file_name, file_hash, status)
                values (%s, %s, %s, %s, %s)
                """,
                (run_id, SOURCE_SYSTEM, file_name, file_hash, "started"),
            )
        conn.commit()

        df = pd.read_excel(EXCEL_PATH)
        counts["rows_in_file"] = len(df)

        date_col = pick_column(df, ["Fecha", "Date", "fecha"])
        time_col = pick_column(df, ["Hora", "Time", "hora"])
        title_col = pick_column(df, ["Título", "Titulo", "Title", "titulo", "title"])
        text_col = pick_column(df, ["Texto", "text", "texto"])
        url_col = pick_column(df, ["URL", "Url", "Link", "link", "url"])
        sentiment_col = pick_column(df, ["Sentimiento", "sentimiento", "Sentiment"])

        base_cols = {c for c in [date_col, time_col, title_col, text_col, url_col, sentiment_col] if c}

        flag_cols = []
        if USE_FLAG_COLUMNS:
            for col in df.columns:
                if col in base_cols:
                    continue
                ser = df[col]
                non_null = ser.dropna()
                if len(non_null) == 0:
                    continue
                try:
                    numeric = pd.to_numeric(non_null, errors="coerce")
                    numeric_ratio = numeric.notna().mean()
                    if numeric_ratio >= 0.80:
                        continue
                except Exception:
                    pass
                if is_flag_column(ser, col):
                    flag_cols.append(col)

        mention_by_key: Dict[str, tuple] = {}
        metrics_by_key: Dict[str, tuple] = {}
        tags_by_key: Dict[str, set] = {}
        sentiments_by_key: Dict[str, str | None] = {}
        all_tags: Dict[str, str] = {}
        row_hashes_by_key: Dict[str, List[str]] = {}

        for row_idx, row in df.iterrows():
            published_at = parse_event_ts(row, date_col, time_col)
            title = norm_str(row.get(title_col, "")) if title_col else ""
            body_text = norm_str(row.get(text_col, "")) if text_col else ""
            url = norm_str(row.get(url_col, "")) if url_col else ""
            sentiment = norm_str(row.get(sentiment_col, "")) if sentiment_col else ""

            author = norm_str(row.get("Autor", ""))
            author_nickname = norm_str(row.get("Apodo", ""))
            author_profile = norm_str(row.get("Perfil", ""))
            source_name = norm_str(row.get("Fuente", "")) or norm_str(row.get("Lugar de publicación", ""))
            source_type = norm_str(row.get("Tipo de recurso", "")) or SOURCE_TYPE_DEFAULT

            mention_key = compute_mention_key(
                SOURCE_SYSTEM, source_name, published_at, title, url, body_text, author
            )

            raw_dict = {}
            for c in df.columns:
                v = row.get(c, None)
                if pd.isna(v):
                    raw_dict[c] = None
                elif isinstance(v, (pd.Timestamp, datetime)):
                    raw_dict[c] = str(pd.to_datetime(v))
                else:
                    raw_dict[c] = str(v)

            mention_by_key[mention_key] = (
                mention_key,
                None,  # external_id
                SOURCE_SYSTEM,
                source_type,
                source_name,
                published_at,
                title or None,
                body_text or None,
                url or None,
                author or None,
                author_nickname or None,
                author_profile or None,
                norm_str(row.get("Idioma", "")) or None,
                norm_str(row.get("País", "")) or None,
                norm_str(row.get("Región", "")) or None,
                norm_str(row.get("Ciudad", "")) or None,
                norm_str(row.get("Lugar de publicación", "")) or None,
                norm_str(row.get("Perfil del lugar de publicación", "")) or None,
                norm_str(row.get("Tipo de publicación", "")) or None,
                norm_str(row.get("Tipos de contenido", "")) or None,
                norm_str(row.get("Formato específico de la fuente", "")) or None,
                norm_str(row.get("Tipo de recurso", "")) or None,
                norm_str(row.get("Notas", "")) or None,
                norm_str(row.get("Asignado a", "")) or None,
                norm_str(row.get("Procesado", "")) or None,
                norm_str(row.get("Datos demográficos", "")) or None,
                norm_str(row.get("Edad", "")) or None,
                norm_str(row.get("Guardado", "")) or None,
                sentiment or None,
                json.dumps(raw_dict, ensure_ascii=False),
                run_id,
                run_id,
            )
            sentiments_by_key[mention_key] = sentiment or None

            metrics_by_key[mention_key] = (
                mention_key,
                to_numeric(row.get("Reacciones", None)),
                to_numeric(row.get("Engagement", None)),
                to_numeric(row.get("Me gusta", None)),
                to_numeric(row.get("Amor", None)),
                to_numeric(row.get("Ja ja", None)),
                to_numeric(row.get("Wow", None)),
                to_numeric(row.get("Triste", None)),
                to_numeric(row.get("Enojado", None)),
                to_numeric(row.get("Preocupado", None)),
                to_numeric(row.get("No me gusta", None)),
                to_numeric(row.get("Comentarios", None)),
                to_numeric(row.get("Republicaciones", None)),
                to_numeric(row.get("Visualizaciones", None)),
                to_numeric(row.get("Impresiones (publicaciones propias)", None)),
                to_numeric(row.get("Alcance (publicaciones propias)", None)),
                to_numeric(row.get("Número de Guardados", None)),
                to_numeric(row.get("Alcance potencial", None)),
                to_numeric(row.get("Rating", None)),
                to_numeric(row.get("Calificación del lugar de publicación", None)),
                to_numeric(row.get("Suscriptores", None)),
                to_numeric(row.get("Suscriptores del lugar de publicación", None)),
            )

            tags = []
            for col in flag_cols:
                v = row.get(col, None)
                if pd.isna(v) or v is None or str(v).strip() == "":
                    continue
                kind = classify_flag_name(col)
                tag_type = "actor" if kind == "actor" else "topic"
                tag_name = norm_str(col)
                tags.append((tag_name, tag_type))

            for field, tag_type in LIST_FIELDS.items():
                for tag in split_list_field(row.get(field, None)):
                    if is_probable_tag(tag):
                        tags.append((tag, tag_type))

            if mention_key not in tags_by_key:
                tags_by_key[mention_key] = set()
            for tag in tags:
                tags_by_key[mention_key].add(tag)
            for tag_name, tag_type in tags:
                if tag_name not in all_tags:
                    all_tags[tag_name] = tag_type

            row_hash = compute_row_hash(raw_dict)
            row_hashes_by_key.setdefault(mention_key, []).append((row_hash, int(row_idx)))

        mention_keys = list(mention_by_key.keys())
        mentions_rows = list(mention_by_key.values())
        metrics_rows = list(metrics_by_key.values())
        counts["rows_mentions"] = len(mentions_rows)

        with conn.cursor() as cur:
            execute_values(
                cur,
                """
                insert into mentions (
                  mention_key, external_id, source_system, source_type, source_name,
                  published_at, title, body_text, url, author, author_nickname, author_profile,
                  language, country, region, city, publication_place, publication_profile,
                  publication_type, content_type, source_format, resource_type, notes,
                  assigned_to, processed, demographics, age, saved, sentiment, raw,
                  first_run_id, last_run_id
                ) values %s
                on conflict (mention_key) do update set
                  external_id = coalesce(excluded.external_id, mentions.external_id),
                  source_system = excluded.source_system,
                  source_type = excluded.source_type,
                  source_name = excluded.source_name,
                  published_at = excluded.published_at,
                  title = excluded.title,
                  body_text = excluded.body_text,
                  url = excluded.url,
                  author = excluded.author,
                  author_nickname = excluded.author_nickname,
                  author_profile = excluded.author_profile,
                  language = excluded.language,
                  country = excluded.country,
                  region = excluded.region,
                  city = excluded.city,
                  publication_place = excluded.publication_place,
                  publication_profile = excluded.publication_profile,
                  publication_type = excluded.publication_type,
                  content_type = excluded.content_type,
                  source_format = excluded.source_format,
                  resource_type = excluded.resource_type,
                  notes = excluded.notes,
                  assigned_to = excluded.assigned_to,
                  processed = excluded.processed,
                  demographics = excluded.demographics,
                  age = excluded.age,
                  saved = excluded.saved,
                  sentiment = excluded.sentiment,
                  raw = excluded.raw,
                  last_run_id = excluded.last_run_id,
                  updated_at = now()
                """,
                mentions_rows,
                page_size=500
            )

            cur.execute(
                """
                select mention_id, mention_key
                from mentions
                where mention_key = any(%s)
                """,
                (mention_keys,)
            )
            mention_map = {k: mid for (mid, k) in cur.fetchall()}

            metrics_values = []
            for row in metrics_rows:
                key = row[0]
                mention_id = mention_map.get(key)
                if not mention_id:
                    continue
                metrics_values.append((mention_id,) + row[1:])

            if metrics_values:
                execute_values(
                    cur,
                    """
                    insert into metrics (
                      mention_id, reactions, engagement, likes, love, haha, wow, sad, angry,
                      worried, dislike, comments, reposts, views, impressions_own, reach_own,
                      saves, reach_potential, rating, publication_rating,
                      author_subscribers, publication_subscribers
                    ) values %s
                    on conflict (mention_id) do update set
                      reactions = excluded.reactions,
                      engagement = excluded.engagement,
                      likes = excluded.likes,
                      love = excluded.love,
                      haha = excluded.haha,
                      wow = excluded.wow,
                      sad = excluded.sad,
                      angry = excluded.angry,
                      worried = excluded.worried,
                      dislike = excluded.dislike,
                      comments = excluded.comments,
                      reposts = excluded.reposts,
                      views = excluded.views,
                      impressions_own = excluded.impressions_own,
                      reach_own = excluded.reach_own,
                      saves = excluded.saves,
                      reach_potential = excluded.reach_potential,
                      rating = excluded.rating,
                      publication_rating = excluded.publication_rating,
                      author_subscribers = excluded.author_subscribers,
                      publication_subscribers = excluded.publication_subscribers,
                      updated_at = now()
                    """,
                    metrics_values,
                    page_size=500
                )

            if all_tags:
                tag_rows = [(name, ttype) for name, ttype in all_tags.items()]
                execute_values(
                    cur,
                    """
                    insert into tags (tag_name, tag_type)
                    values %s
                    on conflict (tag_name) do nothing
                    """,
                    tag_rows,
                    page_size=1000
                )

            if all_tags:
                cur.execute(
                    """
                    select tag_id, tag_name
                    from tags
                    where tag_name = any(%s)
                    """,
                    (list(all_tags.keys()),)
                )
                tag_map = {name: tid for (tid, name) in cur.fetchall()}
            else:
                tag_map = {}

            mention_ids = [mention_map[k] for k in mention_keys if k in mention_map]
            if mention_ids:
                cur.execute(
                    "delete from mention_tags where mention_id = any(%s)",
                    (mention_ids,)
                )

            mention_tag_rows = []
            for key, tags in tags_by_key.items():
                mention_id = mention_map.get(key)
                if not mention_id:
                    continue
                sentiment = sentiments_by_key.get(key)
                for tag_name, _tag_type in tags:
                    tag_id = tag_map.get(tag_name)
                    if not tag_id:
                        continue
                    mention_tag_rows.append((mention_id, tag_id, sentiment))

            if mention_tag_rows:
                execute_values(
                    cur,
                    """
                    insert into mention_tags (mention_id, tag_id, tag_sentiment)
                    values %s
                    on conflict do nothing
                    """,
                    mention_tag_rows,
                    page_size=1000
                )

            counts["rows_tags"] = len(mention_tag_rows)

            occurrence_rows = []
            for key, hashes in row_hashes_by_key.items():
                mention_id = mention_map.get(key)
                if not mention_id:
                    continue
                for row_hash, row_number in hashes:
                    occurrence_rows.append((mention_id, run_id, row_hash, row_number))

            if occurrence_rows:
                execute_values(
                    cur,
                    """
                    insert into mention_occurrences (mention_id, run_id, row_hash, row_number)
                    values %s
                    on conflict (run_id, row_number) do nothing
                    """,
                    occurrence_rows,
                    page_size=1000
                )

        conn.commit()

        with conn.cursor() as cur:
            cur.execute(
                """
                update ingestion_runs
                set status=%s,
                    finished_at=now(),
                    rows_in_file=%s,
                    rows_mentions=%s,
                    rows_tags=%s,
                    error_message=null
                where run_id=%s
                """,
                ("loaded", counts["rows_in_file"], counts["rows_mentions"], counts["rows_tags"], run_id),
            )
        conn.commit()

        # Refrescar vista materializada
        print("[INFO] Refrescando vista materializada...")
        with conn.cursor() as cur:
            try:
                cur.execute("REFRESH MATERIALIZED VIEW mv_mentions_by_actor_day;")
                conn.commit()
                print("[OK] Vista materializada actualizada")
            except Exception as e:
                print(f"[WARNING] No se pudo refrescar vista materializada: {e}")
                # No fallar el proceso si la vista no existe

        print("[OK] Loaded")
        print("[Counts]", counts)

    except Exception as e:
        conn.rollback()
        with conn.cursor() as cur:
            cur.execute(
                """
                update ingestion_runs
                set status=%s,
                    finished_at=now(),
                    rows_in_file=%s,
                    rows_mentions=%s,
                    rows_tags=%s,
                    error_message=%s
                where run_id=%s
                """,
                ("failed", counts["rows_in_file"], counts["rows_mentions"], counts["rows_tags"], str(e), run_id),
            )
        conn.commit()
        print("[ERROR]", e)
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
