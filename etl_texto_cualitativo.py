"""
ETL interactivo para cargar archivos CSV de texto cualitativo de YouScan.

Uso:
    python etl_texto_cualitativo.py data/1-marcobonilla-texto-cualitativo.csv

El script:
1. Consulta los actores disponibles en la tabla `tags` (tag_type='actor')
2. Detecta la última semana con datos en `mentions`
3. Muestra menús interactivos para seleccionar actor y semana
4. Carga los datos en la tabla `qual_insights`
"""

import os
import re
import sys
from datetime import datetime, timedelta

import pandas as pd
import psycopg2
from psycopg2.extras import execute_values


DB_HOST = os.getenv("PGHOST", "localhost")
DB_PORT = int(os.getenv("PGPORT", "5433"))
DB_NAME = os.getenv("PGDATABASE", "youscan")
DB_USER = os.getenv("PGUSER", "youscan_admin")
DB_PASS = os.getenv("PGPASSWORD", "youscan_pass")


def connect():
    return psycopg2.connect(
        host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASS
    )


def get_actors_from_db() -> list[str]:
    """Obtiene lista de actores desde la tabla tags."""
    conn = connect()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT tag_name
                FROM tags
                WHERE tag_type = 'actor'
                ORDER BY tag_name
            """)
            return [row[0] for row in cur.fetchall()]
    finally:
        conn.close()


def get_last_week_from_db() -> tuple[str, str] | None:
    """Obtiene la última semana con datos en mentions."""
    conn = connect()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT
                    DATE_TRUNC('week', MAX(published_at))::date as week_start,
                    (DATE_TRUNC('week', MAX(published_at)) + INTERVAL '6 days')::date as week_end
                FROM mentions
                WHERE published_at IS NOT NULL
            """)
            row = cur.fetchone()
            if row and row[0]:
                return (str(row[0]), str(row[1]))
            return None
    finally:
        conn.close()


def get_recent_weeks_from_db(limit: int = 5) -> list[tuple[str, str]]:
    """Obtiene las últimas N semanas con datos."""
    conn = connect()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT DISTINCT
                    DATE_TRUNC('week', published_at)::date as week_start,
                    (DATE_TRUNC('week', published_at) + INTERVAL '6 days')::date as week_end
                FROM mentions
                WHERE published_at IS NOT NULL
                ORDER BY week_start DESC
                LIMIT %s
            """, (limit,))
            return [(str(row[0]), str(row[1])) for row in cur.fetchall()]
    finally:
        conn.close()


def show_menu(title: str, options: list[str], allow_custom: bool = False) -> int | str:
    """Muestra un menú interactivo y retorna la selección."""
    print(f"\n{'='*50}")
    print(f"  {title}")
    print('='*50)

    for i, opt in enumerate(options, 1):
        print(f"  {i}. {opt}")

    if allow_custom:
        print(f"  {len(options)+1}. Especificar manualmente...")

    print()

    while True:
        try:
            choice = input("Selecciona una opción: ").strip()
            num = int(choice)

            if 1 <= num <= len(options):
                return num - 1  # índice
            elif allow_custom and num == len(options) + 1:
                return "custom"
            else:
                print("Opción no válida. Intenta de nuevo.")
        except ValueError:
            print("Por favor ingresa un número.")


def input_date(prompt: str) -> str:
    """Solicita una fecha al usuario."""
    while True:
        date_str = input(f"{prompt} (YYYY-MM-DD): ").strip()
        try:
            datetime.strptime(date_str, "%Y-%m-%d")
            return date_str
        except ValueError:
            print("Formato inválido. Usa YYYY-MM-DD (ej: 2025-01-05)")


def parse_numeric(value) -> float:
    """Convierte string con comas/puntos a float."""
    if pd.isna(value):
        return 0.0
    s = str(value).replace(",", ".").strip()
    s = re.sub(r"[^\d.\-]", "", s)
    try:
        return float(s)
    except ValueError:
        return 0.0


def load_csv(filepath: str, actor: str, semana_inicio: str, semana_fin: str):
    """Carga el CSV a la tabla qual_insights."""

    df = pd.read_csv(filepath, encoding="utf-8-sig")

    # Detectar columnas
    cols = list(df.columns)
    texto_col = next((c for c in cols if "texto" in c.lower()), cols[0])
    menciones_col = next((c for c in cols if "menciones" in c.lower()), cols[1] if len(cols) > 1 else None)
    soporte_col = next((c for c in cols if "soporte" in c.lower() or "%" in c.lower()), cols[2] if len(cols) > 2 else None)

    rows = []
    for _, row in df.iterrows():
        texto = str(row.get(texto_col, "")).strip()
        if not texto:
            continue

        menciones = int(parse_numeric(row.get(menciones_col, 0))) if menciones_col else 0
        soporte = parse_numeric(row.get(soporte_col, 0)) if soporte_col else 0.0

        rows.append((
            actor,
            semana_inicio,
            semana_fin,
            texto,
            menciones,
            soporte,
            "youscan",
        ))

    if not rows:
        print("[WARNING] No se encontraron filas para cargar")
        return 0

    conn = connect()
    try:
        with conn.cursor() as cur:
            # Eliminar datos anteriores del mismo actor y período
            cur.execute(
                """
                DELETE FROM qual_insights
                WHERE actor_name = %s AND period_start = %s AND period_end = %s
                """,
                (actor, semana_inicio, semana_fin)
            )
            deleted = cur.rowcount
            if deleted > 0:
                print(f"[INFO] Eliminados {deleted} registros anteriores para {actor} ({semana_inicio} - {semana_fin})")

            execute_values(
                cur,
                """
                INSERT INTO qual_insights
                (actor_name, period_start, period_end, insight_text, mentions_count, support_pct, source_system)
                VALUES %s
                """,
                rows,
                page_size=100
            )
            conn.commit()
            print(f"[OK] Cargados {len(rows)} registros para {actor}")
            return len(rows)
    except Exception as e:
        conn.rollback()
        print(f"[ERROR] {e}")
        raise
    finally:
        conn.close()


def main():
    # Verificar argumento del archivo
    if len(sys.argv) < 2:
        print("Uso: python etl_texto_cualitativo.py <archivo.csv>")
        print("Ejemplo: python etl_texto_cualitativo.py data/1-marcobonilla-texto-cualitativo.csv")
        sys.exit(1)

    filepath = sys.argv[1]

    if not os.path.exists(filepath):
        print(f"[ERROR] No existe el archivo: {filepath}")
        sys.exit(1)

    print(f"\n[INFO] Archivo: {filepath}")

    # 1. Obtener actores de la BD
    print("\n[INFO] Consultando actores en la base de datos...")
    actors = get_actors_from_db()

    if not actors:
        print("[WARNING] No hay actores en la tabla tags. Deberás escribir el nombre manualmente.")
        actor = input("Nombre del actor: ").strip()
    else:
        choice = show_menu("Selecciona el actor", actors, allow_custom=True)
        if choice == "custom":
            actor = input("Nombre del actor: ").strip()
        else:
            actor = actors[choice]

    print(f"\n[OK] Actor seleccionado: {actor}")

    # 2. Obtener semanas disponibles
    print("\n[INFO] Consultando semanas disponibles...")
    weeks = get_recent_weeks_from_db(5)

    if not weeks:
        print("[WARNING] No hay datos en mentions. Especifica las fechas manualmente.")
        semana_inicio = input_date("Fecha inicio de semana")
        semana_fin = input_date("Fecha fin de semana")
    else:
        week_options = [f"{w[0]} a {w[1]}" for w in weeks]
        choice = show_menu("Selecciona la semana", week_options, allow_custom=True)

        if choice == "custom":
            semana_inicio = input_date("Fecha inicio de semana")
            semana_fin = input_date("Fecha fin de semana")
        else:
            semana_inicio, semana_fin = weeks[choice]

    print(f"\n[OK] Período seleccionado: {semana_inicio} a {semana_fin}")

    # 3. Confirmar antes de cargar
    print("\n" + "="*50)
    print("  RESUMEN")
    print("="*50)
    print(f"  Archivo: {os.path.basename(filepath)}")
    print(f"  Actor:   {actor}")
    print(f"  Período: {semana_inicio} a {semana_fin}")
    print()

    confirm = input("¿Proceder con la carga? (s/n): ").strip().lower()
    if confirm not in ("s", "si", "sí", "y", "yes"):
        print("[CANCELADO] No se realizaron cambios.")
        sys.exit(0)

    # 4. Cargar datos
    print("\n[INFO] Cargando datos...")
    load_csv(filepath, actor, semana_inicio, semana_fin)

    print("\n[LISTO] Proceso completado.")


if __name__ == "__main__":
    main()
