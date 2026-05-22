"""Conexión a PostgreSQL."""
import os

import psycopg
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")


def get_connection():
    """Abre una conexión usando DATABASE_URL del entorno."""
    if not DATABASE_URL:
        raise RuntimeError("DATABASE_URL no está definida en .env")
    return psycopg.connect(DATABASE_URL)
