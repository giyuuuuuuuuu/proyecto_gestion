"""Comprueba que DATABASE_URL conecta con PostgreSQL."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from repuesto.db import get_connection


def main() -> int:
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT version();")
                version = cur.fetchone()[0]
        print("Conexión OK.")
        print(version)
        return 0
    except Exception as exc:
        print("Error de conexión:", exc, file=sys.stderr)
        print(
            "Si aún no creaste la BBDD, ejecuta: .\\scripts\\setup_postgres.ps1",
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
